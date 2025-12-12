# ログファイルパス
$logFile = "C:\Scripts\wsl-update.log"

# ログ出力関数
function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $Message" | Out-File -Append -Encoding utf8BOM $logFile
}

# ログファイル初期化
"=== Log started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Out-File -FilePath $logFile -Encoding utf8BOM

Write-Log "Windows Task Started"
Write-Log "PowerShell Version: $($PSVersionTable.PSVersion)"

try {
    # apt-get更新(rootで実行)
    Write-Log "Running apt-get update and upgrade..."
    $aptResult = wsl -u root -- bash -c "apt-get update 2>&1 && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y 2>&1"
    $aptResult | Where-Object { 
        $_ -and 
        $_ -notmatch "RemoteException" -and 
        $_ -notmatch "^$"
    } | ForEach-Object { Write-Log $_ }
    
    # brew更新
    Write-Log "Running brew update..."
    $brewUpdateResult = wsl -- /home/linuxbrew/.linuxbrew/bin/brew update 2>&1
    $brewUpdateResult | Where-Object { 
        $_ -and $_ -notmatch "^$" 
    } | ForEach-Object { Write-Log $_ }
    
    # brew upgrade
    Write-Log "Running brew upgrade..."
    $brewUpgradeResult = wsl -- /home/linuxbrew/.linuxbrew/bin/brew upgrade 2>&1
    $brewUpgradeResult | Where-Object { 
        $_ -and $_ -notmatch "^$"
    } | ForEach-Object { 
        $cleaned = $_ -replace '[^\x20-\x7E]', ''
        $cleaned = $cleaned.Trim()
        if ($cleaned) {
            Write-Log $cleaned
        }
    }
    
    Write-Log "Updates completed successfully"
    
    # 少し待機
    Start-Sleep -Seconds 3
    
    # スリープ実行
    Write-Log "Entering sleep mode..."
    
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $sleepResult = [System.Windows.Forms.Application]::SetSuspendState(
            [System.Windows.Forms.PowerState]::Suspend,
            $false,
            $false
        )
        Write-Log "Sleep initiated successfully"
    }
    catch {
        Write-Log "SetSuspendState failed: $_"
        Write-Log "Trying alternative method..."
        & rundll32.exe powrprof.dll,SetSuspendState 0,1,0
    }
    
    Write-Log "=== Task Completed ==="
}
catch {
    Write-Log "ERROR: $_"
    Write-Log "=== Task Failed ==="
    exit 1
}
