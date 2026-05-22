[CmdletBinding()]
param(
    [string]$ProjectRoot = "."
)

$ErrorActionPreference = "Stop"

function Test-CommandExists {
    param([string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $cmd) {
        return $null
    }
    return $cmd.Source
}

function Get-IdfTargetFromSdkconfig {
    param([string]$SdkconfigPath)
    if (-not (Test-Path -LiteralPath $SdkconfigPath)) {
        return $null
    }
    $match = Select-String -LiteralPath $SdkconfigPath -Pattern '^CONFIG_IDF_TARGET="([^"]+)"$' -ErrorAction SilentlyContinue
    if ($match) {
        return $match.Matches[0].Groups[1].Value
    }
    return $null
}

function Get-BoardTypeFromCompileCommands {
    param([string]$CompileCommandsPath)
    if (-not (Test-Path -LiteralPath $CompileCommandsPath)) {
        return $null
    }
    try {
        $json = Get-Content -LiteralPath $CompileCommandsPath -Raw | ConvertFrom-Json
        foreach ($item in $json) {
            if ($item.command -match '-DBOARD_TYPE=\\"([^"]+)\\"') {
                return $Matches[1]
            }
            if ($item.command -match '-DBOARD_TYPE=([^\s]+)') {
                return $Matches[1]
            }
        }
    } catch {
    }
    return $null
}

$root = Resolve-Path -LiteralPath $ProjectRoot
$rootPath = $root.Path
$cmakePath = Join-Path $rootPath "CMakeLists.txt"
$sdkconfigPath = Join-Path $rootPath "sdkconfig"
$compileCommandsPath = Join-Path $rootPath "build\\compile_commands.json"

$portsJson = & (Join-Path $PSScriptRoot "list_serial_ports.ps1")
$ports = @()
if ($portsJson) {
    try {
        $ports = $portsJson | ConvertFrom-Json
    } catch {
        $ports = @()
    }
}

$probe = [ordered]@{
    project_root = $rootPath
    is_espidf_project = ((Test-Path -LiteralPath $cmakePath) -and ((Get-Content -LiteralPath $cmakePath -TotalCount 30) -match 'project\.cmake'))
    environment = [ordered]@{
        idf_path = $env:IDF_PATH
        idf_tools_path = $env:IDF_TOOLS_PATH
        python = Test-CommandExists "python"
        idf_py = Test-CommandExists "idf.py"
        esptool = Test-CommandExists "esptool.py"
        openocd = Test-CommandExists "openocd"
    }
    project = [ordered]@{
        sdkconfig_exists = Test-Path -LiteralPath $sdkconfigPath
        compile_commands_exists = Test-Path -LiteralPath $compileCommandsPath
        idf_target = Get-IdfTargetFromSdkconfig -SdkconfigPath $sdkconfigPath
        board_type = Get-BoardTypeFromCompileCommands -CompileCommandsPath $compileCommandsPath
    }
    ports = $ports
}

$probe | ConvertTo-Json -Depth 6
