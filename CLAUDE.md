# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

WSL (Ubuntu) の `apt` + Homebrew + `claude update` を **Windows 起動時に自動実行**する PowerShell スクリプト集。`BootTrigger` で OS 起動時にタスクを発火 → `pwsh.exe` でスクリプト実行 → `wsl` 経由で Ubuntu 側を更新、という一連の流れが核。更新完了後の電源制御 (シャットダウン/スリープ) は行わず、PC は起動状態のままとなる。

⚠️ **定時実行したい場合の起動方法**: PC を毎日指定時刻 (例: 03:00) に起動するには **BIOS/UEFI の RTC Wake** または **Wake on LAN** が必要。タスク側は起動検知して即実行する。

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
[任意] BIOS RTC Wake / Wake on LAN でシャットダウン状態の Windows を起動
  └─ OS ブート完了
       └─ タスクスケジューラ (BootTrigger, 30秒遅延, HighestAvailable, S4U)
            └─ pwsh.exe -File C:\Scripts\wsl-update.ps1
                 ├─ wsl -u root -- apt-get update/upgrade
                 ├─ wsl -- /home/linuxbrew/.linuxbrew/bin/brew update/upgrade
                 └─ claude update (Claude Code CLI 更新)
                      └─ 完了後は PC 起動状態のまま (電源制御なし)
```

### 設計上の固定事項 (変更時は影響箇所を要確認)

| 項目 | 値 | 参照 |
|------|-----|------|
| PowerShell バージョン | **pwsh 7** (`C:\Program Files\PowerShell\7\pwsh.exe`)。Windows PowerShell 5 ではない | `wsl-update-task-winps.xml` Actions セクション |
| トリガー | `BootTrigger` (OS 起動時に発火、30秒遅延) | `wsl-update-task-winps.xml` Triggers セクション |
| タスク実行ユーザー | `okayasu` にハードコード | `wsl-update-task-winps.xml` Principal セクション |
| ログオン方式 | `S4U` (パスワード不要・ログオフ中も実行可)。ネットワーク資格情報は不可 | `wsl-update-task-winps.xml` Principal セクション |
| apt 実行権限 | `wsl -u root` (root で実行) | `wsl-update.ps1:20` |
| brew パス | `/home/linuxbrew/.linuxbrew/bin/brew` にハードコード | `wsl-update.ps1:29,36` |
| スクリプト配置 | `C:\Scripts\` 絶対パス前提 | 全ファイル |
| ログエンコーディング | UTF8BOM (brew 出力は非 ASCII 除去後に記録) | `wsl-update.ps1:8,40` |
| 実行タイムアウト | `PT1H` (1時間) | `wsl-update-task-winps.xml:38` |

### 起動トリガーの仕様

タスクは `BootTrigger` で OS 起動時に発火する。**PC を手動起動しても自動発火する点に注意**。

| 項目 | 値 | 備考 |
| ---- | ---- | ---- |
| トリガー種別 | `BootTrigger` | Task Scheduler Schema 公式 |
| 起動後遅延 | 30秒 (`PT30S`) | WSL・ネットワーク初期化の安定化時間 |
| 重複防止 | `MultipleInstancesPolicy=IgnoreNew` | 実行中に再トリガーされても無視 |

### 定時起動したい場合 (任意)

Windows 自体を毎日 03:00 等に起動したい場合、以下のいずれかを設定する。BootTrigger 自体は変更不要:

| 方法 | 必要な設定 |
| ---- | ---------- |
| BIOS/UEFI の RTC Wake | BIOS 設定で「Wake on RTC Alarm」等を有効化し、起動時刻を設定 (マザーボード依存) |
| Wake on LAN | BIOS で WoL 有効化 + OS 側 NIC 設定 + 別デバイスからマジックパケット送信 |

⚠️ `setup-auto-update.ps1` の `powercfg RTCWAKE 1` / USB Selective Suspend 無効化 / キーボードウェイク設定は**旧スリープ運用時の名残**で、BootTrigger 運用では不要。削除は保留 (将来スリープ運用に戻す際の資産)。

## 編集時の注意点

- **起動遅延の変更**: `wsl-update-task-winps.xml` の `<Delay>PT30S</Delay>` を編集した後、必ず `schtasks /create ... /f` で再登録する (XML 単体の編集ではタスクに反映されない)
- **定時実行への切り替え**: OS 起動時ではなく特定時刻 (例: 03:00) に実行したい場合は、`BootTrigger` を `CalendarTrigger` + `<StartBoundary>` + `<ScheduleByDay>` に置き換える
- **ユーザー環境の相違**: 別 PC で使う場合、XML の `<UserId>okayasu</UserId>` と brew パスを環境に合わせて書き換える
- **ログエンコーディングの変更禁止**: `Out-File -Encoding utf8BOM` を維持しないと日本語が化ける。brew 出力に混在する非 ASCII はあえて除去している (`wsl-update.ps1:40`)
- **ファイル名の不一致**: リポジトリ内のタスク XML は `wsl-update-task-winps.xml` だが、`setup-auto-update.ps1` と README は `wsl-update-task.xml` を参照している。リネームまたはコピーが必要になる場合がある (`setup-auto-update.ps1:22-23`, `README.md:58`)
