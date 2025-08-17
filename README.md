# 🌊 Nitrox 2.0 - Servidor Multijugador Subnautica

[![Windows](https://img.shields.io/badge/Windows-10%2F11-blue?logo=windows)](https://www.microsoft.com/windows)
[![Subnautica](https://img.shields.io/badge/Subnautica-Compatible-green?logo=steam)](https://store.steampowered.com/app/264710/Subnautica/)
[![License](https://img.shields.io/badge/License-GPL--3.0-red)](LICENSE.txt)

**Nitrox 2.0** permite jugar Subnautica en multijugador con tus amigos. Explora, construye y sobrevive juntos en el mundo oceánico de Subnautica.

## 🚀 Instalación Súper Fácil

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

### 📝 Editar Configuración
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
├── 🚀 Iniciar Servidor.bat    # Inicia el servidor
├── 🎮 Iniciar Launcher.bat    # Inicia el launcher
├── INSTALAR.bat               # Instalador automático
├── Nitrox-Build/             # Archivos del juego
│   ├── Server/               # Servidor Nitrox
│   ├── Launcher/             # Launcher para clientes
│   └── Client/               # Archivos del cliente
├── Servidor/                 # Datos del servidor
│   ├── Config/              # Configuración
│   ├── Saves/               # Mundos guardados
│   └── Logs/                # Logs del servidor
└── README.md                # Este archivo
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

## 🙏 Créditos

- **Equipo Nitrox Original** - Por crear este increíble mod
- **Unknown Worlds Entertainment** - Por Subnautica
- **Comunidad de Modding** - Por el apoyo continuo

---

<div align="center">

**🌊 ¡Sumérgete en la aventura multijugador! 🌊**

*¿Problemas? ¿Sugerencias? ¡Abre un issue en GitHub!*

</div>