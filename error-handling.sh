#!/bin/bash

# Comprehensive Error Handling and Logging System
# Part of Nitrox VPS Deployment System

# Logging configuration
LOG_DIR="$INSTALL_DIR/logs"
MAIN_LOG_FILE="$LOG_DIR/installation.log"
ERROR_LOG_FILE="$LOG_DIR/errors.log"
DEBUG_LOG_FILE="$LOG_DIR/debug.log"
TROUBLESHOOTING_LOG="$LOG_DIR/troubleshooting.log"

# Error codes
readonly E_SUCCESS=0
readonly E_GENERAL=1
readonly E_MISSING_DEPS=2
readonly E_NETWORK=3
readonly E_PERMISSION=4
readonly E_CONFIG=5
readonly E_STEAM_AUTH=6
readonly E_GAME_FILES=7
readonly E_SERVER_START=8

# Initialize logging system
init_logging() {
    # Create log directory
    mkdir -p "$LOG_DIR"
    
    # Initialize log files
    echo "=== Nitrox VPS Installation Log - $(date) ===" > "$MAIN_LOG_FILE"
    echo "=== Error Log - $(date) ===" > "$ERROR_LOG_FILE"
    echo "=== Debug Log - $(date) ===" > "$DEBUG_LOG_FILE"
    echo "=== Troubleshooting Guide - $(date) ===" > "$TROUBLESHOOTING_LOG"
    
    # Set proper permissions
    chmod 644 "$LOG_DIR"/*.log
    
    log_info "Logging system initialized"
}

# Enhanced logging functions with file output
log_info() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${BLUE}[INFO]${NC} $message"
    echo "[$timestamp] [INFO] $message" >> "$MAIN_LOG_FILE"
}

log_success() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${GREEN}[SUCCESS]${NC} $message"
    echo "[$timestamp] [SUCCESS] $message" >> "$MAIN_LOG_FILE"
}

log_warning() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${YELLOW}[WARNING]${NC} $message"
    echo "[$timestamp] [WARNING] $message" >> "$MAIN_LOG_FILE"
    echo "[$timestamp] [WARNING] $message" >> "$ERROR_LOG_FILE"
}

log_error() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${RED}[ERROR]${NC} $message"
    echo "[$timestamp] [ERROR] $message" >> "$MAIN_LOG_FILE"
    echo "[$timestamp] [ERROR] $message" >> "$ERROR_LOG_FILE"
}

log_debug() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ "${DEBUG:-false}" == "true" ]]; then
        echo -e "${BLUE}[DEBUG]${NC} $message"
    fi
    echo "[$timestamp] [DEBUG] $message" >> "$DEBUG_LOG_FILE"
}

# Error handling with context
handle_error() {
    local error_code="$1"
    local error_message="$2"
    local context="${3:-Unknown}"
    local suggestion="${4:-Contact support}"
    
    log_error "Error in $context: $error_message"
    log_error "Error Code: $error_code"
    log_error "Suggestion: $suggestion"
    
    # Add to troubleshooting log
    cat >> "$TROUBLESHOOTING_LOG" << EOF

ERROR: $error_message
Context: $context
Error Code: $error_code
Timestamp: $(date)
Suggestion: $suggestion

EOF
    
    # Show specific troubleshooting based on error code
    show_error_troubleshooting "$error_code" "$context"
    
    return "$error_code"
}

# Show specific troubleshooting information
show_error_troubleshooting() {
    local error_code="$1"
    local context="$2"
    
    case "$error_code" in
        $E_MISSING_DEPS)
            show_dependency_troubleshooting
            ;;
        $E_NETWORK)
            show_network_troubleshooting
            ;;
        $E_PERMISSION)
            show_permission_troubleshooting
            ;;
        $E_STEAM_AUTH)
            show_steam_auth_troubleshooting
            ;;
        $E_GAME_FILES)
            show_game_files_troubleshooting
            ;;
        $E_SERVER_START)
            show_server_start_troubleshooting
            ;;
        *)
            show_general_troubleshooting
            ;;
    esac
}

# Dependency troubleshooting
show_dependency_troubleshooting() {
    cat << EOF

🔧 DEPENDENCY TROUBLESHOOTING:
================================
This error indicates missing system dependencies.

Common solutions:
1. Update package lists:
   - Ubuntu/Debian: sudo apt update
   - CentOS/RHEL: sudo yum update

2. Install missing packages manually:
   - Ubuntu/Debian: sudo apt install curl wget lib32gcc-s1 lib32stdc++6
   - CentOS/RHEL: sudo yum install curl wget glibc.i686 libstdc++.i686

3. Enable additional repositories:
   - Ubuntu: sudo apt install software-properties-common
   - CentOS: sudo yum install epel-release

4. Check internet connectivity:
   - ping google.com

EOF
}

# Network troubleshooting
show_network_troubleshooting() {
    cat << EOF

🌐 NETWORK TROUBLESHOOTING:
===========================
This error indicates network connectivity issues.

Common solutions:
1. Check internet connection:
   - ping 8.8.8.8
   - curl -I https://google.com

2. Check DNS resolution:
   - nslookup steamcdn-a.akamaihd.net
   - cat /etc/resolv.conf

3. Check firewall settings:
   - sudo ufw status (Ubuntu)
   - sudo firewall-cmd --list-all (CentOS)

4. Check proxy settings:
   - echo \$http_proxy
   - echo \$https_proxy

5. Retry with different mirror:
   - Try again in a few minutes
   - Check Steam status: https://steamstat.us/

EOF
}

# Permission troubleshooting
show_permission_troubleshooting() {
    cat << EOF

🔐 PERMISSION TROUBLESHOOTING:
==============================
This error indicates file/directory permission issues.

Common solutions:
1. Check if running as root:
   - whoami
   - sudo ./install-vps.sh (if not root)

2. Check directory permissions:
   - ls -la $INSTALL_DIR
   - sudo chown -R \$(whoami):\$(whoami) $INSTALL_DIR

3. Check disk space:
   - df -h
   - du -sh $INSTALL_DIR

4. Check SELinux (CentOS/RHEL):
   - getenforce
   - sudo setenforce 0 (temporary)

EOF
}

# Steam authentication troubleshooting
show_steam_auth_troubleshooting() {
    cat << EOF

🎮 STEAM AUTHENTICATION TROUBLESHOOTING:
========================================
This error indicates Steam login issues.

Common solutions:
1. Verify Steam credentials:
   - Check username and password
   - Try logging in via Steam website

2. Check for Steam Guard:
   - Disable Steam Guard temporarily
   - Use app-specific password if available

3. Account limitations:
   - Ensure account owns Subnautica
   - Check if account is limited/restricted

4. Network issues:
   - Check if Steam servers are accessible
   - Try different network/VPN

5. Rate limiting:
   - Wait 15-30 minutes between attempts
   - Steam may temporarily block rapid login attempts

EOF
}

# Game files troubleshooting
show_game_files_troubleshooting() {
    cat << EOF

🎯 GAME FILES TROUBLESHOOTING:
==============================
This error indicates issues with Subnautica game files.

Common solutions:
1. Verify download completion:
   - Check available disk space: df -h
   - Look for partial downloads in $GAME_INSTALL_DIR

2. Check file permissions:
   - ls -la $GAME_INSTALL_DIR
   - sudo chmod -R 755 $GAME_INSTALL_DIR

3. Validate game files:
   - Re-run SteamCMD with validate option
   - Delete and re-download if corrupted

4. Check required files:
   - Subnautica.exe
   - Subnautica_Data/Managed/Assembly-CSharp.dll
   - Subnautica_Data/StreamingAssets

5. Manual configuration:
   - Create subnautica_path.txt with correct path
   - Ensure path points to valid Subnautica installation

EOF
}

# Server start troubleshooting
show_server_start_troubleshooting() {
    cat << EOF

🚀 SERVER START TROUBLESHOOTING:
================================
This error indicates Nitrox server startup issues.

Common solutions:
1. Check .NET runtime:
   - dotnet --version
   - Install .NET 6.0 if missing

2. Check server files:
   - ls -la $NITROX_SERVER_DIR
   - Verify NitroxServer-Subnautica.dll exists

3. Check configuration:
   - Validate server.cfg syntax
   - Check game path configuration

4. Check ports:
   - netstat -tulpn | grep 11000
   - Ensure port 11000 is not in use

5. Check logs:
   - tail -f $INSTALL_DIR/server/Logs/*.log
   - Look for specific error messages

EOF
}

# General troubleshooting
show_general_troubleshooting() {
    cat << EOF

❓ GENERAL TROUBLESHOOTING:
==========================
General troubleshooting steps for unknown issues.

Common solutions:
1. Check system resources:
   - free -h (memory)
   - df -h (disk space)
   - top (CPU usage)

2. Check system logs:
   - journalctl -xe
   - dmesg | tail

3. Restart and retry:
   - Reboot the system
   - Re-run the installation script

4. Clean installation:
   - Remove $INSTALL_DIR
   - Start fresh installation

5. Get help:
   - Check logs in $LOG_DIR
   - Report issue with log files
   - Visit project documentation

EOF
}

# Retry mechanism with exponential backoff
retry_with_backoff() {
    local max_attempts="$1"
    local delay="$2"
    local command="$3"
    shift 3
    
    local attempt=1
    local current_delay="$delay"
    
    while [[ $attempt -le $max_attempts ]]; do
        log_info "Attempt $attempt of $max_attempts: $command"
        
        if eval "$command" "$@"; then
            log_success "Command succeeded on attempt $attempt"
            return 0
        else
            local exit_code=$?
            log_warning "Attempt $attempt failed (exit code: $exit_code)"
            
            if [[ $attempt -lt $max_attempts ]]; then
                log_info "Waiting ${current_delay}s before retry..."
                sleep "$current_delay"
                current_delay=$((current_delay * 2))  # Exponential backoff
            fi
        fi
        
        attempt=$((attempt + 1))
    done
    
    log_error "All $max_attempts attempts failed"
    return 1
}

# Network operation with retry
network_retry() {
    local url="$1"
    local output_file="$2"
    local max_attempts="${3:-3}"
    
    log_info "Downloading: $url"
    
    retry_with_backoff "$max_attempts" 5 "wget -q --show-progress --timeout=30 '$url' -O '$output_file'"
}

# Cleanup on exit
cleanup_on_exit() {
    local exit_code=$?
    
    log_info "Cleaning up temporary files..."
    
    # Remove temporary files
    find /tmp -name "nitrox_*" -type f -mmin +60 -delete 2>/dev/null || true
    find "$INSTALL_DIR" -name "temp_*" -type f -delete 2>/dev/null || true
    
    # Log final status
    if [[ $exit_code -eq 0 ]]; then
        log_success "Installation completed successfully"
        show_installation_summary
    else
        log_error "Installation failed with exit code: $exit_code"
        show_failure_summary
    fi
    
    # Compress logs for easier sharing
    if command -v gzip &> /dev/null; then
        gzip -c "$MAIN_LOG_FILE" > "$LOG_DIR/installation_$(date +%Y%m%d_%H%M%S).log.gz" 2>/dev/null || true
    fi
}

# Show installation summary
show_installation_summary() {
    cat << EOF

🎉 INSTALLATION COMPLETED SUCCESSFULLY!
======================================

Server Details:
- Installation Directory: $INSTALL_DIR
- Server Configuration: $INSTALL_DIR/server/UserData/Config/server.cfg
- Game Files: $GAME_INSTALL_DIR
- Logs Directory: $LOG_DIR

Next Steps:
1. Start the server:
   cd $INSTALL_DIR/server
   ./start-nitrox-vps.sh

2. Check server status:
   tail -f $INSTALL_DIR/server/Logs/*.log

3. Connect to server:
   - Server IP: $(curl -s ifconfig.me 2>/dev/null || echo "YOUR_SERVER_IP")
   - Server Port: 11000
   - Server Name: $SERVER_NAME

Troubleshooting:
- Check logs in: $LOG_DIR
- Configuration file: $INSTALL_DIR/server/UserData/Config/server.cfg
- Game path config: $INSTALL_DIR/server/subnautica_path.txt

EOF
}

# Show failure summary
show_failure_summary() {
    cat << EOF

❌ INSTALLATION FAILED
======================

Please check the following logs for details:
- Main log: $MAIN_LOG_FILE
- Error log: $ERROR_LOG_FILE
- Debug log: $DEBUG_LOG_FILE
- Troubleshooting: $TROUBLESHOOTING_LOG

Common next steps:
1. Review the error messages above
2. Check the troubleshooting guide: $TROUBLESHOOTING_LOG
3. Ensure all requirements are met
4. Try running the script again
5. Report the issue with log files if problem persists

For support, please provide:
- Your Linux distribution and version
- The complete error log: $ERROR_LOG_FILE
- System information: uname -a

EOF
}

# Set up error handling
setup_error_handling() {
    # Initialize logging
    init_logging
    
    # Set up exit trap
    trap cleanup_on_exit EXIT
    
    # Set up error trap
    trap 'handle_error $? "Unexpected error" "${BASH_COMMAND}" "Check the error logs"' ERR
    
    log_info "Error handling and logging system initialized"
}

# Export functions
export -f init_logging
export -f log_info
export -f log_success
export -f log_warning
export -f log_error
export -f log_debug
export -f handle_error
export -f retry_with_backoff
export -f network_retry
export -f setup_error_handling
export -f cleanup_on_exit