@echo off
set "ENV_DIR=%~dp0"
echo Starting portable PostgreSQL database server on port 5433...

:: Run database on port 5433 to avoid conflicts with any other PostgreSQL installed globally on 5432
"%ENV_DIR%postgres\bin\pg_ctl.exe" -D "%ENV_DIR%postgres\data" -o "-p 5433" -l "%ENV_DIR%postgres\server.log" start

echo PostgreSQL server started!
echo Log file is saving at: %ENV_DIR%postgres\server.log
echo.
echo Database connection details:
echo Host: localhost
echo Port: 5433
echo User: postgres
echo Pass: (No password / trust authentication for local connections)
echo.
pause
