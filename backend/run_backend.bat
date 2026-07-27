@echo off
:: Village Mapping - Run API Server
set "BACKEND_DIR=%~dp0"
echo Starting Village Land Mapping API Server on port 8000...
echo API Docs will be at: http://localhost:8000/docs
echo Press Ctrl+C to stop.
echo.
"%BACKEND_DIR%venv\Scripts\uvicorn" main:app --reload --port 8000
pause
