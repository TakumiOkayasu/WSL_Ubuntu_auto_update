# ログファイルパス
$logFile = "C:\Scripts\wsl-update.log"

# ログ出力開始
"=== Windows Task Started at $(Get-Date) ===" | Out-File -Append -Encoding utf8BOM $logFile

try {
    # apt更新(rootで実行)
    "Running apt update..." | Out-File -Append -Encoding utf8BOM $logFile
    wsl -u root -- bash -c "apt update && DEBIAN_FRONTEND=noninteractive apt upgrade -y" 2>&1 | Out-File -Append -Encoding utf8BOM $logFile
    
    # brew更新(一般ユーザーで実行)
    "Running brew update..." | Out-File -Append -Encoding utf8BOM $logFile
    wsl -- bash -c 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" && brew update && brew upgrade' 2>&1 | Out-File -Append -Encoding utf8BOM $logFile
    
    "Updates completed. Exit Code: $LASTEXITCODE" | Out-File -Append -Encoding utf8BOM $logFile
    
    # 少し待機
    Start-Sleep -Seconds 5
    
    # スリープ実行(スタートボタンと同じ方法)
    "Entering sleep mode..." | Out-File -Append -Encoding utf8BOM $logFile
    "=== Task Completed at $(Get-Date) ===" | Out-File -Append -Encoding utf8BOM $logFile
    "" | Out-File -Append -Encoding utf8BOM $logFile
    
    # psshutdownまたはNirCmdを使う方法もあるが、標準的な方法:
    Add-Type -AssemblyName System.Windows.Forms
    $null = [System.Windows.Forms.Application]::SetSuspendState([System.Windows.Forms.PowerState]::Suspend, $false, $false)
}
catch {
    "Error occurred: $_" | Out-File -Append -Encoding utf8BOM $logFile
    "=== Task Failed at $(Get-Date) ===" | Out-File -Append -Encoding utf8BOM $logFile
    "" | Out-File -Append -Encoding utf8BOM $logFile
}
