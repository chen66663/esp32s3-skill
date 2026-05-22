[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("capture", "request")]
    [string]$Action,

    [Parameter(Mandatory = $true)]
    [string]$Port,

    [int]$Baud = 115200,
    [int]$CaptureMs = 4000,
    [int]$QuietMs = 250,
    [int]$InterLineDelayMs = 120,
    [string[]]$Lines = @()
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System

function Read-SerialText {
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.Ports.SerialPort]$SerialPort,
        [int]$DurationMs,
        [int]$QuietWindowMs
    )

    $endAt = (Get-Date).AddMilliseconds($DurationMs)
    $lastDataAt = Get-Date
    $builder = New-Object System.Text.StringBuilder

    while ((Get-Date) -lt $endAt) {
        if ($SerialPort.BytesToRead -gt 0) {
            $chunk = $SerialPort.ReadExisting()
            if ($chunk) {
                [void]$builder.Append($chunk)
                $lastDataAt = Get-Date
            }
        } else {
            $quietFor = ((Get-Date) - $lastDataAt).TotalMilliseconds
            if ($quietFor -ge $QuietWindowMs -and $builder.Length -gt 0) {
                break
            }
            Start-Sleep -Milliseconds 60
        }
    }

    return $builder.ToString()
}

$serial = New-Object System.IO.Ports.SerialPort $Port, $Baud, ([System.IO.Ports.Parity]::None), 8, ([System.IO.Ports.StopBits]::One)
$serial.Handshake = [System.IO.Ports.Handshake]::None
$serial.DtrEnable = $false
$serial.RtsEnable = $false
$serial.NewLine = "`r`n"
$serial.ReadTimeout = 200
$serial.WriteTimeout = 1000

try {
    $serial.Open()
    $serial.DiscardInBuffer()
    $serial.DiscardOutBuffer()
    Start-Sleep -Milliseconds 120

    $initialText = Read-SerialText -SerialPort $serial -DurationMs $CaptureMs -QuietWindowMs $QuietMs
    $sentLines = @()
    $responseText = ""

    if ($Action -eq "request") {
        foreach ($line in $Lines) {
            if ($null -eq $line) {
                continue
            }
            $serial.WriteLine($line)
            $sentLines += $line
            Start-Sleep -Milliseconds $InterLineDelayMs
        }

        $responseText = Read-SerialText -SerialPort $serial -DurationMs $CaptureMs -QuietWindowMs $QuietMs
    }

    [ordered]@{
        action = $Action
        port = $Port
        baud = $Baud
        sent_lines = $sentLines
        initial_output = $initialText
        response_output = $responseText
        combined_output = ($initialText + $responseText)
    } | ConvertTo-Json -Depth 6
} finally {
    if ($serial.IsOpen) {
        $serial.Close()
    }
    $serial.Dispose()
}
