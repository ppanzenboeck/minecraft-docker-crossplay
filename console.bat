@echo off
setlocal enabledelayedexpansion
title Minecraft Crossplay Server Console

set "SCRIPT_DIR=%~dp0"
set "ENV_FILE=%SCRIPT_DIR%.env"
set "CREDENTIALS_FILE=%SCRIPT_DIR%credentials.txt"

set "RCON_PORT=25575"
set "RCON_PASSWORD="

set "TARGET_FILE="
if exist "%ENV_FILE%" (
    set "TARGET_FILE=%ENV_FILE%"
) else if exist "%CREDENTIALS_FILE%" (
    set "TARGET_FILE=%CREDENTIALS_FILE%"
)

if defined TARGET_FILE (
    for /f "usebackq tokens=1,* delims==," %%A in ("%TARGET_FILE%") do (
        set "KEY=%%A"
        set "VAL=%%B"
        for /f "tokens=* delims= " %%K in ("!KEY!") do set "KEY=%%K"
        for /f "tokens=* delims= " %%V in ("!VAL!") do set "VAL=%%V"
        if /i "!KEY!"=="RCON_PORT" set "RCON_PORT=!VAL!"
        if /i "!KEY!"=="RCON_PASSWORD" set "RCON_PASSWORD=!VAL!"
    )
)

if not defined RCON_PASSWORD (
    echo [-] Error: RCON_PASSWORD is not configured in credentials.txt or .env
    echo     Please set RCON_PASSWORD in credentials.txt and restart the server.
    pause
    exit /b 1
)

echo [*] Connecting to Minecraft RCON console on port %RCON_PORT%...
echo     (Type commands directly. Press Ctrl+C or type 'exit' to disconnect without stopping the server.)
echo.

docker run -it --rm --network host itzg/rcon-cli:latest --port %RCON_PORT% --password %RCON_PASSWORD% %*
