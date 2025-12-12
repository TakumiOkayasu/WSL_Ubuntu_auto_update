# 管理者権限のPowerShellで実行

Write-Host "Enabling mouse wake from sleep..."

# マウスデバイスを取得
$mice = Get-PnpDevice -Class Mouse | Where-Object { $_.Status -eq 'OK' }

foreach ($mouse in $mice) {
    $instanceId = $mouse.InstanceId
    
    # デバイスのウェイク設定を有効化
    $device = Get-WmiObject Win32_PnPEntity | Where-Object { $_.DeviceID -eq $instanceId }
    
    if ($device) {
        Write-Host "Configuring: $($mouse.FriendlyName)"
        
        # PowerShellでデバイスのウェイク設定を有効化
        $powerMgmt = Get-CimInstance -Namespace root/wmi -ClassName MSPower_DeviceWakeEnable | 
            Where-Object { $_.InstanceName -like "*$($device.PNPDeviceID)*" }
        
        if ($powerMgmt) {
            $powerMgmt | Set-CimInstance -Property @{Enable = $true}
            Write-Host "  Wake enabled for mouse"
        }
    }
}

Write-Host "Done. Please reboot for changes to take effect."
