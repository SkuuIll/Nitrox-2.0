# 🌊 Nitrox 2.0 - Servidor Multijugador Subnautica

[![Windows](https://img.shields.io/badge/Windows-10%2F11-blue?logo=windows)](https://www.microsoft.com/windows)
[![Linux VPS](https://img.shields.io/badge/Linux-VPS%20Ready-green?logo=linux)](https://github.com/SkuuIll/NITROX2.0)
[![Subnautica](https://img.shields.io/badge/Subnautica-Compatible-green?logo=steam)](https://store.steampowered.com/app/264710/Subnautica/)
[![License](https://img.shields.io/badge/License-GPL--3.0-red)](LICENSE.txt)

**Nitrox 2.0** permite jugar Subnautica en multijugador con tus amigos. Explora, construye y sobrevive juntos en el mundo oceánico de Subnautica.

> **📢 Nota**: Esta es una versión mejorada basada en el [proyecto original de Nitrox](https://github.com/SubnauticaNitrox/Nitrox) que añade un instalador fácil para Windows y un sistema completo de instalación automatizada para VPS Linux. Todo el mérito del mod multijugador va al equipo original de Nitrox.

## 🎯 Dos Formas de Usar Nitrox

### 🖥️ **Para Usuarios Normales (Windows)**
Instalador súper fácil con interfaz gráfica - ¡Solo hacer clic!

### 🐧 **Para Servidores VPS (Linux)**
Instalación completamente automatizada en una sola línea de comando

## 🚀 Instalación Súper Fácil (Windows)

### 1️⃣ Descargar
```
📥 Descarga el proyecto completo
🗂️ Extrae todos los archivos en una carpeta
```

### 2️⃣ Instalar
```
🖱️ Clic derecho en "INSTALAR.bat"
⚡ Selecciona "Ejecutar como administrador"
📋 Sigue las instrucciones en pantalla
```

### 3️⃣ ¡Jugar!
```
🚀 Doble clic en "🚀 Iniciar Servidor.bat"
🎮 Doble clic en "🎮 Iniciar Launcher.bat"
🌐 Comparte tu IP con amigos
```

## 🐧 Instalación Automatizada VPS (Linux)

### Instalación en Una Línea

```bash
# Descargar e instalar automáticamente
wget https://raw.githubusercontent.com/SkuuIll/NITROX2.0/master/install-vps.sh
chmod +x install-vps.sh

sudo ./install-vps.sh \
  --steam-user TU_USUARIO_STEAM \
  --steam-pass TU_PASSWORD_STEAM \
  --admin-password PASSWORD_ADMIN \
  --server-name "Mi Servidor Increíble"
```

### ¿Qué Hace Automáticamente?

✅ **Detecta tu distribución Linux** (Ubuntu, Debian, CentOS, etc.)  
✅ **Instala todas las dependencias** (.NET, SteamCMD, librerías)  
✅ **Descarga Subnautica completo** via Steam automáticamente  
✅ **Configura el servidor Nitrox** con parches VPS  
✅ **Crea servicio systemd** para gestión profesional  
✅ **Configura firewall** automáticamente  
✅ **Listo para usar** en 5-10 minutos  

### Gestión del Servidor

```bash
# Iniciar servidor
sudo systemctl start nitrox-server

# Detener servidor  
sudo systemctl stop nitrox-server

# Ver estado
sudo systemctl status nitrox-server

# Ver logs en tiempo real
sudo journalctl -u nitrox-server -f
```

## 📋 Requisitos

- ✅ **Windows 10/11**
- ✅ **Subnautica** (versión Steam)
- ✅ **4GB RAM** mínimo
- ✅ **Conexión a Internet** para descargar archivos

## 🎮 Características

### 🌟 **Multijugador Completo**
- 👥 **Hasta 100 jugadores** (configurable)
- 🏗️ **Construcción cooperativa** de bases
- 🚗 **Vehículos compartidos** (Seamoth, Exosuit, Cyclops)
- 💬 **Chat integrado** para comunicación
- 🎒 **Inventarios sincronizados**

### ⚙️ **Fácil Configuración**
- 🔧 **Instalador automático** con interfaz gráfica
- 🎯 **Configuración guiada** paso a paso
- 🔥 **Firewall automático** configurado
- 📁 **Organización automática** de archivos

### 🛡️ **Características Avanzadas**
- 💾 **Guardado automático** cada 5 minutos
- 🔄 **Backups automáticos** del mundo
- 🔐 **Protección con contraseña** opcional
- 📊 **Logs detallados** para troubleshooting

## 🎯 Modos de Juego

| Modo | Descripción |
|------|-------------|
| 🏊 **Survival** | Experiencia clásica con hambre, sed y oxígeno |
| 🎨 **Creative** | Recursos ilimitados para construcción libre |
| ⚡ **Hardcore** | Un solo intento, máxima dificultad |

## 🌐 Cómo Conectarse

### Para el Host (quien ejecuta el servidor):
1. 🚀 Ejecuta "🚀 Iniciar Servidor.bat"
2. 🎮 Ejecuta "🎮 Iniciar Launcher.bat"
3. 🔗 Conecta usando "localhost" o "127.0.0.1"

### Para Amigos:
1. 🎮 Ejecuta "🎮 Iniciar Launcher.bat"
2. 🌐 Usa la IP del host para conectar
3. 🔑 Ingresa la contraseña si es necesaria

### 📡 Encontrar tu IP:
```
🖥️ Presiona Win + R
⌨️ Escribe "cmd" y presiona Enter
💻 Escribe "ipconfig" y presiona Enter
🔍 Busca "Dirección IPv4"
```

## 🛠️ Configuración Avanzada

### 📝 Configuración Windows (INSTALAR.bat)
Abre: `Servidor\Config\server.cfg`

```json
{
  "ServerName": "Mi Servidor Increíble",
  "ServerPort": 11000,
  "ServerPassword": "mi_password",
  "AdminPassword": "admin_password",
  "GameMode": "Survival",
  "MaxPlayers": 10,
  "SaveInterval": 300000
}
```

### 🔧 Opciones Disponibles:
- **ServerName**: Nombre que aparece en el launcher
- **ServerPort**: Puerto UDP (por defecto 11000)
- **ServerPassword**: Contraseña para unirse (vacío = público)
- **AdminPassword**: Contraseña para comandos de admin
- **GameMode**: Survival, Creative, o Hardcore
- **MaxPlayers**: Número máximo de jugadores (1-100)
- **SaveInterval**: Intervalo de guardado en milisegundos

### 🔧 Parámetros de Instalación VPS

| Parámetro | Descripción | Requerido | Ejemplo |
|-----------|-------------|-----------|---------|
| `--steam-user` | Usuario de Steam | ✅ | `--steam-user miusuario` |
| `--steam-pass` | Password de Steam | ✅ | `--steam-pass mipassword` |
| `--admin-password` | Password de administrador | ✅ | `--admin-password admin123` |
| `--server-name` | Nombre del servidor | ❌ | `--server-name "Mi Servidor"` |
| `--server-password` | Password del servidor | ❌ | `--server-password "secreto"` |
| `--max-players` | Jugadores máximos (1-100) | ❌ | `--max-players 50` |
| `--install-dir` | Directorio de instalación | ❌ | `--install-dir /home/nitrox` |

### Ejemplo Completo

```bash
sudo ./install-vps.sh \
  --steam-user miusuario \
  --steam-pass mipassword \
  --admin-password admin123 \
  --server-name "Servidor Épico de Subnautica" \
  --server-password "password_secreto" \
  --max-players 50 \
  --install-dir /opt/nitrox
```

## 🆘 Solución de Problemas

### ❌ "No se puede conectar al servidor"
```
🔥 Verifica que el firewall esté configurado
🌐 Confirma que la IP sea correcta
🔌 Asegúrate que el puerto 11000 esté abierto
```

### ❌ "Error al iniciar servidor"
```
⚡ Ejecuta como administrador
🎮 Verifica que Subnautica esté instalado
💾 Revisa que haya espacio en disco
```

### ❌ "Lag o desconexiones"
```
📡 Verifica la conexión a internet
💻 Cierra otros programas que usen internet
🔧 Reduce el número de jugadores máximos
```

## 📁 Estructura de Archivos

```
Nitrox 2.0/
├── INSTALAR.bat               # Instalador Windows automático
├── install-vps.sh             # Instalador VPS Linux automático
├── Nitrox-Build/             # Archivos del servidor y launcher
│   ├── Server/               # Servidor Nitrox
│   ├── Launcher/             # Launcher para clientes
│   ├── Iniciar_Servidor_Dedicado.bat    # Iniciar servidor (Windows)
│   └── Iniciar_Nitrox_Launcher.bat      # Iniciar launcher (Windows)
├── Start Server .txt         # Instrucciones servidor manual
├── LICENSE.txt               # Licencia del proyecto
└── README.md                 # Este archivo
```

### Después de Instalación VPS:
```
/opt/nitrox/                  # Instalación en VPS
├── steamcmd/                 # SteamCMD para descargas
├── gamefiles/                # Archivos de Subnautica
├── server/                   # Servidor Nitrox configurado
│   ├── UserData/Config/      # Configuración del servidor
│   ├── Saves/                # Mundos guardados
│   └── Logs/                 # Logs del servidor
├── start-server.sh           # Script para iniciar
├── stop-server.sh            # Script para detener
└── status-server.sh          # Script para ver estado
```

## 🤝 Soporte y Comunidad

### 🐛 Reportar Problemas
- 📧 [Crear Issue](https://github.com/SkuuIll/NITROX2.0/issues)
- 💬 [Discord Community](https://discord.gg/nitrox)

### 📚 Recursos Útiles
- 🎮 [Guía Oficial Subnautica](https://subnautica.fandom.com/)
- 🔧 [Comandos de Admin](https://github.com/SkuuIll/NITROX2.0/wiki/Admin-Commands)
- 🌐 [Configuración de Red](https://github.com/SkuuIll/NITROX2.0/wiki/Network-Setup)

## 📄 Licencia

Este proyecto está bajo la licencia GPL-3.0. Ver [LICENSE.txt](LICENSE.txt) para más detalles.

## 🙏 Créditos y Reconocimientos

### 🌟 **Proyecto Original**
Este proyecto está basado en el increíble trabajo del **[Equipo Nitrox Original](https://github.com/SubnauticaNitrox/Nitrox)**

- 🔗 **Repositorio Original**: https://github.com/SubnauticaNitrox/Nitrox
- 👥 **Desarrolladores Originales**: [SubnauticaNitrox Team](https://github.com/SubnauticaNitrox)
- 🎯 **Concepto y Código Base**: Todo el mérito va al equipo original de Nitrox

### 🚀 **Contribuciones de esta Versión**
- 🐳 **Sistema Docker/VPS**: Implementación completa para despliegue en servidores
- 🖥️ **Instalador Windows**: Interfaz gráfica para usuarios finales
- 📚 **Documentación Mejorada**: Guías para usuarios y administradores
- ⚙️ **Automatización**: Scripts de configuración y despliegue

### 🎮 **Agradecimientos Especiales**
- **[SubnauticaNitrox Team](https://github.com/SubnauticaNitrox/Nitrox)** - Por crear y mantener el mod Nitrox original
- **Unknown Worlds Entertainment** - Por desarrollar Subnautica
- **Comunidad de Modding de Subnautica** - Por el apoyo y feedback continuo
- **Contribuidores del Proyecto Original** - Por su trabajo incansable en hacer posible el multijugador

### 📜 **Nota Importante**
Esta es una versión modificada que añade funcionalidades de despliegue Docker y un instalador fácil para Windows. El código base y la funcionalidad principal del multijugador pertenecen completamente al [proyecto original de Nitrox](https://github.com/SubnauticaNitrox/Nitrox).

## 🛠️ Comandos Útiles

### Para Windows (Instalador)
```batch
# Ver logs del servidor
type "Servidor\Logs\server.log"

# Reiniciar servidor
# Cerrar ventana del servidor y volver a abrir "🚀 Iniciar Servidor.bat"
```

### Para VPS Linux
```bash
# Ver logs del servidor
sudo journalctl -u nitrox-server -f

# Verificar estado del servidor
sudo systemctl status nitrox-server

# Reiniciar servidor
sudo systemctl restart nitrox-server

# Ver configuración del servidor
cat /opt/nitrox/server/UserData/Config/server.cfg

# Crear backup manual
tar -czf nitrox-backup-$(date +%Y%m%d).tar.gz /opt/nitrox/server/Saves/

# Ver jugadores conectados
netstat -an | grep :11000 | grep ESTABLISHED | wc -l
```

---

<div align="center">

**🌊 ¡Sumérgete en la aventura multijugador! 🌊**

*¿Problemas? ¿Sugerencias? ¡Abre un issue en GitHub!*

</div>

<!-- Update Final -->