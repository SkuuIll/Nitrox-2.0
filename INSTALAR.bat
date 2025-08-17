@echo off
chcp 65001 >nul
title 🌊 Nitrox 2.0 - Instalador Automático 🌊

echo.
echo ╔══════════════════════════════════════════════════════════════╗
echo ║                🌊 NITROX 2.0 INSTALLER 🌊                   ║
echo ║              Servidor Multijugador Subnautica               ║
echo ╚══════════════════════════════════════════════════════════════╝
echo.

:: Verificar si está ejecutándose como administrador
net session >nul 2>&1
if %errorLevel% == 0 (
    echo ✅ Ejecutándose como administrador
) else (
    echo ❌ ERROR: Este instalador necesita permisos de administrador
    echo.
    echo Por favor, haz clic derecho en "INSTALAR.bat" y selecciona "Ejecutar como administrador"
    echo.
    pause
    exit /b 1
)

echo.
echo 🔍 Verificando requisitos del sistema...

:: Verificar Windows 10/11
for /f "tokens=4-5 delims=. " %%i in ('ver') do set VERSION=%%i.%%j
if "%version%" == "10.0" (
    echo ✅ Windows 10/11 detectado
) else (
    echo ⚠️  Advertencia: Se recomienda Windows 10 o superior
)

:: Verificar .NET
echo 🔍 Verificando .NET Framework...
reg query "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" /v Release >nul 2>&1
if %errorLevel% == 0 (
    echo ✅ .NET Framework instalado
) else (
    echo ❌ .NET Framework no encontrado
    echo 📥 Descargando .NET Framework 4.7.2...
    powershell -Command "Invoke-WebRequest -Uri 'https://download.microsoft.com/download/6/E/4/6E48E8AB-DC00-419E-9704-06DD46E5F81D/NDP472-KB4054530-x86-x64-AllOS-ENU.exe' -OutFile 'dotnet472.exe'"
    echo 🚀 Instalando .NET Framework...
    dotnet472.exe /quiet
    del dotnet472.exe
)

echo.
echo 📋 CONFIGURACIÓN DEL SERVIDOR
echo ═══════════════════════════════════════

set /p SERVER_NAME="🏷️  Nombre del servidor (por defecto: Mi Servidor Nitrox): "
if "%SERVER_NAME%"=="" set SERVER_NAME=Mi Servidor Nitrox

set /p ADMIN_PASSWORD="🔐 Password de administrador (OBLIGATORIO): "
if "%ADMIN_PASSWORD%"=="" (
    echo ❌ ERROR: El password de administrador es obligatorio
    pause
    exit /b 1
)

set /p SERVER_PASSWORD="🔒 Password del servidor (opcional, Enter para servidor público): "

set /p MAX_PLAYERS="👥 Máximo de jugadores (por defecto: 10): "
if "%MAX_PLAYERS%"=="" set MAX_PLAYERS=10

echo.
echo 🎮 Selecciona el modo de juego:
echo 1. Survival (Supervivencia)
echo 2. Creative (Creativo) 
echo 3. Hardcore (Extremo)
set /p GAME_MODE_CHOICE="Selecciona (1-3, por defecto: 1): "
if "%GAME_MODE_CHOICE%"=="" set GAME_MODE_CHOICE=1

if "%GAME_MODE_CHOICE%"=="1" set GAME_MODE=Survival
if "%GAME_MODE_CHOICE%"=="2" set GAME_MODE=Creative
if "%GAME_MODE_CHOICE%"=="3" set GAME_MODE=Hardcore

echo.
echo 📁 Creando directorios del servidor...
if not exist "Servidor" mkdir Servidor
if not exist "Servidor\Saves" mkdir Servidor\Saves
if not exist "Servidor\Config" mkdir Servidor\Config
if not exist "Servidor\Logs" mkdir Servidor\Logs

echo.
echo 📝 Generando configuración del servidor...

:: Crear archivo de configuración
(
echo {
echo   "ServerName": "%SERVER_NAME%",
echo   "ServerPort": 11000,
echo   "ServerPassword": "%SERVER_PASSWORD%",
echo   "AdminPassword": "%ADMIN_PASSWORD%",
echo   "GameMode": "%GAME_MODE%",
echo   "MaxPlayers": %MAX_PLAYERS%,
echo   "DisableAutoSave": false,
echo   "SaveInterval": 300000,
echo   "MaxBackups": 10,
echo   "SerializerMode": "PROTOBUF",
echo   "CreateFullEntityCache": false,
echo   "DisableAutoBackup": false
echo }
) > "Servidor\Config\server.cfg"

echo ✅ Configuración guardada en: Servidor\Config\server.cfg

echo.
echo 🔥 Configurando firewall de Windows...
netsh advfirewall firewall add rule name="Nitrox Server" dir=in action=allow protocol=UDP localport=11000 >nul 2>&1
echo ✅ Puerto 11000 UDP abierto en el firewall

echo.
echo 🚀 Creando accesos directos...

:: Crear script para iniciar servidor
(
echo @echo off
echo title 🌊 Servidor Nitrox 2.0 🌊
echo cd /d "%%~dp0"
echo echo.
echo echo ╔══════════════════════════════════════════════════════════════╗
echo echo ║                🌊 SERVIDOR NITROX 2.0 🌊                    ║
echo echo ║                     INICIANDO...                            ║
echo echo ╚══════════════════════════════════════════════════════════════╝
echo echo.
echo echo ✅ Servidor: %SERVER_NAME%
echo echo ✅ Puerto: 11000 UDP
echo echo ✅ Modo: %GAME_MODE%
echo echo ✅ Jugadores máx: %MAX_PLAYERS%
echo echo.
echo echo 🔗 Para conectarse, usa la IP: %%COMPUTERNAME%% o tu IP local
echo echo 📝 Logs del servidor se guardan en: Servidor\Logs\
echo echo.
echo "Nitrox-Build\Server\NitroxServer-Subnautica.exe" "%%cd%%\Servidor"
echo pause
) > "🚀 Iniciar Servidor.bat"

:: Crear script para iniciar launcher
(
echo @echo off
echo title 🎮 Nitrox Launcher 🎮
echo cd /d "%%~dp0"
echo "Nitrox-Build\Launcher\Nitrox.Launcher.exe"
) > "🎮 Iniciar Launcher.bat"

echo.
echo 📊 RESUMEN DE LA INSTALACIÓN
echo ═══════════════════════════════════════════════════════════════
echo ✅ Servidor configurado: %SERVER_NAME%
echo ✅ Puerto abierto: 11000 UDP
echo ✅ Modo de juego: %GAME_MODE%
echo ✅ Jugadores máximos: %MAX_PLAYERS%
echo ✅ Firewall configurado
echo ✅ Accesos directos creados
echo.

echo 🎯 CÓMO USAR:
echo ═══════════════════════════════════════════════════════════════
echo 1. 🚀 Doble clic en "🚀 Iniciar Servidor.bat" para iniciar el servidor
echo 2. 🎮 Doble clic en "🎮 Iniciar Launcher.bat" para el launcher de clientes
echo 3. 🌐 Comparte tu IP con amigos para que se conecten
echo.

echo 📡 INFORMACIÓN DE CONEXIÓN:
echo ═══════════════════════════════════════════════════════════════
echo 🖥️  Nombre del PC: %COMPUTERNAME%
echo 🔌 Puerto: 11000
echo 🌐 IP Local: 
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /c:"IPv4"') do echo     %%a

echo.
echo 🎉 ¡INSTALACIÓN COMPLETADA EXITOSAMENTE!
echo.
echo ⚠️  IMPORTANTE:
echo    - Mantén este instalador para futuras configuraciones
echo    - Los archivos del servidor están en la carpeta "Servidor"
echo    - Para cambiar configuración, edita: Servidor\Config\server.cfg
echo.

pause