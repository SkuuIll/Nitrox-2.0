# 🔧 Guía de Troubleshooting - Nitrox VPS

## 📋 Índice de Problemas
1. [Problemas de Instalación](#problemas-de-instalación)
2. [Problemas de Steam/SteamCMD](#problemas-de-steamsteamcmd)
3. [Problemas del Servidor](#problemas-del-servidor)
4. [Problemas de Conectividad](#problemas-de-conectividad)
5. [Problemas de Performance](#problemas-de-performance)
6. [Problemas de Configuración](#problemas-de-configuración)
7. [Herramientas de Diagnóstico](#herramientas-de-diagnóstico)

## 🚨 Problemas de Instalación

### Error: "Could not determine where to save configs"

**Síntomas:**
```
[ERROR] Could not determine where to save configs
Exception: DirectoryNotFoundException
```

**Causa:** Variables de entorno HOME o XDG_CONFIG_HOME no disponibles en VPS.

**Solución:**
```bash
# 1. Verificar variables de entorno
echo $HOME
echo $XDG_CONFIG_HOME

# 2. Establecer variables manualmente
export HOME=/opt/nitrox/server/UserData
export XDG_CONFIG_HOME=/opt/nitrox/server/UserData/.config

# 3. Crear directorios necesarios
mkdir -p /opt/nitrox/server/UserData/.config

# 4. Reiniciar servidor
sudo systemctl restart nitrox-server
```

### Error: "Could not locate Subnautica installation directory"

**Síntomas:**
```
[ERROR] Could not locate Subnautica installation directory
Game files not found
```

**Solución:**
```bash
# 1. Verificar archivo de configuración de ruta
cat /opt/nitrox/server/subnautica_path.txt

# 2. Crear/corregir archivo de ruta
echo "/opt/nitrox/gamefiles" > /opt/nitrox/server/subnautica_path.txt

# 3. Verificar archivos del juego
ls -la /opt/nitrox/gamefiles/
ls -la /opt/nitrox/gamefiles/Subnautica_Data/

# 4. Re-descargar si es necesario
cd /opt/nitrox
source ./subnautica-downloader.sh
download_and_verify_subnautica "TU_USER" "TU_PASS"
```

### Error: Dependencias faltantes

**Síntomas:**
```
[ERROR] Package not found
[ERROR] Command not found
```

**Solución Ubuntu/Debian:**
```bash
# Actualizar repositorios
sudo apt update

# Instalar dependencias básicas
sudo apt install -y curl wget ca-certificates software-properties-common

# Instalar soporte 32-bit
sudo dpkg --add-architecture i386
sudo apt update
sudo apt install -y lib32gcc-s1 lib32stdc++6 libc6-i386

# Instalar .NET runtime
wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt update
sudo apt install -y dotnet-runtime-6.0
```

**Solución CentOS/RHEL:**
```bash
# Actualizar sistema
sudo yum update -y

# Instalar dependencias
sudo yum install -y curl wget ca-certificates

# Instalar librerías 32-bit
sudo yum install -y glibc.i686 libstdc++.i686 libgcc.i686

# Instalar .NET runtime
sudo yum install -y dotnet-runtime-6.0
```

## 🎮 Problemas de Steam/SteamCMD

### Error: Steam authentication failed

**Síntomas:**
```
[ERROR] Invalid Password
[ERROR] Invalid Login
Steam login failed
```

**Soluciones:**
```bash
# 1. Verificar credenciales
# - Asegúrate de que el usuario y contraseña sean correctos
# - Verifica que la cuenta posea Subnautica

# 2. Desactivar Steam Guard temporalmente
# - Ve a Steam > Configuración > Cuenta > Gestionar seguridad
# - Desactiva Steam Guard temporalmente

# 3. Usar contraseña de aplicación (si tienes 2FA)
# - Genera una contraseña específica para aplicaciones

# 4. Verificar estado de Steam
curl -s https://steamstat.us/ | grep -i "online"

# 5. Intentar login manual
cd /opt/nitrox/steamcmd
./steamcmd.sh +login TU_USUARIO TU_PASSWORD +quit
```

### Error: SteamCMD download failed

**Síntomas:**
```
[ERROR] Download failed
[ERROR] Network timeout
Connection refused
```

**Soluciones:**
```bash
# 1. Verificar conectividad
ping steamcdn-a.akamaihd.net
curl -I https://steamcdn-a.akamaihd.net

# 2. Verificar DNS
nslookup steamcdn-a.akamaihd.net
cat /etc/resolv.conf

# 3. Verificar proxy/firewall
echo $http_proxy
echo $https_proxy

# 4. Reintentar descarga con timeout mayor
cd /opt/nitrox/steamcmd
timeout 1800 ./steamcmd.sh +login TU_USER TU_PASS +force_install_dir /opt/nitrox/gamefiles +app_update 264710 validate +quit

# 5. Limpiar cache de SteamCMD
rm -rf /opt/nitrox/steamcmd/appcache/
rm -rf /opt/nitrox/steamcmd/logs/
```

### Error: Subnautica download incomplete

**Síntomas:**
```
[WARNING] Missing required files
[ERROR] Assembly-CSharp.dll not found
Download size smaller than expected
```

**Soluciones:**
```bash
# 1. Verificar espacio en disco
df -h /opt/nitrox/

# 2. Verificar archivos descargados
ls -la /opt/nitrox/gamefiles/
find /opt/nitrox/gamefiles -name "*.dll" | wc -l

# 3. Forzar re-descarga completa
rm -rf /opt/nitrox/gamefiles/*
cd /opt/nitrox/steamcmd
./steamcmd.sh +login TU_USER TU_PASS +force_install_dir /opt/nitrox/gamefiles +app_update 264710 validate +quit

# 4. Verificar integridad después de descarga
source /opt/nitrox/subnautica-downloader.sh
verify_subnautica_files "/opt/nitrox/gamefiles"
```

## 🖥️ Problemas del Servidor

### Error: Server won't start

**Síntomas:**
```
[ERROR] Server failed to start
Process exited with code 1
systemctl status shows failed
```

**Diagnóstico:**
```bash
# 1. Verificar logs detallados
sudo journalctl -u nitrox-server --no-pager -l

# 2. Verificar .NET runtime
dotnet --version
dotnet --list-runtimes

# 3. Verificar archivos del servidor
ls -la /opt/nitrox/server/
ls -la /opt/nitrox/server/NitroxServer-Subnautica.*

# 4. Verificar permisos
ls -la /opt/nitrox/server/UserData/
whoami
id nitrox
```

**Soluciones:**
```bash
# 1. Reinstalar .NET runtime
sudo apt remove dotnet-runtime-6.0
sudo apt install dotnet-runtime-6.0

# 2. Corregir permisos
sudo chown -R nitrox:nitrox /opt/nitrox/
sudo chmod -R 755 /opt/nitrox/

# 3. Recrear configuración
cd /opt/nitrox
source ./server-config.sh
configure_nitrox_server

# 4. Iniciar en modo debug
cd /opt/nitrox/server
sudo -u nitrox dotnet NitroxServer-Subnautica.dll --debug
```

### Error: Port already in use

**Síntomas:**
```
[ERROR] Port 11000 already in use
Address already in use
Bind failed
```

**Soluciones:**
```bash
# 1. Verificar qué proceso usa el puerto
sudo netstat -tulpn | grep :11000
sudo ss -tulpn | grep :11000

# 2. Matar proceso que usa el puerto
sudo kill -9 $(sudo lsof -t -i:11000)

# 3. Cambiar puerto del servidor
# Editar /opt/nitrox/server/UserData/Config/server.cfg
{
    "ServerPort": 11001
}

# 4. Actualizar firewall para nuevo puerto
sudo ufw allow 11001/udp
sudo firewall-cmd --permanent --add-port=11001/udp
sudo firewall-cmd --reload
```

### Error: High memory usage

**Síntomas:**
```
Server consuming too much RAM
Out of memory errors
System becomes unresponsive
```

**Soluciones:**
```bash
# 1. Monitorear uso de memoria
top -p $(pgrep -f "NitroxServer-Subnautica.dll")
ps aux | grep NitroxServer-Subnautica.dll

# 2. Configurar límites de memoria
# Editar /etc/systemd/system/nitrox-server.service
[Service]
MemoryLimit=2G
MemoryMax=4G

# 3. Optimizar configuración del servidor
# Editar server.cfg
{
    "MaxPlayers": 25,
    "Performance": {
        "TickRate": 15,
        "MaxEntityUpdatesPerTick": 50,
        "EnableEntityCulling": true,
        "CullingDistance": 200.0
    }
}

# 4. Reiniciar servicio
sudo systemctl daemon-reload
sudo systemctl restart nitrox-server
```

## 🌐 Problemas de Conectividad

### Error: Players can't connect

**Síntomas:**
```
Connection timeout
Server not responding
Can't find server
```

**Diagnóstico:**
```bash
# 1. Verificar que el servidor esté corriendo
sudo systemctl status nitrox-server
pgrep -f "NitroxServer-Subnautica.dll"

# 2. Verificar puerto abierto
netstat -tulpn | grep :11000
telnet localhost 11000

# 3. Verificar firewall
sudo ufw status
sudo firewall-cmd --list-all

# 4. Verificar IP pública
curl ifconfig.me
ip addr show
```

**Soluciones:**
```bash
# 1. Abrir puerto en firewall
sudo ufw allow 11000/udp
sudo firewall-cmd --permanent --add-port=11000/udp
sudo firewall-cmd --reload

# 2. Verificar configuración de red del VPS
# Algunos proveedores requieren configuración adicional

# 3. Test de conectividad externa
# Desde otra máquina:
telnet TU_IP_PUBLICA 11000
nmap -p 11000 -sU TU_IP_PUBLICA

# 4. Verificar configuración del servidor
cat /opt/nitrox/server/UserData/Config/server.cfg
```

### Error: Connection drops frequently

**Síntomas:**
```
Players get disconnected often
Unstable connections
Lag spikes
```

**Soluciones:**
```bash
# 1. Verificar recursos del sistema
htop
iotop
nethogs

# 2. Optimizar configuración de red
echo "net.core.rmem_max = 16777216" >> /etc/sysctl.conf
echo "net.core.wmem_max = 16777216" >> /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
sysctl -p

# 3. Ajustar configuración del servidor
{
    "Performance": {
        "NetworkTimeout": 45000,
        "TickRate": 20,
        "EnableCompression": true
    }
}

# 4. Monitorear conexiones
watch -n 1 'netstat -an | grep :11000 | grep ESTABLISHED | wc -l'
```

## ⚡ Problemas de Performance

### Error: Server lag/low TPS

**Síntomas:**
```
Slow server response
Low tick rate
Players experience lag
```

**Soluciones:**
```bash
# 1. Monitorear recursos
htop
iotop -o

# 2. Optimizar configuración
{
    "Performance": {
        "TickRate": 15,
        "MaxEntityUpdatesPerTick": 75,
        "EnableEntityCulling": true,
        "CullingDistance": 250.0,
        "EnableLOD": true
    },
    "MaxPlayers": 30
}

# 3. Optimizar sistema
echo "vm.swappiness = 10" >> /etc/sysctl.conf
echo "kernel.sched_migration_cost_ns = 5000000" >> /etc/sysctl.conf
sysctl -p

# 4. Limpiar logs y archivos temporales
find /opt/nitrox/server/Logs -name "*.log" -mtime +7 -delete
find /tmp -name "*nitrox*" -mtime +1 -delete
```

### Error: High CPU usage

**Síntomas:**
```
CPU usage constantly high
System becomes slow
Server becomes unresponsive
```

**Soluciones:**
```bash
# 1. Identificar procesos problemáticos
top -c
ps aux --sort=-%cpu | head -20

# 2. Limitar CPU del servidor
# Editar /etc/systemd/system/nitrox-server.service
[Service]
CPUQuota=200%
CPUWeight=100

# 3. Optimizar configuración
{
    "Performance": {
        "TickRate": 10,
        "MaxEntityUpdatesPerTick": 25,
        "EnableEntityCulling": true
    }
}

# 4. Verificar otros procesos
systemctl list-units --type=service --state=running
```

## ⚙️ Problemas de Configuración

### Error: Invalid configuration

**Síntomas:**
```
[ERROR] Configuration validation failed
JSON syntax error
Missing required fields
```

**Soluciones:**
```bash
# 1. Validar sintaxis JSON
python3 -m json.tool /opt/nitrox/server/UserData/Config/server.cfg
jq empty /opt/nitrox/server/UserData/Config/server.cfg

# 2. Restaurar configuración por defecto
cp /opt/nitrox/server/UserData/Config/server.cfg /opt/nitrox/server/UserData/Config/server.cfg.backup
cd /opt/nitrox
source ./server-config.sh
create_server_configuration

# 3. Verificar campos requeridos
grep -E '"ServerName"|"ServerPort"|"AdminPassword"|"GameMode"|"MaxPlayers"' /opt/nitrox/server/UserData/Config/server.cfg

# 4. Validar valores
# ServerPort: 1024-65535
# MaxPlayers: 1-100
# GameMode: "Survival", "Creative", "Hardcore"
```

### Error: Game path not found

**Síntomas:**
```
[ERROR] Game installation not found
Subnautica files missing
Invalid game path
```

**Soluciones:**
```bash
# 1. Verificar archivo de configuración
cat /opt/nitrox/server/subnautica_path.txt

# 2. Verificar archivos del juego
ls -la /opt/nitrox/gamefiles/Subnautica.exe
ls -la /opt/nitrox/gamefiles/Subnautica_Data/

# 3. Ejecutar detección automática
cd /opt/nitrox
source ./game-detection.sh
find_game_installation

# 4. Configurar manualmente
echo "/opt/nitrox/gamefiles" > /opt/nitrox/server/subnautica_path.txt
```

## 🔍 Herramientas de Diagnóstico

### Script de Diagnóstico Completo

```bash
#!/bin/bash
# /opt/nitrox/diagnostic-report.sh

echo "=== NITROX VPS DIAGNOSTIC REPORT ==="
echo "Generated: $(date)"
echo "Hostname: $(hostname)"
echo "User: $(whoami)"
echo

echo "=== SYSTEM INFO ==="
uname -a
cat /etc/os-release
echo

echo "=== RESOURCES ==="
free -h
df -h /opt/nitrox/
echo

echo "=== NETWORK ==="
ip addr show
netstat -tulpn | grep :11000
echo

echo "=== SERVICES ==="
systemctl status nitrox-server --no-pager
echo

echo "=== PROCESSES ==="
ps aux | grep -i nitrox
echo

echo "=== LOGS (last 20 lines) ==="
tail -20 /opt/nitrox/logs/installation.log
echo
tail -20 /opt/nitrox/server/Logs/*.log 2>/dev/null
echo

echo "=== CONFIGURATION ==="
cat /opt/nitrox/server/UserData/Config/server.cfg
echo
cat /opt/nitrox/server/subnautica_path.txt
echo

echo "=== FILE STRUCTURE ==="
ls -la /opt/nitrox/
ls -la /opt/nitrox/server/
ls -la /opt/nitrox/gamefiles/ 2>/dev/null | head -10
```

### Health Check Avanzado

```bash
#!/bin/bash
# /opt/nitrox/advanced-health-check.sh

ERRORS=0

# Verificar proceso
if ! pgrep -f "NitroxServer-Subnautica.dll" > /dev/null; then
    echo "ERROR: Server process not running"
    ERRORS=$((ERRORS + 1))
fi

# Verificar puerto
if ! netstat -tulpn | grep ":11000 " > /dev/null; then
    echo "ERROR: Port 11000 not listening"
    ERRORS=$((ERRORS + 1))
fi

# Verificar memoria
MEMORY_USAGE=$(ps -o pid,ppid,cmd,%mem --sort=-%mem | grep "NitroxServer-Subnautica.dll" | awk '{print $4}' | head -n1)
if [[ -n "$MEMORY_USAGE" ]] && (( $(echo "$MEMORY_USAGE > 80" | bc -l) )); then
    echo "WARNING: High memory usage: ${MEMORY_USAGE}%"
fi

# Verificar logs recientes
if [[ $(find /opt/nitrox/server/Logs -name "*.log" -mmin -5 | wc -l) -eq 0 ]]; then
    echo "WARNING: No recent log activity"
fi

# Verificar conectividad
if ! ping -c 1 8.8.8.8 &> /dev/null; then
    echo "ERROR: No internet connectivity"
    ERRORS=$((ERRORS + 1))
fi

if [[ $ERRORS -eq 0 ]]; then
    echo "OK: All checks passed"
    exit 0
else
    echo "CRITICAL: $ERRORS errors found"
    exit 2
fi
```

### Comandos de Emergencia

```bash
# Reinicio completo del servidor
sudo systemctl stop nitrox-server
sudo pkill -f "NitroxServer-Subnautica.dll"
sleep 5
sudo systemctl start nitrox-server

# Limpiar y reiniciar
sudo systemctl stop nitrox-server
rm -rf /opt/nitrox/server/Logs/*
rm -rf /opt/nitrox/logs/*
sudo systemctl start nitrox-server

# Restaurar desde backup
sudo systemctl stop nitrox-server
tar -xzf /backups/nitrox-backup-YYYYMMDD.tar.gz -C /
sudo systemctl start nitrox-server

# Reinstalación completa
sudo systemctl stop nitrox-server
sudo systemctl disable nitrox-server
rm -rf /opt/nitrox/
# Ejecutar install-vps.sh nuevamente
```

---

**💡 Tip:** Siempre revisa los logs primero antes de intentar soluciones más drásticas. La mayoría de problemas se pueden diagnosticar revisando `/opt/nitrox/logs/` y los logs del sistema.

**🆘 Si nada funciona:** Crea un issue en GitHub con el output del script de diagnóstico y los logs relevantes.