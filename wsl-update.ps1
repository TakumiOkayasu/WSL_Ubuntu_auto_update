# ログファイルパス
$logFile = "C:\Scripts\wsl-update.log"

# ログ出力開始
"=== Windows Task Started at $(Get-Date) ===" | Out-File -Append $logFile

try {
    # apt更新(rootで実行)
    "Running apt update..." | Out-File -Append $logFile
    wsl -u root -- bash -c "apt update && DEBIAN_FRONTEND=noninteractive apt upgrade -y" 2>&1 | Out-File -Append $logFile
    
    # brew更新(一般ユーザーで実行)
    "Running brew update..." | Out-File -Append $logFile
    wsl -- bash -c 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && brew update && brew upgrade' 2>&1 | Out-File -Append $logFile
    
    "Updates completed. Exit Code: $LASTEXITCODE" | Out-File -Append $logFile
    
    # 少し待機
    Start-Sleep -Seconds 5
    
    # スリープ実行
    "Entering sleep mode..." | Out-File -Append $logFile
    "=== Task Completed at $(Get-Date) ===" | Out-File -Append $logFile
    "" | Out-File -Append $logFile
    
    Add-Type -Assembly System.Windows.Forms
    [System.Windows.Forms.Application]::SetSuspendState('Suspend', $false, $false)
}
catch {
    "Error occurred: $_" | Out-File -Append $logFile
    "=== Task Failed at $(Get-Date) ===" | Out-File -Append $logFile
    "" | Out-File -Append $logFile
}
