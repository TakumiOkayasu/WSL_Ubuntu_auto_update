# WSL自動アップデート完全セットアップスクリプト
# 管理者権限で実行してください

Write-Host "=== WSL Auto Update Setup ===" -ForegroundColor Green

# 1. スリープ解除を許可
Write-Host "`n[1/4] Enabling wake timers..." -ForegroundColor Yellow
powercfg -setacvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 1
powercfg -setdcvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 1

# 2. USBセレクティブサスペンドを無効化
Write-Host "[2/4] Disabling USB selective suspend..." -ForegroundColor Yellow
powercfg -setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0
powercfg -setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0

# 3. 電源設定を適用
Write-Host "[3/4] Applying power settings..." -ForegroundColor Yellow
powercfg -setactive SCHEME_CURRENT

# 4. タスクスケジューラに登録
Write-Host "[4/4] Registering scheduled task..." -ForegroundColor Yellow
if (Test-Path "C:\Scripts\wsl-update-task.xml") {
    schtasks /create /tn "WSL System Update" /xml C:\Scripts\wsl-update-task.xml /f
    Write-Host "Task registered successfully!" -ForegroundColor Green
} else {
    Write-Host "ERROR: C:\Scripts\wsl-update-task.xml not found!" -ForegroundColor Red
}

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "`nIMPORTANT: Please configure keyboard wake manually:" -ForegroundColor Cyan
Write-Host "1. Open Device Manager (Win+X -> Device Manager)"
Write-Host "2. Expand 'Keyboards'"
Write-Host "3. Right-click your keyboard -> Properties"
Write-Host "4. Go to 'Power Management' tab"
Write-Host "5. Check 'Allow this device to wake the computer'"
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
