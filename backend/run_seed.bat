@echo off
set "BACKEND_DIR=%~dp0"
echo Inserting sample village plot data...
"%BACKEND_DIR%venv\Scripts\python" "%BACKEND_DIR%seed_data.py"
pause
