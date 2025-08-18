#!/bin/bash

# Nitrox VPS Deployment Script - Standalone Version
# Automated installation of Nitrox multiplayer server on VPS
# Installs SteamCMD, downloads Subnautica, and configures Nitrox server

set -e  # Exit on any error

# Script version and info
SCRIPT_VERSION="2.0.0"
SCRIPT_NAME="Nitrox VPS Installer"

# Default configuration
DEFAULT_INSTALL_DIR="/opt/nitrox"
DEFAULT_SERVER_NAME="Nitrox VPS Server"
DEFAULT_MAX_PLAYERS=100
SUBNAUTICA_APP_ID=264710

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
STEAM_USERNAME=""
STEAM_PASSWORD=""
INSTALL_DIR="$DEFAULT_INSTALL_DIR"
SERVER_NAME="$DEFAULT_SERVER_NAME"
ADMIN_PASSWORD=""
SERVER_PASSWORD=""
MAX_PLAYERS="$DEFAULT_MAX_PLAYERS"
DETECTED_DISTRO=""
PACKAGE_MANAGER=""

# Logging functions
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

# Display usage information
show_usage() {
    cat << EOF
$SCRIPT_NAME v$SCRIPT_VERSION

Usage: $0 [OPTIONS]

Required Options:
  --steam-user <username>     Steam username for downloading Subnautica
  --steam-pass <password>     Steam password
  --admin-password <pass>     Administrator password for Nitrox server

Optional Options:
  --install-dir <path>        Installation directory (default: $DEFAULT_INSTALL_DIR)
  --server-name <name>        Server display name (default: "$DEFAULT_SERVER_NAME")
  --server-password <pass>    Server password (optional, public if not set)
  --max-players <number>      Maximum players (default: $DEFAULT_MAX_PLAYERS)
  --help                      Show this help message

Examples:
  $0 --steam-user myuser --steam-pass mypass --admin-password admin123
  $0 --steam-user myuser --steam-pass mypass --admin-password admin123 \\
     --server-name "My Awesome Server" --max-players 50

EOF
}

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --steam-user)
                STEAM_USERNAME="$2"
                shift 2
                ;;
            --steam-pass)
                STEAM_PASSWORD="$2"
                shift 2
                ;;
            --install-dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            --server-name)
                SERVER_NAME="$2"
                shift 2
                ;;
            --admin-password)
                ADMIN_PASSWORD="$2"
                shift 2
                ;;
            --server-password)
                SERVER_PASSWORD="$2"
                shift 2
                ;;
            --max-players)
                MAX_PLAYERS="$2"
                shift 2
                ;;
            --help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
}

# Validate required arguments
validate_arguments() {
    local errors=0
    
    if [[ -z "$STEAM_USERNAME" ]]; then
        log_error "Steam username is required (--steam-user)"
        errors=1
    fi
    
    if [[ -z "$STEAM_PASSWORD" ]]; then
        log_error "Steam password is required (--steam-pass)"
        errors=1
    fi
    
    if [[ -z "$ADMIN_PASSWORD" ]]; then
        log_error "Admin password is required (--admin-password)"
        errors=1
    fi
    
    if [[ ! "$MAX_PLAYERS" =~ ^[0-9]+$ ]] || [[ "$MAX_PLAYERS" -lt 1 ]] || [[ "$MAX_PLAYERS" -gt 100 ]]; then
        log_error "Max players must be a number between 1 and 100"
        errors=1
    fi
    
    if [[ $errors -eq 1 ]]; then
        echo
        show_usage
        exit 1
    fi
}

# Detect Linux distribution
detect_distribution() {
    log_info "Detecting Linux distribution..."
    
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        case "$ID" in
            ubuntu|debian)
                DETECTED_DISTRO="debian"
                PACKAGE_MANAGER="apt"
                ;;
            centos|rhel|fedora|rocky|almalinux)
                DETECTED_DISTRO="redhat"
                PACKAGE_MANAGER="yum"
                if command -v dnf &> /dev/null; then
                    PACKAGE_MANAGER="dnf"
                fi
                ;;
            *)
                log_warning "Unsupported distribution: $ID"
                DETECTED_DISTRO="generic"
                ;;
        esac
    else
        log_warning "Cannot detect distribution, using generic approach"
        DETECTED_DISTRO="generic"
    fi
    
    log_success "Detected distribution: $DETECTED_DISTRO (package manager: $PACKAGE_MANAGER)"
}

# Install system dependencies
install_system_dependencies() {
    log_info "Installing system dependencies..."
    
    case "$DETECTED_DISTRO" in
        debian)
            apt-get update -qq
            apt-get install -y curl wget ca-certificates software-properties-common
            dpkg --add-architecture i386
            apt-get update -qq
            apt-get install -y lib32gcc-s1 lib32stdc++6 libc6-i386
            ;;
        redhat)
            if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
                dnf install -y curl wget ca-certificates glibc.i686 libstdc++.i686 libgcc.i686
            else
                yum install -y curl wget ca-certificates glibc.i686 libstdc++.i686 libgcc.i686
            fi
            ;;
        *)
            log_warning "Generic distribution - install dependencies manually if needed"
            ;;
    esac
    
    log_success "System dependencies installed"
}

# Install .NET runtime
install_dotnet_runtime() {
    log_info "Installing .NET runtime..."
    
    if command -v dotnet &> /dev/null; then
        log_success ".NET runtime already installed"
        return 0
    fi
    
    case "$DETECTED_DISTRO" in
        debian)
            wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
            dpkg -i packages-microsoft-prod.deb
            rm packages-microsoft-prod.deb
            apt-get update -qq
            apt-get install -y dotnet-runtime-6.0
            ;;
        redhat)
            if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
                dnf install -y dotnet-runtime-6.0
            else
                yum install -y dotnet-runtime-6.0
            fi
            ;;
        *)
            log_warning "Please install .NET 6.0 runtime manually"
            ;;
    esac
    
    log_success ".NET runtime installed"
}

# Install SteamCMD
install_steamcmd() {
    log_info "Installing SteamCMD..."
    
    local steamcmd_dir="$INSTALL_DIR/steamcmd"
    mkdir -p "$steamcmd_dir"
    cd "$steamcmd_dir"
    
    wget -q https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
    tar -xzf steamcmd_linux.tar.gz
    rm steamcmd_linux.tar.gz
    chmod +x steamcmd.sh
    
    log_success "SteamCMD installed"
}

# Download Subnautica
download_subnautica() {
    log_info "Downloading Subnautica..."
    
    local steamcmd_dir="$INSTALL_DIR/steamcmd"
    local game_dir="$INSTALL_DIR/gamefiles"
    
    cd "$steamcmd_dir"
    
    cat > download_script.txt << EOF
@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
login $STEAM_USERNAME $STEAM_PASSWORD
force_install_dir $game_dir
app_update $SUBNAUTICA_APP_ID validate
quit
EOF
    
    ./steamcmd.sh +runscript download_script.txt
    rm download_script.txt
    
    # Verify download
    if [[ ! -f "$game_dir/Subnautica.exe" ]]; then
        log_error "Subnautica download failed"
        exit 1
    fi
    
    log_success "Subnautica downloaded successfully"
}

# Copy Nitrox server files
copy_nitrox_files() {
    log_info "Copying Nitrox server files..."
    
    if [[ ! -d "./Nitrox-Build/Server" ]]; then
        log_error "Nitrox server files not found. Please ensure Nitrox-Build/Server directory exists."
        exit 1
    fi
    
    cp -r ./Nitrox-Build/Server/* "$INSTALL_DIR/server/"
    chmod -R 755 "$INSTALL_DIR/server"
    
    log_success "Nitrox server files copied"
}

# Create server configuration
create_server_config() {
    log_info "Creating server configuration..."
    
    local config_dir="$INSTALL_DIR/server/UserData/Config"
    mkdir -p "$config_dir"
    
    cat > "$config_dir/server.cfg" << EOF
{
    "ServerName": "$SERVER_NAME",
    "ServerPort": 11000,
    "ServerPassword": "$SERVER_PASSWORD",
    "AdminPassword": "$ADMIN_PASSWORD",
    "GameMode": "Survival",
    "MaxPlayers": $MAX_PLAYERS,
    "SaveInterval": 300000,
    "DisableConsole": false,
    "EnableWhitelist": false
}
EOF
    
    # Create game path configuration
    echo "$INSTALL_DIR/gamefiles" > "$INSTALL_DIR/server/subnautica_path.txt"
    
    log_success "Server configuration created"
}

# Create startup script
create_startup_script() {
    log_info "Creating startup script..."
    
    cat > "$INSTALL_DIR/server/start-nitrox.sh" << EOF
#!/bin/bash
cd "$INSTALL_DIR/server"

# Set environment variables for VPS compatibility
export HOME="\${HOME:-$INSTALL_DIR/server/UserData}"
export XDG_CONFIG_HOME="\${XDG_CONFIG_HOME:-$INSTALL_DIR/server/UserData/.config}"
export SUBNAUTICA_INSTALLATION_PATH="$INSTALL_DIR/gamefiles"

# Create necessary directories
mkdir -p "\$HOME"
mkdir -p "\$XDG_CONFIG_HOME"
mkdir -p "UserData/Config"
mkdir -p "Saves"
mkdir -p "Logs"

echo "Starting Nitrox server..."
exec dotnet NitroxServer-Subnautica.dll
EOF
    
    chmod +x "$INSTALL_DIR/server/start-nitrox.sh"
    
    log_success "Startup script created"
}

# Create systemd service
create_systemd_service() {
    log_info "Creating systemd service..."
    
    cat > /etc/systemd/system/nitrox-server.service << EOF
[Unit]
Description=Nitrox Subnautica Multiplayer Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$INSTALL_DIR/server
ExecStart=$INSTALL_DIR/server/start-nitrox.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable nitrox-server
    
    log_success "Systemd service created and enabled"
}

# Configure firewall
configure_firewall() {
    log_info "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        ufw allow 11000/udp
        log_success "UFW firewall configured"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=11000/udp
        firewall-cmd --reload
        log_success "Firewalld configured"
    else
        log_warning "No supported firewall found. Please open port 11000/UDP manually"
    fi
}

# Create management scripts
create_management_scripts() {
    log_info "Creating management scripts..."
    
    # Start script
    cat > "$INSTALL_DIR/start-server.sh" << 'EOF'
#!/bin/bash
echo "Starting Nitrox server..."
sudo systemctl start nitrox-server
sudo systemctl status nitrox-server
EOF
    
    # Stop script
    cat > "$INSTALL_DIR/stop-server.sh" << 'EOF'
#!/bin/bash
echo "Stopping Nitrox server..."
sudo systemctl stop nitrox-server
EOF
    
    # Status script
    cat > "$INSTALL_DIR/status-server.sh" << 'EOF'
#!/bin/bash
echo "Nitrox server status:"
sudo systemctl status nitrox-server
echo
echo "Recent logs:"
sudo journalctl -u nitrox-server --no-pager -n 20
EOF
    
    chmod +x "$INSTALL_DIR"/*.sh
    
    log_success "Management scripts created"
}

# Check if running as root
check_root_privileges() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Create installation directory structure
create_directory_structure() {
    log_info "Creating directory structure..."
    
    mkdir -p "$INSTALL_DIR"/{steamcmd,gamefiles,server}
    mkdir -p "$INSTALL_DIR/server"/{UserData/Config,Saves,Logs}
    chmod -R 755 "$INSTALL_DIR"
    
    log_success "Directory structure created"
}

# Show installation summary
show_installation_summary() {
    echo
    echo -e "${GREEN}🎉 INSTALLATION COMPLETED SUCCESSFULLY!${NC}"
    echo "========================================"
    echo
    echo "Server Details:"
    echo "- Installation Directory: $INSTALL_DIR"
    echo "- Server Name: $SERVER_NAME"
    echo "- Max Players: $MAX_PLAYERS"
    echo "- Server Port: 11000 (UDP)"
    echo
    echo "Management Commands:"
    echo "- Start server:  $INSTALL_DIR/start-server.sh"
    echo "- Stop server:   $INSTALL_DIR/stop-server.sh"
    echo "- Server status: $INSTALL_DIR/status-server.sh"
    echo
    echo "Or use systemctl directly:"
    echo "- sudo systemctl start nitrox-server"
    echo "- sudo systemctl stop nitrox-server"
    echo "- sudo systemctl status nitrox-server"
    echo
    echo "Configuration files:"
    echo "- Server config: $INSTALL_DIR/server/UserData/Config/server.cfg"
    echo "- Game path: $INSTALL_DIR/server/subnautica_path.txt"
    echo
    echo "To connect to your server:"
    echo "- Server IP: $(curl -s ifconfig.me 2>/dev/null || echo 'YOUR_SERVER_IP')"
    echo "- Port: 11000"
    if [[ -n "$SERVER_PASSWORD" ]]; then
        echo "- Password: [CONFIGURED]"
    else
        echo "- Password: [PUBLIC SERVER]"
    fi
    echo
}

# Main installation function
main() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  $SCRIPT_NAME v$SCRIPT_VERSION${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
    
    # Parse and validate arguments
    parse_arguments "$@"
    validate_arguments
    
    # Display configuration
    log_info "Installation Configuration:"
    echo "  Steam Username: $STEAM_USERNAME"
    echo "  Install Directory: $INSTALL_DIR"
    echo "  Server Name: $SERVER_NAME"
    echo "  Max Players: $MAX_PLAYERS"
    echo "  Admin Password: [HIDDEN]"
    if [[ -n "$SERVER_PASSWORD" ]]; then
        echo "  Server Password: [HIDDEN]"
    else
        echo "  Server Password: [PUBLIC SERVER]"
    fi
    echo
    
    # Confirm installation
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled by user"
        exit 0
    fi
    
    # Start installation process
    log_info "Starting Nitrox VPS installation..."
    
    check_root_privileges
    detect_distribution
    create_directory_structure
    install_system_dependencies
    install_dotnet_runtime
    install_steamcmd
    download_subnautica
    copy_nitrox_files
    create_server_config
    create_startup_script
    create_systemd_service
    configure_firewall
    create_management_scripts
    
    show_installation_summary
    
    log_success "Installation completed! You can now start your server."
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi