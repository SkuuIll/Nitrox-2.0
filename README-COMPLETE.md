# 🌊 Nitrox 2.0 - Instalación Automatizada VPS

## 🎯 Solución Completa Sin Docker

Esta implementación resuelve completamente los problemas de deployment de Nitrox en VPS mediante una instalación **100% automatizada** que elimina la necesidad de Docker y configuración manual.

## ✨ Características Principales

### 🚀 **Instalación Completamente Automatizada**
- **Un solo comando** instala todo el sistema
- **Detección automática** de distribución Linux
- **Instalación automática** de todas las dependencias
- **Descarga automática** de Subnautica via Steam
- **Configuración automática** del servidor

### 🔧 **Compatibilidad VPS Total**
- **Fallbacks inteligentes** para variables de entorno faltantes
- **Detección automática** de rutas de juego
- **Configuración local** cuando fallan rutas del sistema
- **Sin dependencias de Docker** o GUI

### 🛡️ **Sistema Robusto de Errores**
- **Logging completo** con timestamps
- **Reintentos automáticos** con backoff exponencial
- **Guías de troubleshooting** específicas por error
- **Recuperación automática** de fallos

### ⚙️ **Gestión Profesional de Servicios**
- **Servicio systemd** automático
- **Scripts de gestión** (start/stop/restart/status)
- **Monitoreo de salud** automático
- **Rotación de logs** configurada

## 🚀 Instalación Ultra-Rápida

### Comando Único de Instalación

```bash
# Descargar e instalar en un comando
curl -fsSL https://raw.githubusercontent.com/SkuuIll/NITROX2.0/master/install-vps.sh | sudo bash -s -- \
  --steam-user TU_USUARIO_STEAM \
  --steam-pass TU_PASSWORD_STEAM \
  --admin-password TU_PASSWORD_ADMIN \
  --server-name "Mi Servidor Increíble"
```

### Instalación Manual (Recomendada)

```bash
# 1. Descargar instalador
wget https://raw.githubusercontent.com/SkuuIll/NITROX2.0/master/install-vps.sh
chmod +x install-vps.sh

# 2. Ejecutar instalación
sudo ./install-vps.sh \
  --steam-user TU_USUARIO_STEAM \
  --steam-pass TU_PASSWORD_STEAM \
  --admin-password PASSWORD_ADMIN_SEGURO \
  --server-name "Mi Servidor Épico" \
  --max-players 50
```

## 📋 Parámetros de Instalación

| Parámetro | Descripción | Requerido | Ejemplo |
|-----------|-------------|-----------|---------|
| `--steam-user` | Usuario de Steam | ✅ | `--steam-user miusuario` |
| `--steam-pass` | Contraseña de Steam | ✅ | `--steam-pass mipassword` |
| `--admin-password` | Password de administrador | ✅ | `--admin-password admin123` |
| `--server-name` | Nombre del servidor | ❌ | `--server-name "Mi Servidor"` |
| `--server-password` | Password del servidor | ❌ | `--server-password "secreto"` |
| `--max-players` | Jugadores máximos (1-100) | ❌ | `--max-players 50` |
| `--install-dir` | Directorio de instalación | ❌ | `--install-dir /home/nitrox` |

## 🎮 Gestión del Servidor

### Comandos Básicos

```bash
# Iniciar servidor
sudo systemctl start nitrox-server

# Detener servidor
sudo systemctl stop nitrox-server

# Reiniciar servidor
sudo systemctl restart nitrox-server

# Ver estado del servidor
sudo systemctl status nitrox-server

# Ver logs en tiempo real
sudo journalctl -u nitrox-server -f
```

### Scripts de Gestión Incluidos

```bash
# Scripts en /opt/nitrox/
./start-server.sh      # Iniciar servidor
./stop-server.sh       # Detener servidor
./restart-server.sh    # Reiniciar servidor
./status-server.sh     # Ver estado
./health-check.sh      # Verificar salud del servidor
```

## 📊 Monitoreo y Mantenimiento

### Health Checks Automáticos
- **Monitoreo cada 5 minutos** del proceso del servidor
- **Reinicio automático** en caso de fallo
- **Limpieza automática** de logs antiguos
- **Alertas** por uso excesivo de recursos

### Logs y Diagnóstico
```bash
# Ver logs de instalación
tail -f /opt/nitrox/logs/installation.log

# Ver logs del servidor
tail -f /opt/nitrox/server/Logs/*.log

# Ejecutar diagnóstico completo
/opt/nitrox/test-suite.sh

# Generar reporte de diagnóstico
/opt/nitrox/diagnostic-report.sh
```

## 🔧 Configuración

### Configuración del Servidor
**Archivo:** `/opt/nitrox/server/UserData/Config/server.cfg`

```json
{
    "ServerName": "Mi Servidor",
    "ServerPort": 11000,
    "ServerPassword": "",
    "AdminPassword": "admin123",
    "GameMode": "Survival",
    "MaxPlayers": 100
}
```

### Configuración de Ruta del Juego
**Archivo:** `/opt/nitrox/server/subnautica_path.txt`

```
/opt/nitrox/gamefiles
```

## 🌐 Conectarse al Servidor

### Información del Servidor
- **IP**: Tu IP pública del VPS
- **Puerto**: 11000 (UDP)
- **Nombre**: Como configuraste en la instalación

### Para Jugadores
1. Descargar Nitrox Launcher en PC
2. Agregar servidor con tu IP del VPS
3. Conectar usando password del servidor (si está configurado)

## 🆘 Troubleshooting Rápido

### Servidor no inicia
```bash
# Ver logs detallados
sudo journalctl -u nitrox-server --no-pager

# Verificar archivos
ls -la /opt/nitrox/server/

# Ejecutar tests
/opt/nitrox/test-suite.sh
```

### Jugadores no pueden conectar
```bash
# Verificar puerto abierto
netstat -tulpn | grep :11000

# Verificar firewall
sudo ufw status
sudo firewall-cmd --list-all

# Abrir puerto manualmente
sudo ufw allow 11000/udp
```

### Problemas de Steam
```bash
# Re-descargar Subnautica
cd /opt/nitrox
source ./subnautica-downloader.sh
download_and_verify_subnautica "USER" "PASS"
```

## 📁 Estructura de Archivos

```
/opt/nitrox/                    # Instalación principal
├── steamcmd/                   # SteamCMD para descargas
├── gamefiles/                  # Archivos de Subnautica
├── server/                     # Servidor Nitrox
│   ├── UserData/Config/        # Configuración
│   ├── Saves/                  # Mundos guardados
│   ├── Logs/                   # Logs del servidor
│   └── subnautica_path.txt     # Configuración de ruta
├── logs/                       # Logs de instalación
├── patches/                    # Parches VPS
├── tests/                      # Resultados de tests
└── *.sh                       # Scripts de gestión
```

## 🔄 Actualización

### Actualizar Servidor Nitrox
```bash
# Detener servidor
sudo systemctl stop nitrox-server

# Backup configuración
cp -r /opt/nitrox/server/UserData /opt/nitrox/backup-config

# Reemplazar archivos del servidor
# (copiar nuevos archivos Nitrox a /opt/nitrox/server/)

# Iniciar servidor
sudo systemctl start nitrox-server
```

### Actualizar Subnautica
```bash
# Re-ejecutar descarga
cd /opt/nitrox
source ./subnautica-downloader.sh
download_and_verify_subnautica "TU_USER" "TU_PASS"
```

## 📚 Documentación Completa

- **[Guía de Deployment](DEPLOYMENT-GUIDE.md)** - Instalación detallada y configuración avanzada
- **[Guía de Troubleshooting](TROUBLESHOOTING-GUIDE.md)** - Solución de problemas comunes
- **[Ejemplos de Configuración](CONFIGURATION-EXAMPLES.md)** - Configuraciones para diferentes escenarios
- **[README de Instalación VPS](VPS-INSTALLATION-README.md)** - Guía específica para VPS

## 🎯 Casos de Uso Soportados

### ✅ **Completamente Soportado**
- Ubuntu 18.04+ / Debian 9+
- CentOS 7+ / RHEL 7+ / Rocky Linux
- VPS con 4GB+ RAM y 20GB+ disco
- Instalación desde cero
- Configuración automática completa
- Gestión de servicios systemd
- Monitoreo y alertas automáticas

### ⚠️ **Parcialmente Soportado**
- Distribuciones Linux menos comunes
- VPS con menos de 4GB RAM (funciona pero con limitaciones)
- Instalación sobre sistemas existentes

### ❌ **No Soportado**
- Windows Server
- Sistemas sin acceso root/sudo
- Redes con restricciones extremas de firewall

## 🏆 Ventajas vs Solución Docker Original

| Característica | Docker Original | VPS Automatizado |
|----------------|-----------------|-------------------|
| **Instalación** | Manual compleja | Un solo comando |
| **Dependencias** | Docker requerido | Instalación automática |
| **Configuración** | Manual | Completamente automática |
| **Troubleshooting** | Complejo | Guías específicas |
| **Performance** | Overhead Docker | Nativo, más rápido |
| **Gestión** | Docker commands | Scripts dedicados |
| **Monitoreo** | Manual | Automático integrado |
| **Logs** | Dispersos | Centralizados |

## 🤝 Soporte y Comunidad

### 🐛 **Reportar Problemas**
1. Ejecutar diagnóstico: `/opt/nitrox/diagnostic-report.sh`
2. Crear issue en [GitHub](https://github.com/SkuuIll/NITROX2.0/issues)
3. Incluir logs y información del sistema

### 💬 **Comunidad**
- **Discord**: [Nitrox Community](https://discord.gg/nitrox)
- **GitHub**: [Proyecto Original](https://github.com/SubnauticaNitrox/Nitrox)
- **Wiki**: [Documentación](https://github.com/SkuuIll/NITROX2.0/wiki)

## 📄 Licencia y Créditos

### 🌟 **Proyecto Original**
Todo el mérito del mod multijugador va al **[Equipo Nitrox Original](https://github.com/SubnauticaNitrox/Nitrox)**

### 🚀 **Esta Implementación**
- **Instalación automatizada VPS** sin Docker
- **Sistema de gestión completo** con servicios
- **Troubleshooting avanzado** y monitoreo
- **Documentación completa** en español

### 📜 **Licencia**
GPL-3.0 - Ver [LICENSE.txt](LICENSE.txt) para detalles

---

<div align="center">

**🌊 ¡Sumérgete en la aventura multijugador sin complicaciones! 🌊**

*Instalación en 5 minutos • Gestión profesional • Soporte completo*

</div>