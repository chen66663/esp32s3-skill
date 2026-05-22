[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$ports = @()

try {
    $ports += Get-CimInstance Win32_PnPEntity |
        Where-Object { $_.Name -match '\(COM\d+\)' } |
        ForEach-Object {
            $m = [regex]::Match($_.Name, '\((COM\d+)\)')
            [pscustomobject]@{
                Port = $m.Groups[1].Value
                Name = $_.Name
                DeviceId = $_.DeviceID
                Source = "Win32_PnPEntity"
            }
        }
} catch {
}

try {
    $ports += [System.IO.Ports.SerialPort]::GetPortNames() |
        Sort-Object |
        ForEach-Object {
            [pscustomobject]@{
                Port = $_
                Name = $_
                DeviceId = ""
                Source = ".NET"
            }
        }
} catch {
}

$ports |
    Sort-Object Port, Name -Unique |
    ConvertTo-Json -Depth 4
