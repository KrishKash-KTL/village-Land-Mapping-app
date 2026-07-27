@echo off
set "ENV_DIR=%~dp0"
echo Stopping portable PostgreSQL database server...

"%ENV_DIR%postgres\bin\pg_ctl.exe" -D "%ENV_DIR%postgres\data" stop

echo PostgreSQL server stopped.
echo.
pause
