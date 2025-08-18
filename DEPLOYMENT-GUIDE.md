# 🚀 Guía Completa de Deployment - Nitrox VPS

## 📋 Índice
1. [Preparación del VPS](#preparación-del-vps)
2. [Instalación Automatizada](#instalación-automatizada)
3. [Configuración Avanzada](#configuración-avanzada)
4. [Gestión del Servidor](#gestión-del-servidor)
5. [Monitoreo y Mantenimiento](#monitoreo-y-mantenimiento)
6. [Troubleshooting](#troubleshooting)
7. [Optimización de Performance](#optimización-de-performance)

## 🖥️ Preparación del VPS

### Requisitos Mínimos del Sistema
- **OS**: Ubuntu 18.04+, Debian 9+, CentOS 7+, RHEL 7+
- **RAM**: 4GB mínimo, 8GB recomendado
- **Disco**: 20GB mínimo, 50GB recomendado
- **CPU**: 2 cores mínimo, 4 cores recomendado
- **Red**: Conexión estable a internet, puerto 11000/UDP abierto

### Preparación Inicial del VPS

```bash
# 1. Actualizar el sistema
sudo apt update && sudo apt upgrade -y  # Ubuntu/Debian
sudo yum update -y                      # CentOS/RHEL

# 2. Instalar herramientas básicas
sudo apt install -y curl wget git htop  # Ubuntu/Debian
sudo yum install -y curl wget git htop  # CentOS/RHEL

# 3. Configurar firewall básico
sudo ufw enable                         # Ubuntu/Debian
sudo firewall-cmd --state               # CentOS/RHEL

# 4. Crear usuario dedicado (opcional)
sudo adduser nitrox
sudo usermod -aG sudo nitrox
```

### Configuración de Red

```bash
# Verificar conectividad
ping -c 4 google.com
nslookup steamcdn-a.akamaihd.net

# Abrir puerto del servidor
sudo ufw allow 11000/udp               # Ubuntu/Debian
sudo firewall-cmd --permanent --add-port=11000/udp  # CentOS/RHEL
sudo firewall-cmd --reload             # CentOS/RHEL
```

## 🚀 Instalación Automatizada

### Descarga e Instalación

```bash
# 1. Descargar el instalador
wget https://raw.githubusercontent.com/SkuuIll/NITROX2.0/master/install-vps.sh
chmod +x install-vps.sh

# 2. Ejecutar instalación básica
sudo ./install-vps.sh \
  --steam-user TU_USUARIO_STEAM \
  --steam-pass TU_PASSWORD_STEAM \
  --admin-password PASSWORD_ADMIN_SEGURO

# 3. Instalación con opciones avanzadas
sudo ./install-vps.sh \
  --steam-user TU_USUARIO_STEAM \
  --steam-pass TU_PASSWORD_STEAM \
  --admin-password PASSWORD_ADMIN_SEGURO \
  --server-name "Mi Servidor Épico" \
  --server-password "password_servidor" \
  --max-players 50 \
  --install-dir /home/nitrox/server
```

### Parámetros de Instalación

| Parámetro | Descripción | Requerido | Valor por Defecto |
|-----------|-------------|-----------|-------------------|
| `--steam-user` | Usuario de Steam | ✅ | - |
| `--steam-pass` | Contraseña de Steam | ✅ | - |
| `--admin-password` | Contraseña de administrador | ✅ | - |
| `--server-name` | Nombre del servidor | ❌ | "Nitrox VPS Server" |
| `--server-password` | Contraseña del servidor | ❌ | "" (público) |
| `--max-players` | Jugadores máximos | ❌ | 100 |
| `--install-dir` | Directorio de instalación | ❌ | /opt/nitrox |

### Verificación de Instalación

```bash
# Verificar estado del servicio
sudo systemctl status nitrox-server

# Verificar archivos instalados
ls -la /opt/nitrox/

# Ejecutar tests de verificación
/opt/nitrox/test-suite.sh
```

## ⚙️ Configuración Avanzada

### Configuración del Servidor

Editar: `/opt/nitrox/server/UserData/Config/server.cfg`

```json
{
    "ServerName": "Mi Servidor Increíble",
    "ServerPort": 11000,
    "ServerPassword": "",
    "AdminPassword": "admin123",
    "GameMode": "Survival",
    "MaxPlayers": 100,
    "SaveInterval": 300000,
    "DisableConsole": false,
    "EnableWhitelist": false,
    "Advanced": {
        "AutoSave": true,
        "BackupInterval": 3600000,
        "MaxBackups": 10,
        "EnableMetrics": false,
        "LogLevel": "Info",
        "NetworkTimeout": 30000,
        "EnableCompression": true,
        "CompressionLevel": 6
    },
    "Security": {
        "EnableRateLimiting": true,
        "MaxRequestsPerMinute": 60,
        "BanDuration": 3600,
        "EnableIPWhitelist": false,
        "AllowedIPs": []
    },
    "Performance": {
        "TickRate": 20,
        "MaxEntityUpdatesPerTick": 100,
        "EnableEntityCulling": true,
        "CullingDistance": 500.0,
        "EnableLOD": true
    }
}
```

### Configuración de Rutas de Juego

Editar: `/opt/nitrox/server/subnautica_path.txt`

```
/opt/nitrox/gamefiles
```

### Variables de Entorno

Crear: `/opt/nitrox/server/.env`

```bash
# Configuración del servidor
NITROX_SERVER_NAME="Mi Servidor"
NITROX_SERVER_PORT=11000
NITROX_MAX_PLAYERS=100

# Configuración de rutas
HOME=/opt/nitrox/server/UserData
XDG_CONFIG_HOME=/opt/nitrox/server/UserData/.config
SUBNAUTICA_INSTALLATION_PATH=/opt/nitrox/gamefiles

# Configuración de logging
NITROX_LOG_LEVEL=Info
NITROX_DEBUG=false
```

## 🎮 Gestión del Servidor

### Comandos Básicos

```bash
# Iniciar servidor
sudo systemctl start nitrox-server
# o
/opt/nitrox/start-server.sh

# Detener servidor
sudo systemctl stop nitrox-server
# o
/opt/nitrox/stop-server.sh

# Reiniciar servidor
sudo systemctl restart nitrox-server
# o
/opt/nitrox/restart-server.sh

# Ver estado
sudo systemctl status nitrox-server
# o
/opt/nitrox/status-server.sh
```

### Gestión de Logs

```bash
# Ver logs en tiempo real
sudo journalctl -u nitrox-server -f

# Ver logs del servidor
tail -f /opt/nitrox/server/Logs/*.log

# Ver logs de instalación
tail -f /opt/nitrox/logs/installation.log

# Comprimir logs antiguos
find /opt/nitrox/logs -name "*.log" -mtime +7 -exec gzip {} \;
```

### Backup y Restauración

```bash
# Crear backup completo
tar -czf nitrox-backup-$(date +%Y%m%d).tar.gz /opt/nitrox/

# Backup solo de saves y configuración
tar -czf nitrox-data-backup-$(date +%Y%m%d).tar.gz \
  /opt/nitrox/server/Saves/ \
  /opt/nitrox/server/UserData/

# Restaurar backup
sudo systemctl stop nitrox-server
tar -xzf nitrox-backup-YYYYMMDD.tar.gz -C /
sudo systemctl start nitrox-server
```

## 📊 Monitoreo y Mantenimiento

### Health Checks Automáticos

```bash
# Ejecutar health check manual
/opt/nitrox/health-check.sh

# Ver configuración de monitoreo
cat /etc/cron.d/nitrox-server-monitor

# Ver logs de health checks
tail -f /opt/nitrox/logs/health-check.log
```

### Monitoreo de Recursos

```bash
# Uso de CPU y memoria del servidor
top -p $(pgrep -f "NitroxServer-Subnautica.dll")

# Uso de disco
df -h /opt/nitrox/
du -sh /opt/nitrox/*

# Conexiones de red
netstat -tulpn | grep 11000
ss -tulpn | grep 11000

# Procesos del servidor
ps aux | grep -i nitrox
```

### Alertas y Notificaciones

Crear script de alertas: `/opt/nitrox/alert-script.sh`

```bash
#!/bin/bash
# Script de alertas para Nitrox

WEBHOOK_URL="https://discord.com/api/webhooks/YOUR_WEBHOOK"
SERVER_NAME="Mi Servidor Nitrox"

send_alert() {
    local message="$1"
    local level="$2"
    
    curl -H "Content-Type: application/json" \
         -X POST \
         -d "{\"content\":\"[$level] $SERVER_NAME: $message\"}" \
         "$WEBHOOK_URL"
}

# Verificar si el servidor está corriendo
if ! pgrep -f "NitroxServer-Subnautica.dll" > /dev/null; then
    send_alert "Servidor caído - reiniciando automáticamente" "CRITICAL"
    systemctl restart nitrox-server
fi
```

## 🔧 Troubleshooting

### Problemas Comunes

#### 1. Servidor no inicia

```bash
# Verificar logs
sudo journalctl -u nitrox-server --no-pager

# Verificar configuración
/opt/nitrox/test-suite.sh

# Verificar .NET runtime
dotnet --version

# Verificar archivos del juego
ls -la /opt/nitrox/gamefiles/
```

#### 2. Problemas de conexión

```bash
# Verificar puerto
netstat -tulpn | grep 11000

# Verificar firewall
sudo ufw status
sudo firewall-cmd --list-all

# Test de conectividad
telnet YOUR_SERVER_IP 11000
```

#### 3. Problemas de Steam

```bash
# Re-descargar Subnautica
cd /opt/nitrox
source ./subnautica-downloader.sh
download_and_verify_subnautica "USER" "PASS"

# Verificar archivos de Steam
ls -la /opt/nitrox/steamcmd/
```

#### 4. Problemas de permisos

```bash
# Corregir permisos
sudo chown -R nitrox:nitrox /opt/nitrox/
sudo chmod -R 755 /opt/nitrox/

# Verificar usuario del servicio
sudo systemctl show nitrox-server | grep User
```

### Logs de Diagnóstico

```bash
# Generar reporte completo de diagnóstico
/opt/nitrox/generate-diagnostic-report.sh

# Ubicaciones de logs importantes
/opt/nitrox/logs/installation.log      # Log de instalación
/opt/nitrox/logs/errors.log           # Log de errores
/opt/nitrox/server/Logs/*.log         # Logs del servidor
/var/log/syslog                       # Logs del sistema
```

## 🚀 Optimización de Performance

### Configuración del Sistema

```bash
# Aumentar límites de archivos abiertos
echo "nitrox soft nofile 65536" >> /etc/security/limits.conf
echo "nitrox hard nofile 65536" >> /etc/security/limits.conf

# Optimizar red
echo "net.core.rmem_max = 16777216" >> /etc/sysctl.conf
echo "net.core.wmem_max = 16777216" >> /etc/sysctl.conf
sysctl -p
```

### Configuración del Servidor

```json
{
    "Performance": {
        "TickRate": 30,
        "MaxEntityUpdatesPerTick": 150,
        "EnableEntityCulling": true,
        "CullingDistance": 300.0,
        "EnableLOD": true,
        "MaxConcurrentConnections": 50,
        "NetworkTimeout": 15000,
        "EnableCompression": true,
        "CompressionLevel": 4
    }
}
```

### Monitoreo de Performance

```bash
# Script de monitoreo continuo
#!/bin/bash
while true; do
    echo "=== $(date) ==="
    echo "CPU: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)"
    echo "RAM: $(free | grep Mem | awk '{printf "%.2f%%", $3/$2 * 100.0}')"
    echo "Jugadores: $(netstat -an | grep :11000 | grep ESTABLISHED | wc -l)"
    echo "---"
    sleep 60
done
```

## 📚 Recursos Adicionales

### Comandos Útiles

```bash
# Ver jugadores conectados
netstat -an | grep :11000 | grep ESTABLISHED

# Reinicio automático en caso de fallo
echo "*/5 * * * * root /opt/nitrox/health-check.sh || systemctl restart nitrox-server" >> /etc/crontab

# Backup automático diario
echo "0 2 * * * root tar -czf /backups/nitrox-$(date +\%Y\%m\%d).tar.gz /opt/nitrox/server/Saves/" >> /etc/crontab
```

### Scripts de Utilidad

```bash
# Script de actualización
/opt/nitrox/update-server.sh

# Script de limpieza
/opt/nitrox/cleanup-logs.sh

# Script de estadísticas
/opt/nitrox/server-stats.sh
```

### Contacto y Soporte

- **Discord**: [Nitrox Community](https://discord.gg/nitrox)
- **GitHub**: [Issues](https://github.com/SkuuIll/NITROX2.0/issues)
- **Documentación**: [Wiki](https://github.com/SkuuIll/NITROX2.0/wiki)

---

**🌊 ¡Disfruta tu servidor Nitrox! 🌊**