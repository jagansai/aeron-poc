param(
    [string]$BuildDir = 'build',
    [string]$Config = 'Release'    
)

$Root = Split-Path -Parent $PSScriptRoot
$BinPath = Join-Path $BuildDir "bin\$Config\cpp-subscriber.exe"

"Running C++ Subscriber from $BinPath" | Write-Host

if (-not (Test-Path $BinPath)) {
    Write-Error "Subscriber binary not found in ${BuildDir}\bin. Build first with `cmake .. -DAERON_BUILD_DIR=<path>` and `cmake --build . --config Release`."
    exit 1
}

if ($Env:AERON_BUILD_DIR) {
    $AeronLibDir = Join-Path $Env:AERON_BUILD_DIR 'binaries'
} else {
    $DefaultBuild = Join-Path $Root '..\aeron\build'
    $AeronLibDir = Join-Path $DefaultBuild 'binaries'
}

if (Test-Path $AeronLibDir) {
    $env:PATH = "$AeronLibDir;$env:PATH"
} else {
    Write-Host "Aeron lib dir not found at $AeronLibDir; ensure AERON_BUILD_DIR points to your Aeron cpp build output."
}

& $BinPath


