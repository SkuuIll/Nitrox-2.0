# NITROX - COMPILACIÓN COMPLETA

## ¿Qué es Nitrox?
Nitrox es un mod de código abierto que añade funcionalidad multijugador al juego Subnautica, permitiendo que múltiples jugadores exploren, construyan y sobrevivan juntos en el mundo oceánico de Subnautica.

## Contenido de esta compilación

### 📁 Launcher/
**Aplicación principal del usuario**
- `Nitrox.Launcher.exe` - Ejecutar este archivo para iniciar Nitrox
- Incluye todas las dependencias necesarias
- Interfaz gráfica para gestionar la instalación y configuración

### 📁 Server/
**Servidor dedicado**
- `NitroxServer-Subnautica.exe` - Servidor independiente para hosting
- Permite crear servidores dedicados sin necesidad del juego
- Configuración avanzada disponible

### 📁 Client/
**Archivos del cliente**
- `NitroxClient.dll` - Biblioteca principal del mod
- Se instala automáticamente por el Launcher
- No ejecutar manualmente

### 📁 Patcher/
**Sistema de modificación**
- `NitroxPatcher.dll` - Sistema de parches Harmony
- Se instala automáticamente por el Launcher
- No ejecutar manualmente

## 🚀 Inicio rápido

### Para usuarios normales:
1. **Ejecutar**: `Iniciar_Nitrox_Launcher.bat` o `Launcher/Nitrox.Launcher.exe`
2. **Seguir** las instrucciones en pantalla
3. **Instalar** el mod en Subnautica
4. **Unirse** a un servidor o crear uno

### Para servidores dedicados:
1. **Ejecutar**: `Iniciar_Servidor_Dedicado.bat` o `Server/NitroxServer-Subnautica.exe`
2. **Configurar** según sea necesario
3. **Compartir** la IP con los jugadores

## 📋 Requisitos del sistema

### Para el Launcher y Servidor:
- **Windows 10/11** (recomendado)
- **.NET 9.0 Runtime** - Se descarga automáticamente si no está instalado
- **4 GB RAM** mínimo
- **Conexión a Internet** para la primera configuración

### Para el Cliente:
- **Subnautica** instalado (Steam, Epic Games, etc.)
- **.NET Framework 4.7.2** - Incluido en Windows 10/11
- **BepInEx** - Se instala automáticamente

## 🔧 Solución de problemas

### El Launcher no inicia:
- Verificar que .NET 9.0 esté instalado
- Ejecutar como administrador si es necesario
- Revisar el antivirus (puede bloquear archivos)

### Problemas de conexión:
- Verificar firewall de Windows
- Configurar port forwarding si es necesario (puerto por defecto: 11000)
- Revisar la configuración de red

### El mod no funciona en Subnautica:
- Verificar que Subnautica esté cerrado durante la instalación
- Reinstalar el mod usando el Launcher
- Verificar la integridad de los archivos de Subnautica

## 📞 Soporte y comunidad

- **Discord**: https://discord.gg/E8B4X9s
- **GitHub**: https://github.com/SubnauticaNitrox/Nitrox
- **Documentación**: https://subnauticanitrox.github.io/Documentation/

## ⚖️ Licencia

Este proyecto está licenciado bajo GPL v3. Ver el archivo original README.md para más detalles.

## 🏗️ Información de compilación

- **Fecha**: 18 de agosto de 2025
- **Versión**: 1.8.0.0
- **Configuración**: Release
- **Plataforma**: Windows x64

---

**¡Disfruta jugando Subnautica en multijugador con Nitrox!** 🌊🐠