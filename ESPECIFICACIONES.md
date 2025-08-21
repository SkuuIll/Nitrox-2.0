# Especificaciones del Proyecto: Nitrox 2.0 (Actualizado)

Este documento detalla la estructura y el propósito de cada archivo y directorio importante en el proyecto Nitrox 2.0, un mod multijugador para Subnautica.

## 📁 Estructura del Directorio Raíz

- **`.git/`**: Directorio interno de Git para el control de versiones. No debe ser modificado.
- **`.gitattributes`**: Archivo de configuración de Git que define atributos por ruta.
- **`.gitignore`**: Archivo que especifica qué archivos y directorios deben ser ignorados por Git.
- **`INSTALAR.bat`**: Script de instalación para **Windows**. Automatiza la configuración del servidor. Las descargas temporales (como .NET) se guardan en la carpeta `_temp_downloads/`.
- **`install-vps.sh`**: Script de instalación para **Linux (VPS)**. Automatiza la descarga de SteamCMD, Subnautica y la configuración del servidor. Por defecto, todo se instala en la carpeta local `_server_files/`.
- **`LICENSE.txt`**: Contiene la licencia del proyecto (GPL-3.0).
- **`README.md`**: Documentación principal del proyecto.
- **`ESPECIFICACIONES.md`**: Este mismo archivo, con la descripción de la estructura del proyecto.

## 📂 Directorio `Nitrox-Build/`

Contiene los archivos compilados y listos para usar del servidor y el lanzador de Nitrox.

- **`Iniciar_Nitrox_Launcher.bat`**: Script para iniciar el **lanzador del juego** en Windows.
- **`Iniciar_Servidor_Dedicado.bat`**: Script para iniciar el **servidor dedicado** en Windows.

### 📂 `Nitrox-Build/Launcher/`

Contiene los archivos del cliente que los jugadores usan para conectarse al servidor.

- **`NitroxLauncher.exe`**: El ejecutable principal del lanzador.

### 📂 `Nitrox-Build/Server/`

Contiene los archivos del servidor dedicado que gestiona el mundo del juego.

- **`NitroxServer-Subnautica.exe`**: El ejecutable principal del servidor.
- **Directorios generados**: Tras la instalación, se crearán carpetas como `Config/`, `Saves/` y `Logs/` para la configuración, partidas guardadas y registros del servidor.
