[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("list", "build")]
    [string]$Action,

    [string]$ProjectRoot = ".",
    [string]$Board,
    [string]$Name
)

$ErrorActionPreference = "Stop"

$root = Resolve-Path -LiteralPath $ProjectRoot
$releaseScript = Join-Path $root.Path "scripts\\release.py"

if (-not (Test-Path -LiteralPath $releaseScript)) {
    throw "Cannot find scripts\\release.py under $($root.Path)"
}

Push-Location $root.Path

try {
    switch ($Action) {
        "list" {
            & python $releaseScript --list-boards --json
            if ($LASTEXITCODE -ne 0) {
                throw "release.py list failed with exit code $LASTEXITCODE"
            }
        }
        "build" {
            if (-not $Board) {
                throw "Action build requires -Board"
            }
            $args = @($releaseScript, $Board)
            if ($Name) {
                $args += @("--name", $Name)
            }
            & python @args
            if ($LASTEXITCODE -ne 0) {
                throw "release.py build failed with exit code $LASTEXITCODE"
            }
        }
    }
} finally {
    Pop-Location
}
