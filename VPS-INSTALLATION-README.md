# 🌊 Nitrox VPS Installation Guide

## Automated Installation for Linux VPS

This automated installer sets up a complete Nitrox multiplayer server on your VPS without Docker. It handles everything from Steam installation to server configuration.

## 🚀 Quick Start

### Prerequisites
- Linux VPS (Ubuntu 18+, Debian 9+, CentOS 7+, RHEL 7+)
- Root access (sudo)
- Steam account that owns Subnautica
- At least 4GB RAM and 20GB disk space

### One-Command Installation

```bash
# Download and run the installer
wget https://raw.githubusercontent.com/SkuuIll/NITROX2.0/master/install-vps.sh
chmod +x install-vps.sh

# Run installation
sudo ./install-vps.sh \
  --steam-user YOUR_STEAM_USERNAME \
  --steam-pass YOUR_STEAM_PASSWORD \
  --admin-password YOUR_ADMIN_PASSWORD \
  --server-name "My Awesome Nitrox Server"
```

## 📋 Installation Options

### Required Parameters
- `--steam-user`: Your Steam username
- `--steam-pass`: Your Steam password  
- `--admin-password`: Administrator password for the server

### Optional Parameters
- `--install-dir`: Installation directory (default: `/opt/nitrox`)
- `--server-name`: Server display name (default: "Nitrox VPS Server")
- `--server-password`: Server password (leave empty for public server)
- `--max-players`: Maximum players (default: 100, max: 100)

### Example Commands

```bash
# Basic installation
sudo ./install-vps.sh \
  --steam-user myuser \
  --steam-pass mypass \
  --admin-password admin123

# Advanced installation
sudo ./install-vps.sh \
  --steam-user myuser \
  --steam-pass mypass \
  --admin-password admin123 \
  --server-name "Epic Subnautica Server" \
  --server-password "secret123" \
  --max-players 50 \
  --install-dir /home/nitrox
```

## 🔧 What the Installer Does

1. **System Setup**
   - Detects Linux distribution
   - Installs required dependencies
   - Creates directory structure

2. **SteamCMD Installation**
   - Downloads and configures SteamCMD
   - Sets up headless Steam operation
   - Creates dedicated Steam user

3. **Subnautica Download**
   - Automatically downloads Subnautica via Steam
   - Verifies game files integrity
   - Handles download retries and errors

4. **Nitrox Server Setup**
   - Copies and configures Nitrox server files
   - Applies VPS compatibility patches
   - Installs .NET runtime if needed

5. **Configuration**
   - Creates server configuration files
   - Sets up game path detection
   - Configures firewall rules

6. **System Integration**
   - Creates systemd service
   - Sets up automatic startup
   - Creates management scripts
   - Configures log rotation

## 🎮 Server Management

### Starting the Server

```bash
# Using systemd (recommended)
sudo systemctl start nitrox-server

# Using management script
/opt/nitrox/start-server.sh
```

### Stopping the Server

```bash
# Using systemd
sudo systemctl stop nitrox-server

# Using management script
/opt/nitrox/stop-server.sh
```

### Checking Server Status

```bash
# Using systemd
sudo systemctl status nitrox-server

# Using management script
/opt/nitrox/status-server.sh

# Check logs
sudo journalctl -u nitrox-server -f
```

### Restarting the Server

```bash
# Using systemd
sudo systemctl restart nitrox-server

# Using management script
/opt/nitrox/restart-server.sh
```

## 📁 Directory Structure

```
/opt/nitrox/                    # Installation directory
├── steamcmd/                   # SteamCMD installation
├── gamefiles/                  # Subnautica game files
├── server/                     # Nitrox server
│   ├── UserData/              # Server configuration
│   ├── Saves/                 # World saves
│   ├── Logs/                  # Server logs
│   └── subnautica_path.txt    # Game path config
├── logs/                      # Installation logs
├── patches/                   # VPS compatibility patches
└── *.sh                      # Management scripts
```

## ⚙️ Configuration

### Server Configuration
Edit: `/opt/nitrox/server/UserData/Config/server.cfg`

```json
{
    "ServerName": "My Server",
    "ServerPort": 11000,
    "ServerPassword": "",
    "AdminPassword": "admin123",
    "GameMode": "Survival",
    "MaxPlayers": 100
}
```

### Game Path Configuration
Edit: `/opt/nitrox/server/subnautica_path.txt`

```
/opt/nitrox/gamefiles
```

## 🔥 Firewall Configuration

The installer automatically configures firewall rules, but you may need to manually open ports:

```bash
# UFW (Ubuntu/Debian)
sudo ufw allow 11000/udp

# Firewalld (CentOS/RHEL)
sudo firewall-cmd --permanent --add-port=11000/udp
sudo firewall-cmd --reload

# Iptables
sudo iptables -A INPUT -p udp --dport 11000 -j ACCEPT
```

## 🌐 Connecting to Your Server

### Server Information
- **IP Address**: Your VPS IP address
- **Port**: 11000 (UDP)
- **Server Name**: As configured during installation

### For Players
1. Download and install Nitrox launcher on their PC
2. Add server using your VPS IP address
3. Connect using server password (if set)

## 🆘 Troubleshooting

### Check Installation Logs
```bash
# Main installation log
tail -f /opt/nitrox/logs/installation.log

# Error log
tail -f /opt/nitrox/logs/errors.log

# Server logs
tail -f /opt/nitrox/server/Logs/*.log
```

### Common Issues

#### Steam Authentication Failed
- Verify Steam credentials
- Disable Steam Guard temporarily
- Check if account owns Subnautica

#### Server Won't Start
- Check .NET runtime: `dotnet --version`
- Verify game files: `/opt/nitrox/health-check.sh`
- Check port availability: `netstat -tulpn | grep 11000`

#### Game Files Not Found
- Check game path: `cat /opt/nitrox/server/subnautica_path.txt`
- Verify Subnautica installation: `ls -la /opt/nitrox/gamefiles/`
- Re-run game detection: `source /opt/nitrox/game-detection.sh && find_game_installation`

#### Permission Issues
- Check file ownership: `ls -la /opt/nitrox/`
- Fix permissions: `sudo chown -R nitrox:nitrox /opt/nitrox/`

### Getting Help

1. **Check Logs**: Always check the logs first
2. **Run Health Check**: `/opt/nitrox/health-check.sh`
3. **Verify Configuration**: Check all config files
4. **Restart Services**: `sudo systemctl restart nitrox-server`
5. **Clean Reinstall**: Remove `/opt/nitrox` and reinstall

## 🔄 Updating

### Update Nitrox Server
```bash
# Stop server
sudo systemctl stop nitrox-server

# Backup configuration
cp -r /opt/nitrox/server/UserData /opt/nitrox/backup-config

# Download new Nitrox files and replace
# (Manual process - copy new files to /opt/nitrox/server/)

# Start server
sudo systemctl start nitrox-server
```

### Update Subnautica
```bash
# Re-run Subnautica download
cd /opt/nitrox
source ./subnautica-downloader.sh
download_and_verify_subnautica "YOUR_STEAM_USER" "YOUR_STEAM_PASS"
```

## 📊 Monitoring

### Health Checks
The installer sets up automatic health monitoring:
- Process monitoring every 5 minutes
- Log cleanup every 6 hours
- Automatic restart on failure

### Manual Health Check
```bash
/opt/nitrox/health-check.sh
```

### Performance Monitoring
```bash
# CPU and memory usage
top -p $(pgrep -f "NitroxServer-Subnautica.dll")

# Network connections
netstat -tulpn | grep 11000

# Disk usage
du -sh /opt/nitrox/
```

## 🔐 Security

### Service User
The server runs as a dedicated `nitrox` user with limited privileges.

### Firewall
Only the required port (11000/UDP) is opened.

### File Permissions
All files have restrictive permissions and proper ownership.

### Recommendations
- Use strong passwords
- Keep system updated
- Monitor server logs
- Use fail2ban for additional protection

## 📞 Support

### Log Files to Share
When reporting issues, include:
- `/opt/nitrox/logs/installation.log`
- `/opt/nitrox/logs/errors.log`
- `/opt/nitrox/server/Logs/*.log`
- System info: `uname -a`

### Community Resources
- [Nitrox Discord](https://discord.gg/nitrox)
- [GitHub Issues](https://github.com/SkuuIll/NITROX2.0/issues)
- [Original Nitrox Project](https://github.com/SubnauticaNitrox/Nitrox)

---

**🌊 Happy diving with friends! 🌊**