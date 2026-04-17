[CmdletBinding()]
param(
    [string]$LogFile = "C:\Scripts\wsl-update.log",
    [string]$BrewPath = "/home/linuxbrew/.linuxbrew/bin/brew",
    [int]$PreSuspendDelaySec = 3
)

Set-Variable -Name NON_ASCII_PATTERN -Value '[^\x20-\x7E]' -Option Constant -Scope Script

function Write-Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "[$timestamp] $Message" | Out-File -Append -Encoding utf8BOM $LogFile
}

function Write-CommandOutput {
    param(
        [Parameter(Mandatory)][AllowNull()]$Output,
        [switch]$StripNonAscii,
        [string[]]$ExcludePatterns = @()
    )
    $Output | Where-Object {
        if (-not $_) { return $false }
        if ($_ -match "^$") { return $false }
        foreach ($pattern in $ExcludePatterns) {
            if ($_ -match $pattern) { return $false }
        }
        return $true
    } | ForEach-Object {
        if ($StripNonAscii) {
            $cleaned = ($_ -replace $NON_ASCII_PATTERN, '').Trim()
            if ($cleaned) { Write-Log $cleaned }
        } else {
            Write-Log $_
        }
    }
}

function Invoke-AptUpgrade {
    Write-Log "Running apt-get update and upgrade..."
    $result = wsl -u root -- bash -c "apt-get update 2>&1 && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y 2>&1"
    Write-CommandOutput -Output $result -ExcludePatterns @("RemoteException")
}

function Invoke-BrewUpgrade {
    param([Parameter(Mandatory)][string]$BrewBinary)

    Write-Log "Running brew update..."
    $updateResult = wsl -- $BrewBinary update 2>&1
    Write-CommandOutput -Output $updateResult

    Write-Log "Running brew upgrade..."
    $upgradeResult = wsl -- $BrewBinary upgrade 2>&1
    Write-CommandOutput -Output $upgradeResult -StripNonAscii
}

function Invoke-Suspend {
    Write-Log "Entering sleep mode..."
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $sleepResult = [System.Windows.Forms.Application]::SetSuspendState(
            [System.Windows.Forms.PowerState]::Suspend,
            $false,
            $false
        )
        if ($sleepResult) {
            Write-Log "Sleep initiated successfully"
            return
        }
        Write-Log "SetSuspendState returned false, trying fallback..."
    }
    catch {
        Write-Log "SetSuspendState failed: $_"
        Write-Log "Trying alternative method..."
    }
    & rundll32.exe powrprof.dll,SetSuspendState 0,1,0
}

"=== Log started at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" | Out-File -FilePath $LogFile -Append -Encoding utf8BOM

Write-Log "Windows Task Started"
Write-Log "PowerShell Version: $($PSVersionTable.PSVersion)"

try {
    Invoke-AptUpgrade
    Invoke-BrewUpgrade -BrewBinary $BrewPath
    Write-Log "Updates completed successfully"

    Start-Sleep -Seconds $PreSuspendDelaySec
    Invoke-Suspend

    Write-Log "=== Task Completed ==="
}
catch {
    Write-Log "ERROR: $_"
    Write-Log "=== Task Failed ==="
    exit 1
}
