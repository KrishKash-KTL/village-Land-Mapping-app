# Village Mapping - Environment Setup Script (PowerShell)
# This script downloads, extracts, and configures Flutter, OpenJDK, Android SDK Command Line Tools, and PostgreSQL with PostGIS
# in a completely isolated directory.

$ProgressPreference = 'SilentlyContinue'
$EnvDir = $PSScriptRoot

# Create necessary directories
$DownloadDir = Join-Path $EnvDir "downloads"
if (-not (Test-Path $DownloadDir)) {
    New-Item -ItemType Directory -Path $DownloadDir | Out-Null
}

# URLs of all components
$Urls = @{
    "jdk"      = "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse";
    "flutter"  = "https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.22.2-stable.zip";
    "cmdline"  = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip";
    "postgres" = "https://sbp.enterprisedb.com/getfile.jsp?fileid=1260308";
    "postgis"  = "https://download.osgeo.org/postgis/windows/pg16/archive/postgis-bundle-pg16-3.4.2x64.zip"
}

# Download file helper
function Download-File {
    param ($Name, $Url, $Dest)
    if (Test-Path $Dest) {
        Write-Host "Found existing $Name archive at $Dest. Skipping download." -ForegroundColor Green
    } else {
        Write-Host "Downloading $Name... (Please wait, this can take a few minutes)" -ForegroundColor Yellow
        try {
            Invoke-WebRequest -Uri $Url -OutFile $Dest -TimeoutSec 600
            Write-Host "Downloaded $Name successfully." -ForegroundColor Green
        } catch {
            Write-Error "Failed to download $Name. Error: $_"
            exit 1
        }
    }
}

# Define local paths
$JdkZip = Join-Path $DownloadDir "jdk.zip"
$FlutterZip = Join-Path $DownloadDir "flutter.zip"
$CmdlineZip = Join-Path $DownloadDir "cmdline-tools.zip"
$PostgresZip = Join-Path $DownloadDir "postgres.zip"
$PostgisZip = Join-Path $DownloadDir "postgis.zip"

# 1. Download all components
Download-File "OpenJDK 17" $Urls.jdk $JdkZip
Download-File "Flutter SDK" $Urls.flutter $FlutterZip
Download-File "Android Cmdline Tools" $Urls.cmdline $CmdlineZip
Download-File "PostgreSQL" $Urls.postgres $PostgresZip
Download-File "PostGIS Extension" $Urls.postgis $PostgisZip

Write-Host "`nAll downloads complete. Starting extraction..." -ForegroundColor Cyan

# 2. Extract OpenJDK 17
$JdkDest = Join-Path $EnvDir "openjdk"
if (-not (Test-Path $JdkDest)) {
    Write-Host "Extracting OpenJDK 17..." -ForegroundColor Yellow
    $TempExtract = Join-Path $DownloadDir "temp_jdk"
    Expand-Archive -Path $JdkZip -DestinationPath $TempExtract
    $SubDir = Get-ChildItem -Directory -Path $TempExtract | Select-Object -First 1
    Move-Item -Path $SubDir.FullName -Destination $JdkDest
    Remove-Item -Path $TempExtract -Recurse -Force
    Write-Host "OpenJDK extracted to openjdk/." -ForegroundColor Green
} else {
    Write-Host "openjdk/ folder already exists. Skipping JDK extraction." -ForegroundColor Green
}

# 3. Extract Flutter SDK
$FlutterDest = Join-Path $EnvDir "flutter"
if (-not (Test-Path $FlutterDest)) {
    Write-Host "Extracting Flutter SDK..." -ForegroundColor Yellow
    Expand-Archive -Path $FlutterZip -DestinationPath $EnvDir
    Write-Host "Flutter extracted to flutter/." -ForegroundColor Green
} else {
    Write-Host "flutter/ folder already exists. Skipping Flutter extraction." -ForegroundColor Green
}

# 4. Extract Android Commandline Tools
$AndroidSdkDest = Join-Path $EnvDir "android-sdk"
$CmdlineDest = Join-Path $AndroidSdkDest "cmdline-tools\latest"
if (-not (Test-Path $CmdlineDest)) {
    Write-Host "Extracting Android Commandline Tools..." -ForegroundColor Yellow
    $TempExtract = Join-Path $DownloadDir "temp_cmdline"
    Expand-Archive -Path $CmdlineZip -DestinationPath $TempExtract
    # The zip contains a 'cmdline-tools' folder
    New-Item -ItemType Directory -Path $CmdlineDest | Out-Null
    Copy-Item -Path (Join-Path $TempExtract "cmdline-tools\*") -Destination $CmdlineDest -Recurse -Force
    Remove-Item -Path $TempExtract -Recurse -Force
    Write-Host "Android Commandline Tools set up at android-sdk/cmdline-tools/latest." -ForegroundColor Green
} else {
    Write-Host "android-sdk/cmdline-tools/latest already exists. Skipping Android cmdline tools extraction." -ForegroundColor Green
}

# 5. Extract PostgreSQL
$PostgresDest = Join-Path $EnvDir "postgres"
if (-not (Test-Path $PostgresDest)) {
    Write-Host "Extracting PostgreSQL..." -ForegroundColor Yellow
    $TempExtract = Join-Path $DownloadDir "temp_postgres"
    Expand-Archive -Path $PostgresZip -DestinationPath $TempExtract
    Move-Item -Path (Join-Path $TempExtract "pgsql") -Destination $PostgresDest
    Remove-Item -Path $TempExtract -Recurse -Force
    Write-Host "PostgreSQL extracted to postgres/." -ForegroundColor Green
} else {
    Write-Host "postgres/ folder already exists. Skipping PostgreSQL extraction." -ForegroundColor Green
}

# 6. Extract PostGIS and merge into PostgreSQL directory
$PostgisCheckFile = Join-Path $PostgresDest "lib\postgis-3.dll"
if (-not (Test-Path $PostgisCheckFile)) {
    Write-Host "Extracting PostGIS extension and merging with PostgreSQL..." -ForegroundColor Yellow
    $TempExtract = Join-Path $DownloadDir "temp_postgis"
    Expand-Archive -Path $PostgisZip -DestinationPath $TempExtract
    
    # Locate the extracted folder
    $ExtractedFolder = Get-ChildItem -Directory -Path $TempExtract | Select-Object -First 1
    
    # Copy files recursively to PostgreSQL directory
    Copy-Item -Path (Join-Path $ExtractedFolder.FullName "*") -Destination $PostgresDest -Recurse -Force
    Remove-Item -Path $TempExtract -Recurse -Force
    Write-Host "PostGIS extension integrated successfully." -ForegroundColor Green
} else {
    Write-Host "PostGIS extension is already integrated in PostgreSQL." -ForegroundColor Green
}

# 7. Initialize Database
$PgData = Join-Path $PostgresDest "data"
if (-not (Test-Path $PgData)) {
    Write-Host "Initializing PostgreSQL database..." -ForegroundColor Yellow
    $InitDbExe = Join-Path $PostgresDest "bin\initdb.exe"
    # Create DB with trust auth on local connection
    & $InitDbExe -D $PgData -U postgres --auth-local=trust
    Write-Host "Database initialized in postgres/data." -ForegroundColor Green
} else {
    Write-Host "Database already initialized." -ForegroundColor Green
}

# Cleanup downloads folder
Write-Host "`nDo you want to delete the downloaded ZIP files to save disk space? (y/n): " -NoNewline
$Response = Read-Host
if ($Response -eq "y" -or $Response -eq "Y") {
    Remove-Item -Path $DownloadDir -Recurse -Force
    Write-Host "Downloads folder cleaned up." -ForegroundColor Green
}

Write-Host "`n=======================================================" -ForegroundColor Cyan
Write-Host "  Setup Complete! All tools are now installed in:" -ForegroundColor Green
Write-Host "  $EnvDir" -ForegroundColor Green
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "1. Run 'env.bat' to start the local terminal." -ForegroundColor Yellow
Write-Host "2. Inside the terminal, type 'code .' to launch VS Code." -ForegroundColor Yellow
Write-Host "3. Run 'start-postgres.bat' to launch the database." -ForegroundColor Yellow
Write-Host "=======================================================" -ForegroundColor Cyan
