# quick_start.ps1 - Ek script se sab kuch shuru karo
# Run karo: .\quick_start.ps1

$EnvDir = $PSScriptRoot
$BackendDir = Join-Path $EnvDir "backend"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Village Land Mapping - Quick Start" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan

# ── Step 1: Check Python ────────────────────────────────────────────
Write-Host "`n[1/4] Python check kar rahe hain..." -ForegroundColor Yellow
$python = Get-Command python -ErrorAction SilentlyContinue
if (-not $python) {
    Write-Host "ERROR: Python nahi mila. Please install Python from https://python.org" -ForegroundColor Red
    Write-Host "Install ke baad PATH mein add karo aur dobara run karo." -ForegroundColor Red
    pause
    exit 1
}
$pyVersion = & python --version 2>&1
Write-Host "Python found: $pyVersion" -ForegroundColor Green

# ── Step 2: Create virtual environment ─────────────────────────────
$venvPath = Join-Path $BackendDir "venv"
if (-not (Test-Path $venvPath)) {
    Write-Host "`n[2/4] Virtual environment bana rahe hain..." -ForegroundColor Yellow
    & python -m venv $venvPath
    Write-Host "Virtual environment ready!" -ForegroundColor Green
} else {
    Write-Host "`n[2/4] Virtual environment already exists. Skipping." -ForegroundColor Green
}

# ── Step 3: Install packages ────────────────────────────────────────
$pipExe = Join-Path $venvPath "Scripts\pip.exe"
$reqFile = Join-Path $BackendDir "requirements.txt"

Write-Host "`n[3/4] Python packages install kar rahe hain..." -ForegroundColor Yellow
Write-Host "      (Pehli baar mein 2-3 minute lag sakte hain)" -ForegroundColor Gray
& $pipExe install --upgrade pip -q
& $pipExe install -r $reqFile

if ($LASTEXITCODE -ne 0) {
    Write-Host "`nERROR: Package install mein problem aayi." -ForegroundColor Red
    pause
    exit 1
}
Write-Host "Packages install ho gaye!" -ForegroundColor Green

# ── Step 4: Start server ────────────────────────────────────────────
Write-Host "`n[4/4] API Server shuru kar rahe hain..." -ForegroundColor Yellow
Write-Host "      API Docs: http://localhost:8000/docs" -ForegroundColor Cyan
Write-Host "      Press Ctrl+C to stop." -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan

$uvicornExe = Join-Path $venvPath "Scripts\uvicorn.exe"
Set-Location $BackendDir
& $uvicornExe main:app --reload --port 8000
