# 🌊 Nitrox 2.0 - Servidor Multijugador Subnautica

[![Windows](https://img.shields.io/badge/Windows-10%2F11-blue?logo=windows)](https://www.microsoft.com/windows)
[![Docker](https://img.shields.io/badge/Docker-Ready-blue?logo=docker)](https://hub.docker.com/r/nitrox/server)
[![Kubernetes](https://img.shields.io/badge/Kubernetes-Supported-326CE5?logo=kubernetes)](./kubernetes/)
[![Subnautica](https://img.shields.io/badge/Subnautica-Compatible-green?logo=steam)](https://store.steampowered.com/app/264710/Subnautica/)
[![License](https://img.shields.io/badge/License-GPL--3.0-red)](LICENSE.txt)

**Nitrox 2.0** permite jugar Subnautica en multijugador con tus amigos. Explora, construye y sobrevive juntos en el mundo oceánico de Subnautica.

> **📢 Nota**: Esta es una versión mejorada basada en el [proyecto original de Nitrox](https://github.com/SubnauticaNitrox/Nitrox) que añade un instalador fácil para Windows y un sistema completo de despliegue Docker/VPS. Todo el mérito del mod multijugador va al equipo original de Nitrox.

## 🎯 Dos Formas de Usar Nitrox

### 🖥️ **Para Usuarios Normales (Windows)**
Instalador súper fácil con interfaz gráfica - ¡Solo hacer clic!

### 🐳 **Para Servidores/VPS (Docker)**
Despliegue profesional en servidores Linux con Docker y Kubernetes

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

## 🐳 Despliegue Docker/VPS (Avanzado)

### Opción 1: Despliegue Automático en VPS

```bash
# 1. Configurar VPS (Ubuntu/Debian/CentOS)
curl -fsSL https://raw.githubusercontent.com/SkuuIll/NITROX2.0/master/scripts/setup-vps.sh | sudo bash

# 2. Desplegar servidor Nitrox
./scripts/deploy-vps.sh \
  --admin-password "tu_password_admin" \
  --steam-user "tu_usuario_steam" \
  --steam-pass "tu_password_steam" \
  --server-name "Mi Servidor Nitrox"
```

### Opción 2: Docker Compose Local

```bash
# Clonar repositorio
git clone https://github.com/SkuuIll/NITROX2.0.git
cd NITROX2.0

# Configurar variables de entorno
cp docker-compose.yml docker-compose.local.yml
# Editar docker-compose.local.yml con tus credenciales

# Iniciar servidor
docker-compose -f docker-compose.local.yml up -d
```

### Opción 3: Kubernetes

```bash
# Aplicar manifiestos
kubectl apply -f kubernetes/

# Configurar secretos
kubectl create secret generic steam-credentials \
  --from-literal=username=tu_usuario_steam \
  --from-literal=password=tu_password_steam

kubectl create secret generic nitrox-secrets \
  --from-literal=admin-password=tu_password_admin
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

### 🐳 Configuración Docker (Variables de Entorno)

| Variable | Descripción | Valor por Defecto |
|----------|-------------|-------------------|
| `NITROX_SERVER_NAME` | Nombre del servidor | `"Nitrox Docker Server"` |
| `NITROX_SERVER_PORT` | Puerto UDP del servidor | `11000` |
| `NITROX_ADMIN_PASSWORD` | Password de administrador | **Requerido** |
| `NITROX_SERVER_PASSWORD` | Password del servidor (opcional) | `""` |
| `NITROX_GAME_MODE` | Modo de juego | `"Survival"` |
| `NITROX_MAX_PLAYERS` | Máximo de jugadores | `100` |
| `STEAM_USERNAME` | Usuario de Steam | **Requerido** |
| `STEAM_PASSWORD` | Password de Steam | **Requerido** |

### Ejemplo Docker Compose

```yaml
version: '3.8'
services:
  nitrox-server:
    image: nitrox/server:latest
    ports:
      - "11000:11000/udp"
    environment:
      - NITROX_SERVER_NAME=Mi Servidor Increíble
      - NITROX_ADMIN_PASSWORD=password_super_seguro
      - STEAM_USERNAME=mi_usuario_steam
      - STEAM_PASSWORD=mi_password_steam
      - NITROX_GAME_MODE=Survival
      - NITROX_MAX_PLAYERS=50
    volumes:
      - nitrox_gamefiles:/app/gamefiles
      - nitrox_saves:/app/saves
      - nitrox_config:/app/config
    restart: unless-stopped

volumes:
  nitrox_gamefiles:
  nitrox_saves:
  nitrox_config:
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

### Para Docker/VPS
```bash
# Construir imagen Docker
make build

# Desplegar localmente
make deploy-local

# Ver logs del servidor
make logs
# o
docker logs -f nitrox-server

# Verificar estado
make status
# o
docker ps --filter "name=nitrox-server"

# Actualizar servidor
make update
# o
docker pull nitrox/server:latest && docker-compose up -d

# Crear backup
make backup

# Limpiar recursos Docker
make clean
```

---

<div align="center">

**🌊 ¡Sumérgete en la aventura multijugador! 🌊**

*¿Problemas? ¿Sugerencias? ¡Abre un issue en GitHub!*

</div>