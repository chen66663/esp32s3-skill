[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("build-flash-capture", "flash-capture", "capture", "request", "loop")]
    [string]$Action,

    [string]$ProjectRoot = ".",
    [string]$FlashPort,
    [string]$SerialPort,
    [int]$FlashBaud = 460800,
    [int]$SerialBaud = 115200,
    [int]$BootWaitMs = 1800,
    [int]$CaptureMs = 4500,
    [int]$QuietMs = 250,
    [string[]]$Commands = @()
)

$ErrorActionPreference = "Stop"

function Invoke-JsonScript {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $jsonText = & $ScriptPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Script failed: $ScriptPath"
    }
    return $jsonText | ConvertFrom-Json
}

$root = Resolve-Path -LiteralPath $ProjectRoot
$doScript = Join-Path $PSScriptRoot "espidf_do.ps1"
$serialScript = Join-Path $PSScriptRoot "serial_roundtrip.ps1"

function Run-Build {
    & $doScript -Action build -ProjectRoot $root.Path
    if ($LASTEXITCODE -ne 0) {
        throw "Build failed"
    }
}

function Run-Flash {
    if (-not $FlashPort) {
        throw "Flash requires -FlashPort"
    }
    & $doScript -Action flash -ProjectRoot $root.Path -Port $FlashPort -Baud $FlashBaud
    if ($LASTEXITCODE -ne 0) {
        throw "Flash failed"
    }
}

function Run-Capture {
    if (-not $SerialPort) {
        throw "Capture requires -SerialPort"
    }
    return Invoke-JsonScript -ScriptPath $serialScript -Arguments @(
        "-Action", "capture",
        "-Port", $SerialPort,
        "-Baud", "$SerialBaud",
        "-CaptureMs", "$CaptureMs",
        "-QuietMs", "$QuietMs"
    )
}

function Run-Request {
    if (-not $SerialPort) {
        throw "Request requires -SerialPort"
    }
    $args = @(
        "-Action", "request",
        "-Port", $SerialPort,
        "-Baud", "$SerialBaud",
        "-CaptureMs", "$CaptureMs",
        "-QuietMs", "$QuietMs"
    )
    foreach ($cmd in $Commands) {
        $args += @("-Lines", $cmd)
    }
    return Invoke-JsonScript -ScriptPath $serialScript -Arguments $args
}

$summary = [ordered]@{
    action = $Action
    project_root = $root.Path
    flash_port = $FlashPort
    serial_port = $SerialPort
    flash_baud = $FlashBaud
    serial_baud = $SerialBaud
    commands = $Commands
    build = $false
    flash = $false
    boot_capture = $null
    request_result = $null
}

switch ($Action) {
    "build-flash-capture" {
        Run-Build
        $summary.build = $true
        Run-Flash
        $summary.flash = $true
        Start-Sleep -Milliseconds $BootWaitMs
        $summary.boot_capture = Run-Capture
    }
    "flash-capture" {
        Run-Flash
        $summary.flash = $true
        Start-Sleep -Milliseconds $BootWaitMs
        $summary.boot_capture = Run-Capture
    }
    "capture" {
        $summary.boot_capture = Run-Capture
    }
    "request" {
        $summary.request_result = Run-Request
    }
    "loop" {
        Run-Build
        $summary.build = $true
        Run-Flash
        $summary.flash = $true
        Start-Sleep -Milliseconds $BootWaitMs
        $summary.boot_capture = Run-Capture
        if ($Commands.Count -gt 0) {
            $summary.request_result = Run-Request
        }
    }
}

$summary | ConvertTo-Json -Depth 8
