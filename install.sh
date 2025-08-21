#!/bin/bash

# Nitrox Unified Installer Script
# Combines interactive setup and command-line functionality.

set -e  # Exit on any error

# Script version and info
SCRIPT_VERSION="2.2.0"
SCRIPT_NAME="Nitrox Unified Installer"

# Default configuration
DEFAULT_INSTALL_DIR="./server_data"
DEFAULT_SERVER_NAME="Nitrox VPS Server"
DEFAULT_MAX_PLAYERS=100
SUBNAUTICA_APP_ID=264710

# Color codes for output
RED='[0;31m'
GREEN='[0;32m'
YELLOW='[1;33m'
BLUE='[0;34m'
NC='[0m' # No Color

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

# === FUNCTION DEFINITIONS ===

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
If no options are provided, the script will run in interactive mode.

Required Options (for non-interactive mode):
  --steam-user <username>     Steam username for downloading Subnautica
  --steam-pass <password>     Steam password
  --admin-password <pass>     Administrator password for Nitrox server

Optional Options:
  --install-dir <path>        Installation directory (default: $DEFAULT_INSTALL_DIR)
  --server-name <name>        Server display name (default: "$DEFAULT_SERVER_NAME")
  --server-password <pass>    Server password (optional, public if not set)
  --max-players <number>      Maximum players (1-100, default: $DEFAULT_MAX_PLAYERS)
  --help                      Show this help message

Examples:
  $0  (runs interactive setup)
  $0 --steam-user myuser --steam-pass mypass --admin-password admin123

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

# Run interactive setup to gather info from the user
run_interactive_setup() {
    echo -e "${BLUE}--- Asistente de Instalación del Servidor Nitrox ---${NC}"
    echo "Este script te ayudará a configurar los parámetros para la instalación."
    echo

    read -p "Introduce tu nombre de usuario de Steam: " STEAM_USERNAME
    read -s -p "Introduce tu contraseña de Steam: " STEAM_PASSWORD
    echo
    read -p "Crea una contraseña de administrador para el servidor: " ADMIN_PASSWORD
    read -p "Introduce un nombre para tu servidor (deja en blanco para '$DEFAULT_SERVER_NAME'): " server_name_input
    SERVER_NAME=${server_name_input:-$DEFAULT_SERVER_NAME}
    read -p "Introduce una contraseña para el servidor (deja en blanco para un servidor público): " SERVER_PASSWORD
    read -p "Introduce el número máximo de jugadores (1-100, deja en blanco para $DEFAULT_MAX_PLAYERS): " max_players_input
    MAX_PLAYERS=${max_players_input:-$DEFAULT_MAX_PLAYERS}

    echo
    echo -e "${GREEN}--- Resumen de la Configuración ---${NC}"
    echo "Usuario de Steam: $STEAM_USERNAME"
    echo "Contraseña de Admin: $ADMIN_PASSWORD"
    echo "Nombre del Servidor: $SERVER_NAME"
    echo "Contraseña del Servidor: ${SERVER_PASSWORD:-"Ninguna (Público)"}"
    echo "Máximo de Jugadores: $MAX_PLAYERS"
    echo

    read -p "¿Es correcta esta información? (s/n): " confirm
    if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
        echo "Instalación cancelada."
        exit 0
    fi
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
            ubuntu|debian) DETECTED_DISTRO="debian"; PACKAGE_MANAGER="apt"; ;;
            centos|rhel|fedora|rocky|almalinux) 
                DETECTED_DISTRO="redhat"
                PACKAGE_MANAGER="yum"
                if command -v dnf &> /dev/null; then PACKAGE_MANAGER="dnf"; fi
                ;; 
            *) log_warning "Unsupported distribution: $ID"; DETECTED_DISTRO="generic"; ;;
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
            sudo apt-get update -qq
            sudo apt-get install -y curl wget ca-certificates software-properties-common
            sudo dpkg --add-architecture i386
            sudo apt-get update -qq
            sudo apt-get install -y lib32gcc-s1 lib32stdc++6 libc6-i386
            ;; 
        redhat)
            if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
                sudo dnf install -y curl wget ca-certificates glibc.i686 libstdc++.i686 libgcc.i686
            else
                sudo yum install -y curl wget ca-certificates glibc.i686 libstdc++.i686 libgcc.i686
            fi
            ;; 
        *) log_warning "Generic distribution - install dependencies manually if needed"; ;; 
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
            sudo dpkg -i packages-microsoft-prod.deb
            rm packages-microsoft-prod.deb
            sudo apt-get update -qq
            sudo apt-get install -y dotnet-runtime-6.0
            ;; 
        redhat)
            if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
                sudo dnf install -y dotnet-runtime-6.0
            else
                sudo yum install -y dotnet-runtime-6.0
            fi
            ;; 
        *) log_warning "Please install .NET 6.0 runtime manually"; ;; 
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
    cd - > /dev/null
    log_success "SteamCMD installed"
}

# Download Subnautica
download_subnautica() {
    log_info "Downloading Subnautica..."
    local steamcmd_path="$INSTALL_DIR/steamcmd/steamcmd.sh"
    local game_dir="$INSTALL_DIR/gamefiles"
    
    local download_script_path=$(mktemp)
    cat > "$download_script_path" << EOF
@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
login $STEAM_USERNAME $STEAM_PASSWORD
force_install_dir $game_dir
app_update $SUBNAUTICA_APP_ID validate
quit
EOF
    
    "$steamcmd_path" +runscript "$download_script_path"
    rm "$download_script_path"
    
    if [[ ! -f "$game_dir/Subnautica.exe" ]]; then
        log_error "Subnautica download failed. Check Steam credentials and ensure the account owns the game."
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
    mkdir -p "$INSTALL_DIR/server"
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
    echo "$INSTALL_DIR/gamefiles" > "$INSTALL_DIR/server/subnautica_path.txt"
    log_success "Server configuration created"
}

# Create startup script
create_startup_script() {
    log_info "Creating startup script..."
    cat > "$INSTALL_DIR/start.sh" << EOF
#!/bin/bash
cd "$INSTALL_DIR/server"

# Set environment variables for VPS compatibility
export HOME="$HOME:=$INSTALL_DIR/server/UserData"
export XDG_CONFIG_HOME="$XDG_CONFIG_HOME:=$INSTALL_DIR/server/UserData/.config"
export SUBNAUTICA_INSTALLATION_PATH="$INSTALL_DIR/gamefiles"

# Create necessary directories
mkdir -p "\$HOME"
mkdir -p "\$XDG_CONFIG_HOME"

echo "Starting Nitrox server..."
exec dotnet NitroxServer-Subnautica.dll
EOF
    chmod +x "$INSTALL_DIR/start.sh"
    log_success "Startup script created at $INSTALL_DIR/start.sh"
}

# Show installation summary
show_final_summary() {
    echo
    echo -e "${GREEN}--- ¡Instalación Completa! ---${NC}"
    echo "Puedes iniciar tu servidor ejecutando:"
    echo -e "${YELLOW}  $INSTALL_DIR/start.sh${NC}"
    echo
}

# Create installation directory structure
create_directory_structure() {
    log_info "Creating directory structure..."
    mkdir -p "$INSTALL_DIR"/{steamcmd,gamefiles,server}
    mkdir -p "$INSTALL_DIR/server"/{UserData/Config,Saves,Logs}
    chmod -R 755 "$INSTALL_DIR"
    log_success "Directory structure created"
}

# --- MAIN EXECUTION ---
main() {
    if [[ $# -gt 0 ]]; then
        parse_arguments "$@"
    else
        run_interactive_setup
    fi
    
    validate_arguments
    
    echo
    log_info "Starting installation process..."
    echo -e "${YELLOW}La instalación podría requerir privilegios de superusuario (sudo) para instalar paquetes.${NC}"
    
    detect_distribution
    install_system_dependencies
    install_dotnet_runtime
    
    create_directory_structure
    install_steamcmd
    download_subnautica
    copy_nitrox_files
    create_server_config
    create_startup_script
    
    show_final_summary
}

main "$@"
