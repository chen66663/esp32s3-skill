[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("build", "flash", "monitor", "flash-monitor", "fullclean", "erase-flash", "merge-bin", "set-target")]
    [string]$Action,

    [string]$ProjectRoot = ".",
    [string]$Port,
    [string]$Baud = "460800",
    [string]$Target
)

$ErrorActionPreference = "Stop"

function Require-Command {
    param([string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $cmd) {
        throw "Required command not found: $Name"
    }
}

function Invoke-Idf {
    param([string[]]$Arguments)
    Write-Host ("idf.py " + ($Arguments -join " "))
    & idf.py @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "idf.py failed with exit code $LASTEXITCODE"
    }
}

$root = Resolve-Path -LiteralPath $ProjectRoot
Push-Location $root.Path

try {
    Require-Command "idf.py"

    switch ($Action) {
        "build" { Invoke-Idf @("build") }
        "flash" {
            $args = @()
            if ($Port) { $args += @("-p", $Port) }
            if ($Baud) { $args += @("-b", $Baud) }
            $args += "flash"
            Invoke-Idf $args
        }
        "monitor" {
            $args = @()
            if ($Port) { $args += @("-p", $Port) }
            $args += "monitor"
            Invoke-Idf $args
        }
        "flash-monitor" {
            $args = @()
            if ($Port) { $args += @("-p", $Port) }
            if ($Baud) { $args += @("-b", $Baud) }
            $args += @("flash", "monitor")
            Invoke-Idf $args
        }
        "fullclean" { Invoke-Idf @("fullclean") }
        "erase-flash" {
            $args = @()
            if ($Port) { $args += @("-p", $Port) }
            if ($Baud) { $args += @("-b", $Baud) }
            $args += "erase-flash"
            Invoke-Idf $args
        }
        "merge-bin" { Invoke-Idf @("merge-bin") }
        "set-target" {
            if (-not $Target) {
                throw "Action set-target requires -Target"
            }
            Invoke-Idf @("set-target", $Target)
        }
    }
} finally {
    Pop-Location
}
