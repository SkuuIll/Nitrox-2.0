#!/bin/bash

# Server Configuration Management System
# Part of Nitrox VPS Deployment System

# Configuration paths
SERVER_CONFIG_DIR="$INSTALL_DIR/server/UserData/Config"
SERVER_CONFIG_FILE="$SERVER_CONFIG_DIR/server.cfg"
BACKUP_CONFIG_DIR="$INSTALL_DIR/server/Config-Backups"
CONFIG_TEMPLATE_DIR="$INSTALL_DIR/config-templates"

# Default server configuration values
DEFAULT_SERVER_PORT=11000
DEFAULT_GAME_MODE="Survival"
DEFAULT_SAVE_INTERVAL=300000
DEFAULT_DISABLE_CONSOLE=false
DEFAULT_ENABLE_WHITELIST=false

# Create server configuration from template
create_server_configuration() {
    log_info "Creating server configuration..."
    
    # Ensure config directory exists
    mkdir -p "$SERVER_CONFIG_DIR"
    mkdir -p "$BACKUP_CONFIG_DIR"
    mkdir -p "$CONFIG_TEMPLATE_DIR"
    
    # Get game path
    local game_path=""
    if [[ -f "$INSTALL_DIR/server/subnautica_path.txt" ]]; then
        game_path=$(cat "$INSTALL_DIR/server/subnautica_path.txt" | head -n1 | tr -d '\r\n' | xargs)
    fi
    
    # Create server configuration JSON
    cat > "$SERVER_CONFIG_FILE" << EOF
{
    "ServerName": "$SERVER_NAME",
    "ServerPort": $DEFAULT_SERVER_PORT,
    "ServerPassword": "$SERVER_PASSWORD",
    "AdminPassword": "$ADMIN_PASSWORD",
    "GameMode": "$DEFAULT_GAME_MODE",
    "MaxPlayers": $MAX_PLAYERS,
    "SaveInterval": $DEFAULT_SAVE_INTERVAL,
    "DisableConsole": $DEFAULT_DISABLE_CONSOLE,
    "EnableWhitelist": $DEFAULT_ENABLE_WHITELIST,
    "GameInstallationPath": "$game_path",
    "ConfigurationPath": "$SERVER_CONFIG_DIR",
    "SavePath": "$INSTALL_DIR/server/Saves",
    "LogPath": "$INSTALL_DIR/server/Logs"
}
EOF
    
    # Set proper permissions
    chmod 644 "$SERVER_CONFIG_FILE"
    
    log_success "Server configuration created: $SERVER_CONFIG_FILE"
}

# Create advanced server configuration template
create_advanced_config_template() {
    log_info "Creating advanced configuration template..."
    
    cat > "$CONFIG_TEMPLATE_DIR/advanced-server.cfg" << 'EOF'
{
    "ServerName": "${SERVER_NAME}",
    "ServerPort": ${SERVER_PORT:-11000},
    "ServerPassword": "${SERVER_PASSWORD}",
    "AdminPassword": "${ADMIN_PASSWORD}",
    "GameMode": "${GAME_MODE:-Survival}",
    "MaxPlayers": ${MAX_PLAYERS:-100},
    "SaveInterval": ${SAVE_INTERVAL:-300000},
    "DisableConsole": ${DISABLE_CONSOLE:-false},
    "EnableWhitelist": ${ENABLE_WHITELIST:-false},
    "GameInstallationPath": "${GAME_PATH}",
    "ConfigurationPath": "${CONFIG_PATH}",
    "SavePath": "${SAVE_PATH}",
    "LogPath": "${LOG_PATH}",
    "Advanced": {
        "AutoSave": true,
        "BackupInterval": 3600000,
        "MaxBackups": 10,
        "EnableMetrics": false,
        "LogLevel": "Info",
        "NetworkTimeout": 30000,
        "MaxConcurrentConnections": ${MAX_PLAYERS:-100},
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
EOF
    
    log_success "Advanced configuration template created"
}

# Validate server configuration
validate_server_configuration() {
    local config_file="$1"
    
    log_info "Validating server configuration..."
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        return 1
    fi
    
    # Check JSON syntax
    if ! python3 -m json.tool "$config_file" > /dev/null 2>&1; then
        if ! jq empty "$config_file" > /dev/null 2>&1; then
            log_error "Invalid JSON syntax in configuration file"
            return 1
        fi
    fi
    
    # Validate required fields
    local required_fields=(
        "ServerName"
        "ServerPort"
        "AdminPassword"
        "GameMode"
        "MaxPlayers"
    )
    
    for field in "${required_fields[@]}"; do
        if ! grep -q "\"$field\"" "$config_file"; then
            log_error "Missing required field: $field"
            return 1
        fi
    done
    
    # Validate port range
    local port
    port=$(grep -o '"ServerPort":[[:space:]]*[0-9]*' "$config_file" | grep -o '[0-9]*$')
    if [[ -n "$port" ]]; then
        if [[ $port -lt 1024 ]] || [[ $port -gt 65535 ]]; then
            log_warning "Server port $port may require special privileges or be invalid"
        fi
    fi
    
    # Validate max players
    local max_players
    max_players=$(grep -o '"MaxPlayers":[[:space:]]*[0-9]*' "$config_file" | grep -o '[0-9]*$')
    if [[ -n "$max_players" ]]; then
        if [[ $max_players -lt 1 ]] || [[ $max_players -gt 100 ]]; then
            log_warning "MaxPlayers value $max_players may cause performance issues"
        fi
    fi
    
    log_success "Configuration validation passed"
    return 0
}

# Backup existing configuration
backup_server_configuration() {
    local config_file="$1"
    local backup_name="${2:-$(date +%Y%m%d_%H%M%S)}"
    
    if [[ -f "$config_file" ]]; then
        log_info "Backing up existing configuration..."
        
        local backup_file="$BACKUP_CONFIG_DIR/server_config_$backup_name.cfg"
        cp "$config_file" "$backup_file"
        
        log_success "Configuration backed up to: $backup_file"
    fi
}

# Restore configuration from backup
restore_server_configuration() {
    local backup_file="$1"
    
    if [[ ! -f "$backup_file" ]]; then
        log_error "Backup file not found: $backup_file"
        return 1
    fi
    
    log_info "Restoring configuration from backup..."
    
    # Backup current config first
    backup_server_configuration "$SERVER_CONFIG_FILE" "pre_restore_$(date +%Y%m%d_%H%M%S)"
    
    # Restore from backup
    cp "$backup_file" "$SERVER_CONFIG_FILE"
    
    # Validate restored configuration
    if validate_server_configuration "$SERVER_CONFIG_FILE"; then
        log_success "Configuration restored successfully"
        return 0
    else
        log_error "Restored configuration is invalid"
        return 1
    fi
}

# Generate configuration from environment variables
generate_config_from_environment() {
    log_info "Generating configuration from environment variables..."
    
    # Set defaults for missing variables
    export SERVER_PORT="${SERVER_PORT:-$DEFAULT_SERVER_PORT}"
    export GAME_MODE="${GAME_MODE:-$DEFAULT_GAME_MODE}"
    export SAVE_INTERVAL="${SAVE_INTERVAL:-$DEFAULT_SAVE_INTERVAL}"
    export DISABLE_CONSOLE="${DISABLE_CONSOLE:-$DEFAULT_DISABLE_CONSOLE}"
    export ENABLE_WHITELIST="${ENABLE_WHITELIST:-$DEFAULT_ENABLE_WHITELIST}"
    
    # Get paths
    export GAME_PATH="$GAME_INSTALL_DIR"
    export CONFIG_PATH="$SERVER_CONFIG_DIR"
    export SAVE_PATH="$INSTALL_DIR/server/Saves"
    export LOG_PATH="$INSTALL_DIR/server/Logs"
    
    # Use advanced template if available
    local template_file="$CONFIG_TEMPLATE_DIR/advanced-server.cfg"
    if [[ -f "$template_file" ]]; then
        log_info "Using advanced configuration template"
        envsubst < "$template_file" > "$SERVER_CONFIG_FILE"
    else
        # Fallback to basic configuration
        create_server_configuration
    fi
    
    log_success "Configuration generated from environment variables"
}

# Update configuration value
update_config_value() {
    local config_file="$1"
    local key="$2"
    local value="$3"
    
    log_info "Updating configuration: $key = $value"
    
    # Backup before modification
    backup_server_configuration "$config_file" "before_update_$(date +%Y%m%d_%H%M%S)"
    
    # Update value using sed (basic JSON modification)
    if grep -q "\"$key\"" "$config_file"; then
        # Key exists, update it
        sed -i "s/\"$key\":[[:space:]]*\"[^\"]*\"/\"$key\": \"$value\"/" "$config_file"
        sed -i "s/\"$key\":[[:space:]]*[0-9]*/\"$key\": $value/" "$config_file"
    else
        log_warning "Key $key not found in configuration file"
        return 1
    fi
    
    # Validate after update
    if validate_server_configuration "$config_file"; then
        log_success "Configuration updated successfully"
        return 0
    else
        log_error "Configuration update resulted in invalid config"
        return 1
    fi
}

# Create firewall configuration
configure_server_firewall() {
    local server_port="$1"
    
    log_info "Configuring firewall for server port $server_port..."
    
    # Try different firewall systems
    if command -v ufw &> /dev/null; then
        # Ubuntu/Debian UFW
        log_info "Configuring UFW firewall..."
        ufw allow "$server_port/udp" comment "Nitrox Server"
        log_success "UFW rule added for port $server_port/udp"
        
    elif command -v firewall-cmd &> /dev/null; then
        # CentOS/RHEL firewalld
        log_info "Configuring firewalld..."
        firewall-cmd --permanent --add-port="$server_port/udp"
        firewall-cmd --reload
        log_success "Firewalld rule added for port $server_port/udp"
        
    elif command -v iptables &> /dev/null; then
        # Generic iptables
        log_info "Configuring iptables..."
        iptables -A INPUT -p udp --dport "$server_port" -j ACCEPT
        
        # Try to save rules
        if command -v iptables-save &> /dev/null; then
            iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
        fi
        log_success "Iptables rule added for port $server_port/udp"
        
    else
        log_warning "No supported firewall system found"
        log_info "Please manually open port $server_port/udp in your firewall"
    fi
}

# Display configuration summary
show_configuration_summary() {
    local config_file="$1"
    
    log_info "Server Configuration Summary:"
    echo "================================"
    
    if [[ -f "$config_file" ]]; then
        # Extract key values
        local server_name port max_players game_mode
        server_name=$(grep -o '"ServerName":[[:space:]]*"[^"]*"' "$config_file" | cut -d'"' -f4)
        port=$(grep -o '"ServerPort":[[:space:]]*[0-9]*' "$config_file" | grep -o '[0-9]*$')
        max_players=$(grep -o '"MaxPlayers":[[:space:]]*[0-9]*' "$config_file" | grep -o '[0-9]*$')
        game_mode=$(grep -o '"GameMode":[[:space:]]*"[^"]*"' "$config_file" | cut -d'"' -f4)
        
        echo "Server Name: $server_name"
        echo "Server Port: $port (UDP)"
        echo "Max Players: $max_players"
        echo "Game Mode: $game_mode"
        echo "Config File: $config_file"
        
        # Check if password protected
        if grep -q '"ServerPassword":[[:space:]]*""' "$config_file"; then
            echo "Server Password: [PUBLIC SERVER]"
        else
            echo "Server Password: [PROTECTED]"
        fi
        
    else
        log_error "Configuration file not found: $config_file"
    fi
    
    echo "================================"
}

# Main configuration function
configure_nitrox_server() {
    log_info "Starting Nitrox server configuration..."
    
    # Create configuration templates
    create_advanced_config_template
    
    # Generate configuration
    generate_config_from_environment
    
    # Validate configuration
    if ! validate_server_configuration "$SERVER_CONFIG_FILE"; then
        log_error "Server configuration validation failed"
        return 1
    fi
    
    # Configure firewall
    configure_server_firewall "$DEFAULT_SERVER_PORT"
    
    # Show configuration summary
    show_configuration_summary "$SERVER_CONFIG_FILE"
    
    log_success "Nitrox server configuration completed successfully"
    return 0
}

# Export functions
export -f configure_nitrox_server
export -f create_server_configuration
export -f validate_server_configuration
export -f backup_server_configuration
export -f restore_server_configuration
export -f update_config_value
export -f configure_server_firewall
export -f show_configuration_summary