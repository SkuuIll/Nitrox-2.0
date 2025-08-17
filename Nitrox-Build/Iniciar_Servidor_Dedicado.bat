@echo off
echo ========================================
echo   NITROX SERVIDOR DEDICADO - SUBNAUTICA
echo ========================================
echo.
echo Iniciando el Servidor Dedicado de Nitrox...
echo NOTA: Este servidor se ejecutará en esta ventana.
echo Para detener el servidor, presiona Ctrl+C
echo.
pause

cd /d "%~dp0Server"
"NitroxServer-Subnautica.exe"

echo.
echo El servidor se ha detenido.
pause