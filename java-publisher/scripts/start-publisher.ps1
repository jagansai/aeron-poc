# start-publisher.ps1 - Start Java Publisher with required JVM flags
param(
    [string]$Count = '10',        # Number of messages or 'loop' for infinite
    [string]$IntervalMs = '500',  # Interval between messages in ms
    [switch]$Background           # Run in background
)

$Root = Split-Path -Parent $PSScriptRoot
$Jar = Join-Path $Root 'build\libs\java-publisher.jar'

# Use Java 24 if available, otherwise fall back to default java
$Java24 = 'D:\software\jdk-24.0.2\bin\java.exe'
if (Test-Path $Java24) {
    $JavaExe = $Java24
} else {
    $JavaExe = 'java'
}

if (-not (Test-Path $Jar)) {
    Write-Host "JAR not found; building..."
    Push-Location $Root
    & .\gradlew.bat build
    Pop-Location
}

$JavaFlags = @(
    '--add-opens=java.base/jdk.internal.misc=ALL-UNNAMED',
    '--add-opens=java.base/java.util.zip=ALL-UNNAMED'
)

$JavaArgs = $JavaFlags + @('-jar', $Jar, $Count, $IntervalMs)

Write-Host "Using Java: $JavaExe"

if ($Background) {
    $LogDir = Join-Path $Root 'logs'
    New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
    $LogFile = Join-Path $LogDir 'java-publisher.log'
    Start-Process -FilePath $JavaExe -ArgumentList $JavaArgs -RedirectStandardOutput $LogFile -RedirectStandardError "$LogFile.err" -NoNewWindow
    Write-Host "Publisher started in background; logs: $LogFile"
} else {
    & $JavaExe @JavaArgs
}
