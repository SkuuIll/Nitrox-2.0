#!/bin/bash

# Nitrox VPS Deployment Script
# Automated installation of Nitrox multiplayer server on VPS
# Installs SteamCMD, downloads Subnautica, and configures Nitrox server

set -e  # Exit on any error

# Script version and info
SCRIPT_VERSION="1.0.0"
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
                # Check if dnf is available (newer versions)
                if command -v dnf &> /dev/null; then
                    PACKAGE_MANAGER="dnf"
                fi
                ;;
            *)
                log_warning "Unsupported distribution: $ID"
                log_info "Attempting to use generic Linux approach..."
                DETECTED_DISTRO="generic"
                ;;
        esac
    else
        log_warning "Cannot detect distribution, using generic approach"
        DETECTED_DISTRO="generic"
    fi
    
    log_success "Detected distribution: $DETECTED_DISTRO (package manager: $PACKAGE_MANAGER)"
}

# Install system dependencies based on distribution
install_system_dependencies() {
    log_info "Installing system dependencies..."
    
    case "$DETECTED_DISTRO" in
        debian)
            install_debian_dependencies
            ;;
        redhat)
            install_redhat_dependencies
            ;;
        generic)
            log_warning "Generic distribution detected. You may need to install dependencies manually:"
            log_info "Required packages: curl, wget, lib32gcc1, lib32stdc++6, ca-certificates"
            ;;
    esac
}

# Install dependencies for Debian/Ubuntu
install_debian_dependencies() {
    log_info "Updating package lists..."
    apt-get update -qq
    
    log_info "Installing required packages..."
    apt-get install -y \
        curl \
        wget \
        ca-certificates \
        software-properties-common \
        apt-transport-https \
        gnupg \
        lsb-release
    
    # Add 32-bit architecture support (required for SteamCMD)
    log_info "Adding 32-bit architecture support..."
    dpkg --add-architecture i386
    apt-get update -qq
    
    # Install 32-bit libraries
    log_info "Installing 32-bit libraries for SteamCMD..."
    apt-get install -y \
        lib32gcc-s1 \
        lib32stdc++6 \
        libc6-i386
    
    log_success "Debian/Ubuntu dependencies installed successfully"
}

# Install dependencies for RedHat/CentOS/Fedora
install_redhat_dependencies() {
    log_info "Installing required packages..."
    
    if [[ "$PACKAGE_MANAGER" == "dnf" ]]; then
        dnf install -y \
            curl \
            wget \
            ca-certificates \
            glibc.i686 \
            libstdc++.i686 \
            libgcc.i686
    else
        yum install -y \
            curl \
            wget \
            ca-certificates \
            glibc.i686 \
            libstdc++.i686 \
            libgcc.i686
    fi
    
    log_success "RedHat/CentOS dependencies installed successfully"
}

# Check if running as root
check_root_privileges() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
    log_success "Running with root privileges"
}

# Create installation directory structure
create_directory_structure() {
    log_info "Creating directory structure at $INSTALL_DIR..."
    
    mkdir -p "$INSTALL_DIR"/{steamcmd,gamefiles,server,logs}
    mkdir -p "$INSTALL_DIR/server"/{UserData/Config,Saves,Logs}
    
    # Set proper permissions
    chmod 755 "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"/{steamcmd,gamefiles,server,logs}
    
    log_success "Directory structure created successfully"
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
    install_system_dependencies
    create_directory_structure
    
    # Load all modules
    source ./error-handling.sh
    source ./steamcmd-installer.sh
    source ./subnautica-downloader.sh
    source ./nitrox-patches.sh
    source ./game-detection.sh
    source ./server-config.sh
    source ./system-integration.sh
    
    # Setup error handling and logging
    setup_error_handling
    
    # Install and configure SteamCMD
    if ! install_and_configure_steamcmd; then
        handle_error $E_GENERAL "SteamCMD installation failed" "SteamCMD Installation" "Check network connectivity and dependencies"
        exit 1
    fi
    
    # Download and verify Subnautica
    if ! download_and_verify_subnautica "$STEAM_USERNAME" "$STEAM_PASSWORD"; then
        handle_error $E_GAME_FILES "Subnautica download failed" "Game Download" "Check Steam credentials and network connectivity"
        exit 1
    fi
    
    # Apply Nitrox VPS patches
    if ! apply_nitrox_vps_patches; then
        handle_error $E_CONFIG "Nitrox patches failed" "Server Patching" "Check .NET runtime and server files"
        exit 1
    fi
    
    # Detect and configure game installation
    if ! detect_and_configure_game_installation; then
        handle_error $E_GAME_FILES "Game detection failed" "Game Detection" "Verify Subnautica installation"
        exit 1
    fi
    
    # Configure Nitrox server
    if ! configure_nitrox_server; then
        handle_error $E_CONFIG "Server configuration failed" "Server Configuration" "Check configuration parameters"
        exit 1
    fi
    
    # Setup system integration
    if ! setup_system_integration; then
        handle_error $E_SERVER_START "System integration failed" "System Integration" "Check system permissions and services"
        exit 1
    fi
    
    # Load and run comprehensive tests
    source ./test-suite.sh
    log_info "Running post-installation tests..."
    if ! run_comprehensive_tests; then
        log_warning "Some tests failed, but installation completed. Check test logs for details."
    fi
    
    log_success "Nitrox VPS installation completed successfully!"
    log_info "Server is ready to start. Use the management scripts in $INSTALL_DIR"
    
    # Show final summary
    show_installation_summary
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi