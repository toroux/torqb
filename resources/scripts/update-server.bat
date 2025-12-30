@echo off
REM Quick update script - pulls latest changes and optionally restarts server

echo ========================================
echo FiveM Server Auto-Update
echo ========================================
echo.

cd /d "%~dp0"

if "%1"=="restart" (
    echo Pulling latest changes and restarting server...
    powershell.exe -ExecutionPolicy Bypass -File "restart-server.ps1" -Branch main
) else (
    echo Pulling latest changes...
    powershell.exe -ExecutionPolicy Bypass -File "auto-pull.ps1" -Branch main
)

echo.
echo Done!
pause


