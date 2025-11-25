# start_all.ps1 - Start C++ Subscriber and Java Publisher
# Usage: 
#   .\start_all.ps1                           # Use defaults
#   .\start_all.ps1 -ConfigFile .\run.conf    # Use config file
#   .\start_all.ps1 -Config Debug -MessageCount 5 -IntervalMs 200  # Use params
param(
    [string]$ConfigFile,          # Optional config file path
    [string]$Config = 'Debug',    # Build config: Debug or Release
    [string]$MessageCount = '10', # Number of messages ('loop' or -1 for infinite)
    [string]$IntervalMs = '100',  # Interval between messages in milliseconds
    [switch]$SubscriberBackground,# Run subscriber in background (no window)
    [switch]$PublisherBackground  # Run publisher in background (no window)
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot

# Parse config file if provided
if ($ConfigFile -and (Test-Path $ConfigFile)) {
    Write-Host "Loading config from: $ConfigFile" -ForegroundColor Cyan
    
    $cfg = @{}
    Get-Content $ConfigFile | ForEach-Object {
        if ($_ -match '^\s*#' -or $_ -match '^\s*$') { return }
        if ($_ -match '^\s*([^=\s]+)\s*=\s*(.*)$') {
            $cfg[$matches[1].Trim()] = $matches[2].Trim()
        }
    }
    
    # Apply config values (config file overrides defaults, but explicit params override config)
    if ($cfg['publisher.msg.limit']) {
        $limit = $cfg['publisher.msg.limit']
        if ($limit -eq '-1') { $MessageCount = 'loop' } else { $MessageCount = $limit }
    }
    if ($cfg['publisher.msg.interval.ms']) {
        $IntervalMs = $cfg['publisher.msg.interval.ms']
    }
    if ($cfg['publisher.msg.rate'] -and -not $cfg['publisher.msg.interval.ms']) {
        $rate = [int]$cfg['publisher.msg.rate']
        if ($rate -gt 0) { $IntervalMs = [math]::Floor(1000 / $rate).ToString() }
    }
    if ($cfg['subscriber.run.in.bg'] -eq 'true') {
        $SubscriberBackground = $true
    }
    if ($cfg['publisher.run.in.bg'] -eq 'true') {
        $PublisherBackground = $true
    }
}

# Paths
$AeronDir = "C:\Users\$env:USERNAME\AppData\Local\Temp\aeron-$env:USERNAME"
$SubscriberScript = Join-Path $Root 'cpp-subscriber\scripts\run-subscriber.ps1'
$PublisherScript = Join-Path $Root 'java-publisher\scripts\start-publisher.ps1'
$AeronBuildDir = Join-Path $Root '..\aeron\cppbuild\Release'

# Set environment
$Env:AERON_BUILD_DIR = $AeronBuildDir

Write-Host "=== Aeron POC Startup ===" -ForegroundColor Cyan
Write-Host "Config: $Config, Messages: $MessageCount, Interval: ${IntervalMs}ms"
Write-Host "Subscriber BG: $SubscriberBackground, Publisher BG: $PublisherBackground"

# 1. Check if Media Driver is running
Write-Host "`n[1/3] Checking Media Driver..." -ForegroundColor Yellow

$cncFile = Join-Path $AeronDir 'cnc.dat'
if (-not (Test-Path $cncFile)) {
    Write-Host "ERROR: Media Driver is NOT running!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please start the Media Driver first in a separate terminal:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host '  cd D:\code\aeron_poc\java-publisher' -ForegroundColor White
    Write-Host '  .\gradlew.bat run --args="driver"' -ForegroundColor White
    exit 1
}

Write-Host "Media Driver is running" -ForegroundColor Green

# 2. Start C++ Subscriber
Write-Host "`n[2/3] Starting C++ Subscriber..." -ForegroundColor Yellow

if (-not (Test-Path $SubscriberScript)) {
    Write-Error "Subscriber script not found at: $SubscriberScript"
    exit 1
}

$subArgs = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $SubscriberScript, '-Config', $Config)

if ($SubscriberBackground) {
    $LogDir = Join-Path $Root 'logs'
    New-Item -ItemType Directory -Force -Path $LogDir | Out-Null
    $subLog = Join-Path $LogDir 'subscriber.log'
    $subProcess = Start-Process -FilePath 'powershell' -ArgumentList $subArgs `
        -PassThru -WindowStyle Hidden -WorkingDirectory (Join-Path $Root 'cpp-subscriber') `
        -RedirectStandardOutput $subLog -RedirectStandardError "$subLog.err"
    Write-Host "Subscriber started in background (PID: $($subProcess.Id), log: $subLog)" -ForegroundColor Green
} else {
    $subProcess = Start-Process -FilePath 'powershell' -ArgumentList $subArgs `
        -PassThru -WindowStyle Normal -WorkingDirectory (Join-Path $Root 'cpp-subscriber')
    Write-Host "Subscriber started (PID: $($subProcess.Id))" -ForegroundColor Green
}

Write-Host "Waiting 2 seconds for subscription..."
Start-Sleep -Seconds 2

# Verify subscriber is still running
if ($subProcess.HasExited) {
    Write-Host "ERROR: Subscriber exited prematurely (exit code: $($subProcess.ExitCode))" -ForegroundColor Red
    exit 1
}

Write-Host "Subscriber is ready" -ForegroundColor Green

# 3. Run Java Publisher
Write-Host "`n[3/3] Starting Java Publisher..." -ForegroundColor Yellow

if (-not (Test-Path $PublisherScript)) {
    Write-Error "Publisher script not found at: $PublisherScript"
    exit 1
}

if ($PublisherBackground) {
    & $PublisherScript -Count $MessageCount -IntervalMs $IntervalMs -Background
} else {
    & $PublisherScript -Count $MessageCount -IntervalMs $IntervalMs
}

Write-Host "`n=== Done ===" -ForegroundColor Cyan
if (-not $SubscriberBackground) {
    Write-Host "Press Ctrl+C in the Subscriber window to stop it."
}
