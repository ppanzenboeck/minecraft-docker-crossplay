@echo off
setlocal enabledelayedexpansion
title Minecraft Crossplay Server - Launcher

set "SCRIPT_DIR=%~dp0"
cd /d "%SCRIPT_DIR%"

set "CREDENTIALS_FILE=%SCRIPT_DIR%credentials.txt"
set "TEMPLATE_FILE=%SCRIPT_DIR%credentials.example.txt"
set "ENV_FILE=%SCRIPT_DIR%.env"
set "SERVER_PROPS=%SCRIPT_DIR%data\server.properties"

:: Ensure credentials.txt exists
if not exist "%CREDENTIALS_FILE%" (
    if exist "%TEMPLATE_FILE%" (
        echo [!] No credentials.txt found. Creating one from credentials.example.txt...
        copy "%TEMPLATE_FILE%" "%CREDENTIALS_FILE%" >nul
        echo [!] Created credentials.txt. Please edit it with your secrets if needed.
    ) else (
        echo [!] Error: Neither credentials.txt nor credentials.example.txt found!
        pause
        exit /b 1
    )
)

echo [*] Loading credentials and settings from credentials.txt...

:: Clear/create .env file
type nul > "%ENV_FILE%"

:: Parse KEY=VALUE or KEY,VALUE format and write to .env
for /f "usebackq tokens=1,* delims==," %%A in ("%CREDENTIALS_FILE%") do (
    set "LINE=%%A"
    set "KEY=%%A"
    set "VAL=%%B"
    if not "!LINE:~0,1!"=="#" (
        for /f "tokens=* delims= " %%K in ("!KEY!") do set "KEY=%%K"
        for /f "tokens=* delims= " %%V in ("!VAL!") do set "VAL=%%V"
        if defined KEY (
            echo !KEY!=!VAL!>> "%ENV_FILE%"
            set "!KEY!=!VAL!"
        )
    )
)

:: Set default fallbacks if missing
if not defined PUID set "PUID=1000"
if not defined PGID set "PGID=1000"
if not defined MINECRAFT_VERSION set "MINECRAFT_VERSION=26.3"
if not defined MAX_MEMORY set "MAX_MEMORY=4096"
if not defined SERVER_PORT set "SERVER_PORT=25565"
if not defined BEDROCK_PORT set "BEDROCK_PORT=19132"
if not defined DYNMAP_PORT set "DYNMAP_PORT=8123"
if not defined BLUEMAP_PORT set "BLUEMAP_PORT=8100"
if not defined RCON_PORT set "RCON_PORT=25575"
if not defined SERVER_NAME set "SERVER_NAME=Crossplay Minecraft Server"
if not defined SERVER_MOTD set "SERVER_MOTD=Welcome to Minecraft 26.3 Purpur Crossplay Server!"

:: Append resolved defaults to .env
echo PUID=%PUID%>> "%ENV_FILE%"
echo PGID=%PGID%>> "%ENV_FILE%"
echo MINECRAFT_VERSION=%MINECRAFT_VERSION%>> "%ENV_FILE%"
echo MAX_MEMORY=%MAX_MEMORY%>> "%ENV_FILE%"
echo SERVER_PORT=%SERVER_PORT%>> "%ENV_FILE%"
echo BEDROCK_PORT=%BEDROCK_PORT%>> "%ENV_FILE%"
echo DYNMAP_PORT=%DYNMAP_PORT%>> "%ENV_FILE%"
echo BLUEMAP_PORT=%BLUEMAP_PORT%>> "%ENV_FILE%"
echo RCON_PORT=%RCON_PORT%>> "%ENV_FILE%"
if defined RCON_PASSWORD echo RCON_PASSWORD=%RCON_PASSWORD%>> "%ENV_FILE%"

:: Update server.properties via powershell helper
if exist "%SERVER_PROPS%" (
    echo [*] Injecting configuration into server.properties...
    powershell -NoProfile -Command ^
        "$p = Get-Content '%SERVER_PROPS%';" ^
        "$props = @{'server-port'='%SERVER_PORT%'; 'query.port'='%SERVER_PORT%'; 'server-name'='%SERVER_NAME%'; 'motd'='%SERVER_MOTD%'};" ^
        "if ('%RCON_PASSWORD%' -ne '') { $props['enable-rcon'] = 'true'; $props['rcon.port'] = '%RCON_PORT%'; $props['rcon.password'] = '%RCON_PASSWORD%' };" ^
        "foreach ($k in $props.Keys) { $pat = '^' + [regex]::Escape($k) + '=.*'; if ($p -match $pat) { $p = $p -replace $pat, ($k + '=' + $props[$k]) } else { $p += ($k + '=' + $props[$k]) } };" ^
        "Set-Content -Path '%SERVER_PROPS%' -Value $p"
)

:: Ensure canonical directories exist
if not exist "data\plugins\dynmap" mkdir "data\plugins\dynmap"
if not exist "data\plugins\bluemap\config" mkdir "data\plugins\bluemap\config"
if not exist "data\plugins\bluemap\data" mkdir "data\plugins\bluemap\data"
if not exist "data\plugins\bluemap\web" mkdir "data\plugins\bluemap\web"
if not exist "data\geyser" mkdir "data\geyser"

:: Sync Floodgate authentication key to Geyser Standalone proxy
if exist "data\plugins\floodgate\key.pem" (
    if not exist "data\geyser\key.pem" (
        echo [*] Syncing Floodgate key.pem to Geyser...
        copy "data\plugins\floodgate\key.pem" "data\geyser\key.pem" >nul
    )
)

:: Auto-update Geyser Standalone proxy binary
echo [*] Ensuring Geyser Standalone is up to date...
where curl.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    curl.exe -s -f -L -o "data\geyser\Geyser-Standalone.jar.tmp" --connect-timeout 5 --max-time 60 "https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/standalone" >nul 2>&1
    if exist "data\geyser\Geyser-Standalone.jar.tmp" (
        for %%I in ("data\geyser\Geyser-Standalone.jar.tmp") do (
            if %%~zI gtr 1000000 (
                move /y "data\geyser\Geyser-Standalone.jar.tmp" "data\geyser\Geyser-Standalone.jar" >nul
            ) else (
                del /f /q "data\geyser\Geyser-Standalone.jar.tmp" >nul
            )
        )
    )
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "$ErrorActionPreference = 'SilentlyContinue';" ^
        "try {" ^
        "  Invoke-WebRequest -Uri 'https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/standalone' -OutFile 'data\geyser\Geyser-Standalone.jar.tmp' -UseBasicParsing -TimeoutSec 60;" ^
        "  if (Test-Path 'data\geyser\Geyser-Standalone.jar.tmp') {" ^
        "    if ((Get-Item 'data\geyser\Geyser-Standalone.jar.tmp').Length -gt 1000000) {" ^
        "      Move-Item -Force 'data\geyser\Geyser-Standalone.jar.tmp' 'data\geyser\Geyser-Standalone.jar';" ^
        "    } else {" ^
        "      Remove-Item -Force 'data\geyser\Geyser-Standalone.jar.tmp';" ^
        "    }" ^
        "  }" ^
        "} catch {}"
)

:: Auto-update ViaBackwards cross-version compatibility plugin
echo [*] Ensuring ViaBackwards is up to date...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'SilentlyContinue';" ^
    "try {" ^
    "  $rel = Invoke-RestMethod -Uri 'https://api.github.com/repos/ViaVersion/ViaBackwards/releases/latest' -UseBasicParsing;" ^
    "  $asset = $rel.assets | Where-Object { $_.browser_download_url -like '*.jar' } | Select-Object -First 1;" ^
    "  if ($asset) {" ^
    "    Invoke-WebRequest -Uri $asset.browser_download_url -OutFile 'data\plugins\ViaBackwards.jar.tmp' -UseBasicParsing -TimeoutSec 30;" ^
    "    if (Test-Path 'data\plugins\ViaBackwards.jar.tmp') {" ^
    "      if ((Get-Item 'data\plugins\ViaBackwards.jar.tmp').Length -gt 100000) {" ^
    "        Move-Item -Force 'data\plugins\ViaBackwards.jar.tmp' 'data\plugins\ViaBackwards.jar';" ^
    "      } else {" ^
    "        Remove-Item -Force 'data\plugins\ViaBackwards.jar.tmp';" ^
    "      }" ^
    "    }" ^
    "  }" ^
    "} catch {}"

echo [*] Starting containers with Docker Compose...
docker compose up -d

echo.
echo ==================================================================
echo  Minecraft Crossplay Server Started Successfully!
echo ==================================================================
echo  - Version: Purpur %MINECRAFT_VERSION%
echo  - Java Edition Port:    %SERVER_PORT% (TCP)
echo  - Bedrock Edition Port: %BEDROCK_PORT% (UDP/TCP)
echo  - Dynmap Web Map:       http://localhost:%DYNMAP_PORT%
echo  - BlueMap 3D Web Map:   http://localhost:%BLUEMAP_PORT%
set "CF_URL="
for /f "tokens=*" %%U in ('powershell -NoProfile -Command "docker logs bluemap-tunnel 2>&1 | Select-String -Pattern 'https://[a-zA-Z0-9.-]+\.trycloudflare\.com' | ForEach-Object { $_.Matches.Value } | Select-Object -Last 1"') do set "CF_URL=%%U"
if defined CF_URL echo  - BlueMap Public HTTPS: %CF_URL%
echo ==================================================================
echo  To enter server console: console.bat
echo  To view server logs:    docker compose logs -f server
echo  To view bluemap logs:   docker compose logs -f bluemap
echo  To stop the server:     docker compose down
echo ==================================================================
