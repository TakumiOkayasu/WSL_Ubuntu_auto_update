[CmdletBinding()]
param(
    [string]$TaskXmlPath = "C:\Scripts\wsl-update-task-winps.xml",
    [string]$TaskName = "WSL System Update"
)

Set-Variable -Name USB_SELECTIVE_SUSPEND_SUBGROUP -Value "2a737441-1930-4402-8d77-b2bebba308a3" -Option Constant
Set-Variable -Name USB_SELECTIVE_SUSPEND_SETTING  -Value "48e6b7a6-50f5-4782-a5d4-53bb8f07e226" -Option Constant

function Enable-WakeTimers {
    powercfg -setacvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 1
    powercfg -setdcvalueindex SCHEME_CURRENT SUB_SLEEP RTCWAKE 1
}

function Disable-UsbSelectiveSuspend {
    powercfg -setacvalueindex SCHEME_CURRENT $USB_SELECTIVE_SUSPEND_SUBGROUP $USB_SELECTIVE_SUSPEND_SETTING 0
    powercfg -setdcvalueindex SCHEME_CURRENT $USB_SELECTIVE_SUSPEND_SUBGROUP $USB_SELECTIVE_SUSPEND_SETTING 0
}

function Register-UpdateTask {
    param(
        [Parameter(Mandatory)][string]$XmlPath,
        [Parameter(Mandatory)][string]$Name
    )
    if (-not (Test-Path $XmlPath)) {
        Write-Host "ERROR: $XmlPath not found!" -ForegroundColor Red
        exit 1
    }
    schtasks /create /tn $Name /xml $XmlPath /f
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: schtasks failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
    Write-Host "Task registered successfully!" -ForegroundColor Green
}

Write-Host "=== WSL Auto Update Setup ===" -ForegroundColor Green

Write-Host "`n[1/4] Enabling wake timers..." -ForegroundColor Yellow
Enable-WakeTimers

Write-Host "[2/4] Disabling USB selective suspend..." -ForegroundColor Yellow
Disable-UsbSelectiveSuspend

Write-Host "[3/4] Applying power settings..." -ForegroundColor Yellow
powercfg -setactive SCHEME_CURRENT

Write-Host "[4/4] Registering scheduled task..." -ForegroundColor Yellow
Register-UpdateTask -XmlPath $TaskXmlPath -Name $TaskName

Write-Host "`n=== Setup Complete ===" -ForegroundColor Green
Write-Host "`nIMPORTANT: Please configure keyboard wake manually:" -ForegroundColor Cyan
Write-Host "1. Open Device Manager (Win+X -> Device Manager)"
Write-Host "2. Expand 'Keyboards'"
Write-Host "3. Right-click your keyboard -> Properties"
Write-Host "4. Go to 'Power Management' tab"
Write-Host "5. Check 'Allow this device to wake the computer'"
Write-Host "`nPress any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
