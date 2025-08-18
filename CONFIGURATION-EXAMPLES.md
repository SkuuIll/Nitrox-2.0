# ⚙️ Ejemplos de Configuración - Nitrox VPS

## 📋 Índice
1. [Configuraciones Básicas](#configuraciones-básicas)
2. [Configuraciones por Tipo de Servidor](#configuraciones-por-tipo-de-servidor)
3. [Configuraciones de Performance](#configuraciones-de-performance)
4. [Configuraciones de Seguridad](#configuraciones-de-seguridad)
5. [Configuraciones de Red](#configuraciones-de-red)
6. [Scripts de Automatización](#scripts-de-automatización)

## 🎯 Configuraciones Básicas

### Servidor Público Básico

**Archivo:** `/opt/nitrox/server/UserData/Config/server.cfg`

```json
{
    "ServerName": "Servidor Público Nitrox",
    "ServerPort": 11000,
    "ServerPassword": "",
    "AdminPassword": "admin123_CAMBIAR",
    "GameMode": "Survival",
    "MaxPlayers": 50,
    "SaveInterval": 300000,
    "DisableConsole": false,
    "EnableWhitelist": false,
    "GameInstallationPath": "/opt/nitrox/gamefiles",
    "ConfigurationPath": "/opt/nitrox/server/UserData/Config",
    "SavePath": "/opt/nitrox/server/Saves",
    "LogPath": "/opt/nitrox/server/Logs"
}
```

### Servidor Privado con Contraseña

```json
{
    "ServerName": "Mi Servidor Privado",
    "ServerPort": 11000,
    "ServerPassword": "mi_password_secreto",
    "AdminPassword": "admin_password_super_seguro",
    "GameMode": "Survival",
    "MaxPlayers": 20,
    "SaveInterval": 180000,
    "DisableConsole": false,
    "EnableWhitelist": true,
    "GameInstallationPath": "/opt/nitrox/gamefiles",
    "ConfigurationPath": "/opt/nitrox/server/UserData/Config",
    "SavePath": "/opt/nitrox/server/Saves",
    "LogPath": "/opt/nitrox/server/Logs"
}
```

### Servidor Creative

```json
{
    "ServerName": "Servidor Creative - Construcción Libre",
    "ServerPort": 11000,
    "ServerPassword": "",
    "AdminPassword": "creative_admin_2024",
    "GameMode": "Creative",
    "MaxPlayers": 100,
    "SaveInterval": 600000,
    "DisableConsole": false,
    "EnableWhitelist": false,
    "GameInstallationPath": "/opt/nitrox/gamefiles",
    "ConfigurationPath": "/opt/nitrox/server/UserData/Config",
    "SavePath": "/opt/nitrox/server/Saves",
    "LogPath": "/opt/nitrox/server/Logs"
}
```

## 🎮 Configuraciones por Tipo de Servidor

### Servidor de Alto Rendimiento (VPS Potente)

```json
{
    "ServerName": "Servidor High-Performance",
    "ServerPort": 11000,
    "ServerPassword": "",
    "AdminPassword": "hp_admin_2024",
    "GameMode": "Survival",
    "MaxPlayers": 100,
    "SaveInterval": 300000,
    "DisableConsole": false,
    "EnableWhitelist": false,
    "Advanced": {
        "AutoSave": true,
        "BackupInterval": 1800000,
        "MaxBackups": 20,
        "EnableMetrics": true,
        "LogLevel": "Info",
        "NetworkTimeout": 30000,
        "MaxConcurrentConnections": 100,
        "EnableCompression": true,
        "CompressionLevel": 6
    },
    "Performance": {
        "TickRate": 30,
        "MaxEntityUpdatesPerTick": 200,
        "EnableEntityCulling": true,
        "CullingDistance": 500.0,
        "EnableLOD": true
    },
    "Security": {
        "EnableRateLimiting": true,
        "MaxRequestsPerMinute": 120,
        "BanDuration": 1800,
        "EnableIPWhitelist": false,
        "AllowedIPs": []
    }
}
```

### Servidor de Recursos Limitados (VPS Básico)

```json
{
    "ServerName": "Servidor Económico",
    "ServerPort": 11000,
    "ServerPassword": "",
    "AdminPassword": "eco_admin_2024",
    "GameMode": "Survival",
    "MaxPlayers": 15,
    "SaveInterval": 600000,
    "DisableConsole": false,
    "EnableWhitelist": false,
    "Advanced": {
        "AutoSave": true,
        "BackupInterval": 3600000,
        "MaxBackups": 5,
        "EnableMetrics": false,
        "LogLevel": "Warning",
        "NetworkTimeout": 45000,
        "MaxConcurrentConnections": 20,
        "EnableCompression": true,
        "CompressionLevel": 9
    },
    "Performance": {
        "TickRate": 15,
        "MaxEntityUpdatesPerTick": 50,
        "EnableEntityCulling": true,
        "CullingDistance": 200.0,
        "EnableLOD": true
    },
    "Security": {
        "EnableRateLimiting": true,
        "MaxRequestsPerMinute": 30,
        "BanDuration": 3600,
        "EnableIPWhitelist": false,
        "AllowedIPs": []
    }
}
```

### Servidor PvP Competitivo

```json
{
    "ServerName": "Arena PvP Subnautica",
    "ServerPort": 11000,
    "ServerPassword": "pvp_password_2024",
    "AdminPassword": "pvp_admin_ultra_seguro",
    "GameMode": "Hardcore",
    "MaxPlayers": 30,
    "SaveInterval": 120000,
    "DisableConsole": true,
    "EnableWhitelist": true,
    "Advanced": {
        "AutoSave": true,
        "BackupInterval": 900000,
        "MaxBackups": 50,
        "EnableMetrics": true,
        "LogLevel": "Debug",
        "NetworkTimeout": 15000,
        "MaxConcurrentConnections": 35,
        "EnableCompression": true,
        "CompressionLevel": 4
    },
    "Performance": {
        "TickRate": 25,
        "MaxEntityUpdatesPerTick": 150,
        "EnableEntityCulling": true,
        "CullingDistance": 300.0,
        "EnableLOD": false
    },
    "Security": {
        "EnableRateLimiting": true,
        "MaxRequestsPerMinute": 60,
        "BanDuration": 7200,
        "EnableIPWhitelist": true,
        "AllowedIPs": [
            "192.168.1.0/24",
            "10.0.0.0/8"
        ]
    }
}
```

## ⚡ Configuraciones de Performance

### Configuración Ultra Performance

```json
{
    "Performance": {
        "TickRate": 60,
        "MaxEntityUpdatesPerTick": 300,
        "EnableEntityCulling": true,
        "CullingDistance": 1000.0,
        "EnableLOD": true,
        "OptimizationLevel": "Ultra",
        "EnableMultithreading": true,
        "ThreadPoolSize": 8,
        "EnableAsyncIO": true,
        "BufferSize": 65536,
        "EnableCaching": true,
        "CacheSize": 1024
    },
    "Advanced": {
        "EnableCompression": true,
        "CompressionLevel": 3,
        "EnableDeltaCompression": true,
        "NetworkTimeout": 10000,
        "KeepAliveInterval": 5000,
        "MaxPacketSize": 1400,
        "EnableBandwidthLimiting": false,
        "MaxBandwidthPerClient": 0
    }
}
```

### Configuración Balanced

```json
{
    "Performance": {
        "TickRate": 20,
        "MaxEntityUpdatesPerTick": 100,
        "EnableEntityCulling": true,
        "CullingDistance": 400.0,
        "EnableLOD": true,
        "OptimizationLevel": "Balanced",
        "EnableMultithreading": true,
        "ThreadPoolSize": 4,
        "EnableAsyncIO": true,
        "BufferSize": 32768,
        "EnableCaching": true,
        "CacheSize": 512
    },
    "Advanced": {
        "EnableCompression": true,
        "CompressionLevel": 6,
        "EnableDeltaCompression": true,
        "NetworkTimeout": 30000,
        "KeepAliveInterval": 15000,
        "MaxPacketSize": 1200,
        "EnableBandwidthLimiting": false,
        "MaxBandwidthPerClient": 0
    }
}
```

### Configuración Power Saving

```json
{
    "Performance": {
        "TickRate": 10,
        "MaxEntityUpdatesPerTick": 25,
        "EnableEntityCulling": true,
        "CullingDistance": 150.0,
        "EnableLOD": true,
        "OptimizationLevel": "PowerSaving",
        "EnableMultithreading": false,
        "ThreadPoolSize": 2,
        "EnableAsyncIO": false,
        "BufferSize": 8192,
        "EnableCaching": false,
        "CacheSize": 128
    },
    "Advanced": {
        "EnableCompression": true,
        "CompressionLevel": 9,
        "EnableDeltaCompression": true,
        "NetworkTimeout": 60000,
        "KeepAliveInterval": 30000,
        "MaxPacketSize": 800,
        "EnableBandwidthLimiting": true,
        "MaxBandwidthPerClient": 1024
    }
}
```

## 🔐 Configuraciones de Seguridad

### Seguridad Máxima

```json
{
    "Security": {
        "EnableRateLimiting": true,
        "MaxRequestsPerMinute": 30,
        "BanDuration": 14400,
        "EnableIPWhitelist": true,
        "AllowedIPs": [
            "192.168.1.100",
            "10.0.0.50",
            "203.0.113.0/24"
        ],
        "EnableGeoblocking": true,
        "AllowedCountries": ["US", "CA", "GB", "DE", "FR"],
        "EnableDDoSProtection": true,
        "MaxConnectionsPerIP": 2,
        "EnableCaptcha": true,
        "RequireAuthentication": true,
        "SessionTimeout": 3600,
        "EnableEncryption": true,
        "EncryptionLevel": "AES256"
    },
    "Logging": {
        "LogLevel": "Debug",
        "EnableSecurityLogs": true,
        "LogRetentionDays": 30,
        "EnableAuditTrail": true,
        "LogFailedAttempts": true,
        "AlertOnSuspiciousActivity": true
    }
}
```

### Seguridad Básica

```json
{
    "Security": {
        "EnableRateLimiting": true,
        "MaxRequestsPerMinute": 60,
        "BanDuration": 3600,
        "EnableIPWhitelist": false,
        "AllowedIPs": [],
        "EnableGeoblocking": false,
        "AllowedCountries": [],
        "EnableDDoSProtection": true,
        "MaxConnectionsPerIP": 5,
        "EnableCaptcha": false,
        "RequireAuthentication": false,
        "SessionTimeout": 7200,
        "EnableEncryption": false,
        "EncryptionLevel": "None"
    },
    "Logging": {
        "LogLevel": "Info",
        "EnableSecurityLogs": true,
        "LogRetentionDays": 7,
        "EnableAuditTrail": false,
        "LogFailedAttempts": true,
        "AlertOnSuspiciousActivity": false
    }
}
```

## 🌐 Configuraciones de Red

### Configuración para Múltiples Regiones

```json
{
    "Network": {
        "BindAddress": "0.0.0.0",
        "ServerPort": 11000,
        "EnableIPv6": true,
        "IPv6Address": "::",
        "EnableUPnP": false,
        "EnablePortForwarding": false,
        "RegionOptimization": {
            "EnableRegionDetection": true,
            "PreferredRegions": ["NA", "EU", "AS"],
            "RegionBasedRouting": true,
            "EnableCDN": false
        },
        "LoadBalancing": {
            "EnableLoadBalancing": false,
            "LoadBalancingMethod": "RoundRobin",
            "HealthCheckInterval": 30000,
            "MaxServerLoad": 80
        }
    }
}
```

### Configuración de Red Local

```json
{
    "Network": {
        "BindAddress": "192.168.1.100",
        "ServerPort": 11000,
        "EnableIPv6": false,
        "IPv6Address": "",
        "EnableUPnP": true,
        "EnablePortForwarding": true,
        "LocalNetworkOptimization": {
            "EnableLANMode": true,
            "LANDiscovery": true,
            "BroadcastInterval": 10000,
            "EnableZeroConf": true
        }
    }
}
```

## 🤖 Scripts de Automatización

### Script de Configuración Automática

```bash
#!/bin/bash
# /opt/nitrox/auto-configure.sh

SERVER_TYPE="$1"  # basic, performance, pvp, creative
PLAYER_COUNT="$2"
SERVER_NAME="$3"

case "$SERVER_TYPE" in
    "basic")
        MAX_PLAYERS="${PLAYER_COUNT:-25}"
        TICK_RATE=15
        COMPRESSION_LEVEL=6
        ;;
    "performance")
        MAX_PLAYERS="${PLAYER_COUNT:-100}"
        TICK_RATE=30
        COMPRESSION_LEVEL=3
        ;;
    "pvp")
        MAX_PLAYERS="${PLAYER_COUNT:-30}"
        TICK_RATE=25
        COMPRESSION_LEVEL=4
        ;;
    "creative")
        MAX_PLAYERS="${PLAYER_COUNT:-100}"
        TICK_RATE=20
        COMPRESSION_LEVEL=6
        ;;
    *)
        echo "Uso: $0 {basic|performance|pvp|creative} [player_count] [server_name]"
        exit 1
        ;;
esac

# Generar configuración
cat > /opt/nitrox/server/UserData/Config/server.cfg << EOF
{
    "ServerName": "${SERVER_NAME:-Servidor Nitrox Auto-Configurado}",
    "ServerPort": 11000,
    "ServerPassword": "",
    "AdminPassword": "$(openssl rand -base64 12)",
    "GameMode": "Survival",
    "MaxPlayers": $MAX_PLAYERS,
    "Performance": {
        "TickRate": $TICK_RATE,
        "EnableCompression": true,
        "CompressionLevel": $COMPRESSION_LEVEL
    }
}
EOF

echo "Configuración '$SERVER_TYPE' aplicada para $MAX_PLAYERS jugadores"
echo "Contraseña de admin generada automáticamente"
```

### Script de Optimización Dinámica

```bash
#!/bin/bash
# /opt/nitrox/dynamic-optimization.sh

# Obtener uso actual de recursos
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
MEMORY_USAGE=$(free | grep Mem | awk '{printf "%.0f", $3/$2 * 100.0}')
PLAYER_COUNT=$(netstat -an | grep :11000 | grep ESTABLISHED | wc -l)

CONFIG_FILE="/opt/nitrox/server/UserData/Config/server.cfg"

# Ajustar configuración basada en carga
if (( $(echo "$CPU_USAGE > 80" | bc -l) )); then
    # CPU alta - reducir tick rate
    sed -i 's/"TickRate": [0-9]*/"TickRate": 15/' "$CONFIG_FILE"
    echo "CPU alta detectada - reduciendo tick rate"
elif (( $(echo "$CPU_USAGE < 30" | bc -l) )); then
    # CPU baja - aumentar tick rate
    sed -i 's/"TickRate": [0-9]*/"TickRate": 25/' "$CONFIG_FILE"
    echo "CPU baja detectada - aumentando tick rate"
fi

if (( MEMORY_USAGE > 85 )); then
    # Memoria alta - habilitar culling agresivo
    sed -i 's/"CullingDistance": [0-9.]*/"CullingDistance": 200.0/' "$CONFIG_FILE"
    echo "Memoria alta detectada - habilitando culling agresivo"
fi

# Reiniciar servidor si es necesario
if (( $(echo "$CPU_USAGE > 90" | bc -l) )) || (( MEMORY_USAGE > 90 )); then
    echo "Recursos críticos - reiniciando servidor"
    systemctl restart nitrox-server
fi
```

### Script de Backup Automático

```bash
#!/bin/bash
# /opt/nitrox/auto-backup.sh

BACKUP_DIR="/backups/nitrox"
DATE=$(date +%Y%m%d_%H%M%S)
RETENTION_DAYS=7

mkdir -p "$BACKUP_DIR"

# Crear backup
echo "Creando backup: $DATE"
tar -czf "$BACKUP_DIR/nitrox_backup_$DATE.tar.gz" \
    /opt/nitrox/server/Saves/ \
    /opt/nitrox/server/UserData/Config/ \
    /opt/nitrox/server/subnautica_path.txt

# Limpiar backups antiguos
find "$BACKUP_DIR" -name "nitrox_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete

echo "Backup completado: nitrox_backup_$DATE.tar.gz"
```

### Crontab para Automatización

```bash
# /etc/crontab - Agregar estas líneas

# Backup automático cada 6 horas
0 */6 * * * root /opt/nitrox/auto-backup.sh

# Optimización dinámica cada 15 minutos
*/15 * * * * root /opt/nitrox/dynamic-optimization.sh

# Limpieza de logs diaria
0 2 * * * root find /opt/nitrox/server/Logs -name "*.log" -mtime +7 -delete

# Reinicio semanal (domingo 3 AM)
0 3 * * 0 root systemctl restart nitrox-server

# Health check cada 5 minutos
*/5 * * * * root /opt/nitrox/health-check.sh || systemctl restart nitrox-server
```

---

**💡 Consejos:**
- Siempre haz backup antes de cambiar configuraciones
- Testa las configuraciones en un entorno de prueba primero
- Monitorea el rendimiento después de cambios
- Ajusta gradualmente los valores de performance

**🔧 Personalización:**
- Copia cualquier ejemplo y modifícalo según tus necesidades
- Combina diferentes secciones de configuración
- Usa los scripts de automatización para facilitar la gestión