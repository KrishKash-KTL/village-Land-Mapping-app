# Village Mapping - Local Environment PowerShell Setup
# To run this and keep variables in current shell, run it as: . .\env.ps1 (note the dot at start)

$EnvDir = $PSScriptRoot
$env:JAVA_HOME = Join-Path $EnvDir "openjdk"
$env:ANDROID_HOME = Join-Path $EnvDir "android-sdk"

# Add portable paths to the session PATH
$env:PATH = "$(Join-Path $EnvDir 'flutter\bin');$(Join-Path $EnvDir 'openjdk\bin');$(Join-Path $EnvDir 'android-sdk\cmdline-tools\latest\bin');$(Join-Path $EnvDir 'android-sdk\platform-tools');$(Join-Path $EnvDir 'postgres\bin');$env:PATH"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  Village Mapping - Portable Development Environment (PowerShell)" -ForegroundColor Green
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  JAVA_HOME    : $env:JAVA_HOME"
Write-Host "  ANDROID_HOME : $env:ANDROID_HOME"
Write-Host "  Flutter      : $(Join-Path $EnvDir 'flutter')"
Write-Host "  Postgres Port: 5433 (Run '.\start-postgres.bat' to start database)"
Write-Host "  VS Code      : Type 'code .' to open in this environment"
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  To delete this environment, simply delete the parent folder:" -ForegroundColor Yellow
Write-Host "  $EnvDir" -ForegroundColor Yellow
Write-Host "====================================================================" -ForegroundColor Cyan
