# WSL自動アップデートスクリプト

WSL上のUbuntuで、**Windows起動時にapt/brew/claude updateの自動アップデートを実行**する設定。

## 概要

- **実行内容**: apt update/upgrade → brew update/upgrade → claude update
- **実行タイミング**: **Windows 起動時** (BootTrigger、起動後 30 秒遅延)
- **完了後**: PC は起動状態のまま (電源制御なし)
- **定時起動したい場合** (任意): PC 自体を毎日決まった時刻に起動するには以下のいずれかを別途設定:
  - **BIOS/UEFI の RTC Wake 機能** (マザーボード依存、「Wake on RTC Alarm」等の項目を有効化)
  - **Wake on LAN** (別デバイスからマジックパケット送信)

⚠️ **仕様**: PC を手動起動した場合も 30 秒後に自動でアップデートが開始されます。起動直後にアップデートさせたくない場合はタスクを無効化してください (`Disable-ScheduledTask -TaskName "WSL System Update"`)。

## セットアップ手順

### 0. 自動セットアップ(推奨)

管理者権限のPowerShellで実行:

```powershell
C:\Scripts\setup-auto-update.ps1
```

その後、画面の指示に従ってキーボードのウェイク設定を手動で行ってください。

### 手動セットアップ

#### 1. スリープ解除を許可する設定

管理者権限のPowerShellで実行:

```powershell
# RTCウェイクタイマーの有効化
powercfg -setacvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 1
powercfg -setdcvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 1

# USBセレクティブサスペンドを無効化
powercfg -setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg -setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0

# 設定を適用
powercfg -setactive SCHEME_CURRENT
```

#### 2. キーボードウェイク設定

デバイスマネージャーで設定:

1. `Win + X` → デバイスマネージャー
2. 「キーボード」を展開
3. 使用しているキーボードを右クリック → プロパティ
4. 「電源の管理」タブ
5. ☑ `このデバイスで、コンピューターのスタンバイ状態を解除できるようにする`

#### 3. タスクスケジューラへ登録

管理者権限のPowerShellで実行:

```powershell
# タスクをインポート
schtasks /create /tn "WSL System Update" /xml C:\Scripts\wsl-update-task-winps.xml /f
```

### 3. 動作確認(テスト実行)

管理者権限のPowerShellで実行:

```powershell
# 手動でタスク実行
schtasks /run /tn "WSL System Update"

# ログ確認
Start-Sleep -Seconds 30
Get-Content C:\Scripts\wsl-update.log -Tail 50
```

## 設定変更

### 起動遅延の変更

`C:\Scripts\wsl-update-task-winps.xml` の `BootTrigger` 内を編集:

```xml
<BootTrigger>
    <Enabled>true</Enabled>
    <Delay>PT30S</Delay>
</BootTrigger>
```

- `PT30S` = 30 秒遅延。`PT2M` で 2 分、`PT5M` で 5 分
- 変更後、再度タスクを登録 (手順3を再実行)

### 定時実行に戻したい場合 (起動時ではなく 03:00 等に実行)

`BootTrigger` を `CalendarTrigger` に置き換え:

```xml
<CalendarTrigger>
    <StartBoundary>2025-01-01T03:00:00</StartBoundary>
    <Enabled>true</Enabled>
    <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
    </ScheduleByDay>
</CalendarTrigger>
```

さらに `<WakeToRun>false</WakeToRun>` を `true` に戻す。ただし**シャットダウン運用のままでは自動起動しない**ため、BIOS RTC Wake 等の別途設定が必要。

### Homebrewのパスが異なる場合

WSLで実際のパスを確認:

```bash
which brew
```

パスが `/home/linuxbrew/.linuxbrew/bin/brew` と異なる場合は、`C:\Scripts\wsl-update.ps1` のパスを修正。

## ログ確認

```powershell
# 最新のログを表示
Get-Content C:\Scripts\wsl-update.log -Tail 50

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

### PC 起動時にタスクが実行されない

```powershell
# BootTrigger が有効か確認
(Get-ScheduledTask -TaskName "WSL System Update").Triggers

# 前回実行結果のエラーコード確認
Get-ScheduledTask -TaskName "WSL System Update" | Get-ScheduledTaskInfo
```

よくある原因:

| 原因 | 対処 |
| ---- | ---- |
| XML が反映されていない | `schtasks /create ... /f` で再登録 |
| `LogonType=S4U` のバッチ権限不足 | `okayasu` がローカル管理者グループに所属しているか確認 |
| 起動直後過ぎて WSL 未初期化 | `<Delay>` を `PT1M` 等に延長 |

### PC を定時起動したい

`BootTrigger` 自体は「起動したら実行」のみ。**PC を毎日 03:00 等に起動するには別設定が必要**:

1. **BIOS/UEFI 設定**: 「Wake on RTC Alarm」「RTC Wake」等の項目を有効化し、起動時刻を指定
2. **Wake on LAN**: 別デバイスから `wakeonlan` コマンド等でマジックパケット送信
3. **電源制御を復活させたい場合**: `wsl-update.ps1` に `Stop-Computer -Force` または `SetSuspendState` ベースの処理を追加 (git履歴参照)
