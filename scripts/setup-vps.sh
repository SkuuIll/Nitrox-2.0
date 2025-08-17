#!/bin/bash
set -e

# Nitrox VPS Setup Script
# This script prepares a VPS for Nitrox server deployment

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    log_error "This script must be run as root (use sudo)"
    exit 1
fi

log_info "Starting VPS setup for Nitrox server..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    log_error "Cannot detect OS version"
    exit 1
fi

log_info "Detected OS: $OS $VER"

# Update system packages
log_info "Updating system packages..."
case $OS in
    "Ubuntu"*)
        apt-get update && apt-get upgrade -y
        ;;
    "Debian"*)
        apt-get update && apt-get upgrade -y
        ;;
    "CentOS"*|"Red Hat"*|"Rocky"*|"AlmaLinux"*)
        yum update -y || dnf update -y
        ;;
    *)
        log_warning "Unsupported OS: $OS. Proceeding anyway..."
        ;;
esac

# Install Docker
log_info "Installing Docker..."
if ! command -v docker &> /dev/null; then
    case $OS in
        "Ubuntu"*|"Debian"*)
            # Install Docker on Ubuntu/Debian
            apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        "CentOS"*|"Red Hat"*|"Rocky"*|"AlmaLinux"*)
            # Install Docker on CentOS/RHEL
            yum install -y yum-utils || dnf install -y dnf-utils
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo || dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        *)
            log_error "Unsupported OS for automatic Docker installation: $OS"
            log_info "Please install Docker manually: https://docs.docker.com/engine/install/"
            exit 1
            ;;
    esac
    
    # Start and enable Docker
    systemctl start docker
    systemctl enable docker
    
    log_success "Docker installed successfully"
else
    log_info "Docker is already installed"
fi

# Install Docker Compose (if not already installed)
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    log_info "Installing Docker Compose..."
    
    # Get latest version
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    
    # Download and install
    curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    log_success "Docker Compose installed successfully"
else
    log_info "Docker Compose is already available"
fi

# Configure firewall
log_info "Configuring firewall..."

# Default Nitrox port
NITROX_PORT=11000

if command -v ufw &> /dev/null; then
    # Ubuntu/Debian UFW
    log_info "Configuring UFW firewall..."
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow ${NITROX_PORT}/udp
    ufw reload
    log_success "UFW firewall configured"
    
elif command -v firewall-cmd &> /dev/null; then
    # CentOS/RHEL firewalld
    log_info "Configuring firewalld..."
    systemctl start firewalld
    systemctl enable firewalld
    firewall-cmd --permanent --add-service=ssh
    firewall-cmd --permanent --add-port=${NITROX_PORT}/udp
    firewall-cmd --reload
    log_success "Firewalld configured"
    
elif command -v iptables &> /dev/null; then
    # Fallback to iptables
    log_info "Configuring iptables..."
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    iptables -A INPUT -p udp --dport ${NITROX_PORT} -j ACCEPT
    iptables -A INPUT -j DROP
    
    # Save iptables rules
    case $OS in
        "Ubuntu"*|"Debian"*)
            iptables-save > /etc/iptables/rules.v4
            ;;
        "CentOS"*|"Red Hat"*|"Rocky"*|"AlmaLinux"*)
            iptables-save > /etc/sysconfig/iptables
            ;;
    esac
    
    log_success "Iptables configured"
else
    log_warning "No supported firewall found. Please configure firewall manually to allow UDP port $NITROX_PORT"
fi

# Create nitrox user
log_info "Creating nitrox user..."
if ! id "nitrox" &>/dev/null; then
    useradd -r -s /bin/false -d /opt/nitrox nitrox
    log_success "Nitrox user created"
else
    log_info "Nitrox user already exists"
fi

# Create data directories
log_info "Creating data directories..."
mkdir -p /opt/nitrox/{gamefiles,saves,config,logs,backups}
chown -R nitrox:nitrox /opt/nitrox
chmod -R 755 /opt/nitrox

# Add current user to docker group (if not root)
if [ -n "$SUDO_USER" ]; then
    log_info "Adding user $SUDO_USER to docker group..."
    usermod -aG docker $SUDO_USER
    log_info "User $SUDO_USER added to docker group (logout and login again to apply)"
fi

# Install useful tools
log_info "Installing useful tools..."
case $OS in
    "Ubuntu"*|"Debian"*)
        apt-get install -y curl wget htop nano vim git unzip
        ;;
    "CentOS"*|"Red Hat"*|"Rocky"*|"AlmaLinux"*)
        yum install -y curl wget htop nano vim git unzip || dnf install -y curl wget htop nano vim git unzip
        ;;
esac

# Configure system limits
log_info "Configuring system limits..."
cat >> /etc/security/limits.conf << EOF

# Nitrox server limits
nitrox soft nofile 65536
nitrox hard nofile 65536
nitrox soft nproc 32768
nitrox hard nproc 32768
EOF

# Configure sysctl for better network performance
log_info "Optimizing network settings..."
cat >> /etc/sysctl.conf << EOF

# Nitrox server network optimizations
net.core.rmem_default = 262144
net.core.rmem_max = 16777216
net.core.wmem_default = 262144
net.core.wmem_max = 16777216
net.core.netdev_max_backlog = 5000
net.ipv4.udp_mem = 102400 873800 16777216
net.ipv4.udp_rmem_min = 8192
net.ipv4.udp_wmem_min = 8192
EOF

sysctl -p

# Create systemd service for automatic startup (optional)
log_info "Creating systemd service..."
cat > /etc/systemd/system/nitrox-server.service << EOF
[Unit]
Description=Nitrox Multiplayer Server
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/bin/docker start nitrox-server
ExecStop=/usr/bin/docker stop nitrox-server
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable nitrox-server.service

# Create log rotation
log_info "Setting up log rotation..."
cat > /etc/logrotate.d/nitrox << EOF
/opt/nitrox/logs/*.log {
    daily
    rotate 7
    compress
    delaycompress
    missingok
    notifempty
    create 644 nitrox nitrox
}
EOF

# Download deployment script
log_info "Downloading deployment script..."
curl -fsSL -o /usr/local/bin/deploy-nitrox https://raw.githubusercontent.com/SubnauticaNitrox/Nitrox/master/scripts/deploy-vps.sh
chmod +x /usr/local/bin/deploy-nitrox

# Create helpful aliases
log_info "Creating helpful aliases..."
cat >> /root/.bashrc << EOF

# Nitrox server aliases
alias nitrox-logs='docker logs -f nitrox-server'
alias nitrox-status='docker ps --filter name=nitrox-server'
alias nitrox-stop='docker stop nitrox-server'
alias nitrox-start='docker start nitrox-server'
alias nitrox-restart='docker restart nitrox-server'
alias nitrox-update='docker pull nitrox/server:latest && docker stop nitrox-server && docker rm nitrox-server'
EOF

# Display summary
log_success "VPS setup completed successfully!"
echo ""
log_info "Setup Summary:"
echo "  ✓ Docker and Docker Compose installed"
echo "  ✓ Firewall configured (UDP port $NITROX_PORT allowed)"
echo "  ✓ Nitrox user and directories created"
echo "  ✓ System optimizations applied"
echo "  ✓ Systemd service created"
echo "  ✓ Log rotation configured"
echo ""
log_info "Next Steps:"
echo "  1. Deploy Nitrox server:"
echo "     deploy-nitrox --admin-password YOUR_PASSWORD --steam-user YOUR_STEAM_USER --steam-pass YOUR_STEAM_PASS"
echo ""
echo "  2. Or use Docker Compose:"
echo "     cd /opt/nitrox && wget https://raw.githubusercontent.com/SubnauticaNitrox/Nitrox/master/docker-compose.yml"
echo "     Edit docker-compose.yml with your settings"
echo "     docker-compose up -d"
echo ""
log_info "Useful Commands:"
echo "  nitrox-status  - Check server status"
echo "  nitrox-logs    - View server logs"
echo "  nitrox-restart - Restart server"
echo ""
log_warning "Important Security Notes:"
echo "  • Change default passwords immediately"
echo "  • Keep your system updated: apt update && apt upgrade (Ubuntu/Debian)"
echo "  • Monitor server logs regularly"
echo "  • Consider setting up automated backups"
echo ""
log_success "Your VPS is now ready for Nitrox server deployment!"