# WSL自動アップデートスクリプト

WSL上のUbuntuで、毎日決まった時間にapt/brewの自動アップデートを実行し、完了後に自動スリープする設定。

## 概要

- **実行内容**: apt update/upgrade → brew update/upgrade → スリープ復帰
- **実行時刻**: 毎日午前3時(変更可能)
- **動作**: スリープ中でも指定時刻に自動起動して実行

## セットアップ手順

### 1. スリープ解除を許可する設定

管理者権限のPowerShellで実行:

```powershell
# RTCウェイクタイマーの有効化
powercfg -setacvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 1
powercfg -setdcvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 1
powercfg -setactive SCHEME_CURRENT
```

### 2. タスクスケジューラへ登録

管理者権限のPowerShellで実行:

```powershell
# タスクをインポート
schtasks /create /tn "WSL System Update" /xml C:\Scripts\wsl-update-task.xml /f
```

### 3. 動作確認(テスト実行)

管理者権限のPowerShellで実行:

```powershell
# 手動でタスク実行
schtasks /run /tn "WSL System Update"

# ログ確認
Get-Content C:\Scripts\wsl-update.log -Tail 30
```

## 設定変更

### 実行時刻の変更

`C:\Scripts\wsl-update-task.xml` を編集:

```xml
<StartBoundary>2025-01-01T03:00:00</StartBoundary>
```

- `T03:00:00` の部分を変更(例: `T23:00:00` で午後11時)
- 変更後、再度タスクを登録(手順2を再実行)

### Homebrewのパスが異なる場合

WSLで実際のパスを確認:

```bash
which brew
```

パスが `/home/linuxbrew/.linuxbrew/bin/brew` と異なる場合は、`C:\Scripts\wsl-update.ps1` のパスを修正。

## ログ確認

```powershell
# 最新のログを表示
Get-Content C:\Scripts\wsl-update.log -Tail 30

# ログ全体を表示
Get-Content C:\Scripts\wsl-update.log
```

## タスクの削除

```powershell
# タスクを削除
schtasks /delete /tn "WSL System Update" /f
```

## トラブルシューティング

### タスクが実行されない

```powershell
# タスクの状態確認
Get-ScheduledTask -TaskName "WSL System Update" | Get-ScheduledTaskInfo
```

イベントビューアでエラー確認:

- `Win + R` → `eventvwr.msc`
- Windowsログ → アプリケーション

### スリープに戻らない

電源オプションでスリープが無効になっていないか確認:

```powershell
# 現在の電源設定確認
powercfg /query

# スリープタイムアウト設定(例: 30分後)
powercfg -change -standby-timeout-ac 30
```
