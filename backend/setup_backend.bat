@echo off
:: Village Mapping - Backend Setup Script
:: Virtual environment banao aur saare packages install karo

set "BACKEND_DIR=%~dp0"
set "ENV_DIR=%BACKEND_DIR%.."

echo ======================================================
echo   Village Land Mapping - Backend Setup
echo ======================================================

:: Check if Python is available (from portable env PATH via env.bat)
python --version >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Python nahi mila!
    echo Pehle 'env.bat' run karo to load the portable environment,
    echo ya Python install karo from https://python.org
    pause
    exit /b 1
)

echo.
echo [1/3] Python virtual environment bana rahe hain...
python -m venv "%BACKEND_DIR%venv"
if errorlevel 1 (
    echo ERROR: Virtual environment banane mein error aaya.
    pause
    exit /b 1
)
echo Virtual environment ready!

echo.
echo [2/3] Required packages install kar rahe hain...
echo (Thoda waqt lagega - Please wait...)
"%BACKEND_DIR%venv\Scripts\pip" install --upgrade pip -q
"%BACKEND_DIR%venv\Scripts\pip" install -r "%BACKEND_DIR%requirements.txt"
if errorlevel 1 (
    echo ERROR: Package installation mein kuch problem aayi.
    pause
    exit /b 1
)

echo.
echo [3/3] Setup complete!
echo ======================================================
echo   Backend Setup Successful!
echo ======================================================
echo.
echo   Next Steps:
echo   1. Start PostgreSQL database: Double-click 'start-postgres.bat' in parent folder
echo   2. Start the API server: run_backend.bat
echo   3. Open API docs: http://localhost:8000/docs
echo   4. Insert sample data: run_seed.bat
echo ======================================================
pause
