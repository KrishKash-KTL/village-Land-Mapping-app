@echo off
:: Village Mapping - Local Environment CMD Shell Setup
:: Running this script sets the PATH variables locally for the current command session.

set "ENV_DIR=%~dp0"
set "JAVA_HOME=%ENV_DIR%openjdk"
set "ANDROID_HOME=%ENV_DIR%android-sdk"

:: Update PATH locally to prioritize our local bin folders
set "PATH=%ENV_DIR%flutter\bin;%ENV_DIR%openjdk\bin;%ENV_DIR%android-sdk\cmdline-tools\latest\bin;%ENV_DIR%android-sdk\platform-tools;%ENV_DIR%postgres\bin;%PATH%"

echo ====================================================================
echo   Village Mapping - Portable Development Environment
echo ====================================================================
echo   JAVA_HOME    : %JAVA_HOME%
echo   ANDROID_HOME : %ANDROID_HOME%
echo   Flutter      : %ENV_DIR%flutter
echo   Postgres Port: 5433 (Type 'start-postgres.bat' to start database)
echo   VS Code      : Type 'code .' to open in this environment
echo ====================================================================
echo   To delete this environment, simply delete the parent folder:
echo   %ENV_DIR%
echo ====================================================================
cmd /k
