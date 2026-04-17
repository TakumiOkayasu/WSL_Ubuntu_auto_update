# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

WSL (Ubuntu) の `apt` + Homebrew を毎日 03:00 に自動実行し、完了後に Windows をスリープへ戻す PowerShell スクリプト集。Windows タスクスケジューラの `WakeToRun` で RTC ウェイク → `pwsh.exe` でスクリプト実行 → `wsl` 経由で Ubuntu 側を更新 → `SetSuspendState` でスリープ、という一連の流れが核。

## Commonly Used Commands

全て **管理者権限の PowerShell** で実行する。

```powershell
# フルセットアップ (powercfg + タスク登録をまとめて実施)
C:\Scripts\setup-auto-update.ps1

# タスクを手動登録 (XML 編集後の再登録)
schtasks /create /tn "WSL System Update" /xml C:\Scripts\wsl-update-task.xml /f

# 手動テスト実行
schtasks /run /tn "WSL System Update"

# 実行状態の確認
Get-ScheduledTask -TaskName "WSL System Update" | Get-ScheduledTaskInfo

# ログ確認
Get-Content C:\Scripts\wsl-update.log -Tail 50

# タスク削除
schtasks /delete /tn "WSL System Update" /f

# マウスでスリープ解除を有効化
C:\Scripts\enable-mouse-wake.ps1
```

## Architecture

### トリガーチェーン

```
タスクスケジューラ (WakeToRun=true, 03:00 毎日)
  └─ RTC Wake でスリープ中の Windows を起動
       └─ pwsh.exe -File C:\Scripts\wsl-update.ps1
            ├─ wsl -u root -- apt-get update/upgrade
            ├─ wsl -- /home/linuxbrew/.linuxbrew/bin/brew update/upgrade
            └─ [System.Windows.Forms.Application]::SetSuspendState(Suspend, $false, $false)
                 └─ 失敗時フォールバック: rundll32 powrprof.dll,SetSuspendState 0,1,0
```

### 設計上の固定事項 (変更時は影響箇所を要確認)

| 項目 | 値 | 参照 |
|------|-----|------|
| PowerShell バージョン | **pwsh 7** (`C:\Program Files\PowerShell\7\pwsh.exe`)。Windows PowerShell 5 ではない | `wsl-update-task-winps.xml:43` |
| タスク実行ユーザー | `okayasu` にハードコード | `wsl-update-task-winps.xml:17` |
| apt 実行権限 | `wsl -u root` (root で実行) | `wsl-update.ps1:20` |
| brew パス | `/home/linuxbrew/.linuxbrew/bin/brew` にハードコード | `wsl-update.ps1:29,36` |
| スクリプト配置 | `C:\Scripts\` 絶対パス前提 | 全ファイル |
| ログエンコーディング | UTF8BOM (brew 出力は非 ASCII 除去後に記録) | `wsl-update.ps1:8,40` |
| 実行タイムアウト | `PT1H` (1時間) | `wsl-update-task-winps.xml:38` |

### Wake の前提条件 (`setup-auto-update.ps1` が自動化)

スリープからの自動起動には以下3点が必要。1つでも欠けると指定時刻にウェイクしない:

1. `powercfg RTCWAKE 1` (RTC ウェイクタイマー有効化)
2. USB Selective Suspend 無効化 (`2a737441-...` サブキー)
3. キーボード/マウスのデバイスマネージャで **「このデバイスでスタンバイ状態を解除できるようにする」** が有効 (マウスは `enable-mouse-wake.ps1` で自動設定可能だが、キーボードは手動)

## 編集時の注意点

- **実行時刻の変更**: `wsl-update-task-winps.xml` の `<StartBoundary>2025-01-01T03:00:00</StartBoundary>` を編集した後、必ず `schtasks /create ... /f` で再登録する (XML 単体の編集ではタスクに反映されない)
- **ユーザー環境の相違**: 別 PC で使う場合、XML の `<UserId>okayasu</UserId>` と brew パスを環境に合わせて書き換える
- **ログエンコーディングの変更禁止**: `Out-File -Encoding utf8BOM` を維持しないと日本語が化ける。brew 出力に混在する非 ASCII はあえて除去している (`wsl-update.ps1:40`)
- **ファイル名の不一致**: リポジトリ内のタスク XML は `wsl-update-task-winps.xml` だが、`setup-auto-update.ps1` と README は `wsl-update-task.xml` を参照している。リネームまたはコピーが必要になる場合がある (`setup-auto-update.ps1:22-23`, `README.md:58`)
