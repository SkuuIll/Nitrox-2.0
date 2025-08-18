#!/bin/bash

# System Integration and Startup Management
# Part of Nitrox VPS Deployment System

# Service configuration
SERVICE_NAME="nitrox-server"
SERVICE_USER="nitrox"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME.service"
STARTUP_SCRIPT="$INSTALL_DIR/server/start-nitrox-vps.sh"

# Create dedicated service user
create_service_user() {
    log_info "Creating dedicated service user..."
    
    # Check if user already exists
    if id "$SERVICE_USER" &>/dev/null; then
        log_info "Service user '$SERVICE_USER' already exists"
        return 0
    fi
    
    # Create system user
    if useradd -r -s /bin/false -d "$INSTALL_DIR" -c "Nitrox Server" "$SERVICE_USER" 2>/dev/null; then
        log_success "Service user '$SERVICE_USER' created successfully"
    else
        log_warning "Could not create service user, using current user"
        SERVICE_USER=$(whoami)
    fi
    
    # Set ownership of installation directory
    chown -R "$SERVICE_USER:$SERVICE_USER" "$INSTALL_DIR" 2>/dev/null || true
    
    return 0
}

# Create systemd service file
create_systemd_service() {
    log_info "Creating systemd service..."
    
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Nitrox Subnautica Multiplayer Server
After=network.target
Wants=network.target

[Service]
Type=simple
User=$SERVICE_USER
Group=$SERVICE_USER
WorkingDirectory=$INSTALL_DIR/server
ExecStart=$STARTUP_SCRIPT
ExecReload=/bin/kill -HUP \$MAINPID
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=nitrox-server

# Environment variables
Environment=HOME=$INSTALL_DIR/server/UserData
Environment=XDG_CONFIG_HOME=$INSTALL_DIR/server/UserData/.config
Environment=DOTNET_CLI_HOME=$INSTALL_DIR/server/UserData

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$INSTALL_DIR

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096

[Install]
WantedBy=multi-user.target
EOF
    
    # Set proper permissions
    chmod 644 "$SERVICE_FILE"
    
    log_success "Systemd service created: $SERVICE_FILE"
}

# Create SysV init script (for older systems)
create_sysv_init_script() {
    log_info "Creating SysV init script..."
    
    local init_script="/etc/init.d/$SERVICE_NAME"
    
    cat > "$init_script" << EOF
#!/bin/bash
# Nitrox Server Init Script
# chkconfig: 35 80 20
# description: Nitrox Subnautica Multiplayer Server

. /etc/rc.d/init.d/functions

USER="$SERVICE_USER"
DAEMON="$SERVICE_NAME"
ROOT_DIR="$INSTALL_DIR/server"
SERVER_SCRIPT="\$ROOT_DIR/start-nitrox-vps.sh"
LOCK_FILE="/var/lock/subsys/\$DAEMON"

start() {
    if [ -f \$LOCK_FILE ]; then
        echo "\$DAEMON is already running."
        exit 0
    fi
    
    echo -n "Starting \$DAEMON: "
    daemon --user "\$USER" --pidfile="\$LOCK_FILE" "\$SERVER_SCRIPT" && echo_success || echo_failure
    RETVAL=\$?
    echo
    [ \$RETVAL -eq 0 ] && touch \$LOCK_FILE
    return \$RETVAL
}

stop() {
    echo -n "Shutting down \$DAEMON: "
    pid=\$(ps -aefw | grep "\$DAEMON" | grep -v " grep " | awk '{print \$2}')
    kill -9 \$pid > /dev/null 2>&1
    [ \$? -eq 0 ] && echo_success || echo_failure
    echo
    rm -f \$LOCK_FILE
}

restart() {
    stop
    start
}

status() {
    if [ -f \$LOCK_FILE ]; then
        echo "\$DAEMON is running."
    else
        echo "\$DAEMON is stopped."
    fi
}

case "\$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    restart)
        restart
        ;;
    *)
        echo "Usage: {\$0 {start|stop|status|restart}"
        exit 1
        ;;
esac

exit \$?
EOF
    
    chmod +x "$init_script"
    
    log_success "SysV init script created: $init_script"
}

# Configure automatic startup
configure_auto_startup() {
    log_info "Configuring automatic startup..."
    
    # Try systemd first (modern systems)
    if command -v systemctl &> /dev/null; then
        log_info "Using systemd for service management"
        
        # Reload systemd
        systemctl daemon-reload
        
        # Enable service
        systemctl enable "$SERVICE_NAME"
        
        log_success "Service enabled for automatic startup"
        return 0
        
    # Try SysV init (older systems)
    elif command -v chkconfig &> /dev/null; then
        log_info "Using SysV init for service management"
        
        # Add service to chkconfig
        chkconfig --add "$SERVICE_NAME"
        chkconfig "$SERVICE_NAME" on
        
        log_success "Service enabled for automatic startup (SysV)"
        return 0
        
    # Try update-rc.d (Debian/Ubuntu without systemd)
    elif command -v update-rc.d &> /dev/null; then
        log_info "Using update-rc.d for service management"
        
        update-rc.d "$SERVICE_NAME" defaults
        
        log_success "Service enabled for automatic startup (update-rc.d)"
        return 0
        
    else
        log_warning "No supported init system found"
        log_info "You may need to configure automatic startup manually"
        return 1
    fi
}

# Create server management scripts
create_management_scripts() {
    log_info "Creating server management scripts..."
    
    # Create start script
    cat > "$INSTALL_DIR/start-server.sh" << EOF
#!/bin/bash
# Start Nitrox Server

if command -v systemctl &> /dev/null; then
    echo "Starting Nitrox server via systemd..."
    sudo systemctl start $SERVICE_NAME
    sudo systemctl status $SERVICE_NAME
else
    echo "Starting Nitrox server directly..."
    cd "$INSTALL_DIR/server"
    ./start-nitrox-vps.sh
fi
EOF
    
    # Create stop script
    cat > "$INSTALL_DIR/stop-server.sh" << EOF
#!/bin/bash
# Stop Nitrox Server

if command -v systemctl &> /dev/null; then
    echo "Stopping Nitrox server via systemd..."
    sudo systemctl stop $SERVICE_NAME
else
    echo "Stopping Nitrox server..."
    pkill -f "NitroxServer-Subnautica.dll" || true
fi
EOF
    
    # Create restart script
    cat > "$INSTALL_DIR/restart-server.sh" << EOF
#!/bin/bash
# Restart Nitrox Server

if command -v systemctl &> /dev/null; then
    echo "Restarting Nitrox server via systemd..."
    sudo systemctl restart $SERVICE_NAME
    sudo systemctl status $SERVICE_NAME
else
    echo "Restarting Nitrox server..."
    ./stop-server.sh
    sleep 5
    ./start-server.sh
fi
EOF
    
    # Create status script
    cat > "$INSTALL_DIR/status-server.sh" << EOF
#!/bin/bash
# Check Nitrox Server Status

if command -v systemctl &> /dev/null; then
    echo "Checking Nitrox server status via systemd..."
    sudo systemctl status $SERVICE_NAME
else
    echo "Checking Nitrox server status..."
    if pgrep -f "NitroxServer-Subnautica.dll" > /dev/null; then
        echo "Nitrox server is running"
        ps aux | grep "NitroxServer-Subnautica.dll" | grep -v grep
    else
        echo "Nitrox server is not running"
    fi
fi

echo
echo "Server logs:"
tail -n 20 "$INSTALL_DIR/server/Logs"/*.log 2>/dev/null || echo "No logs found"
EOF
    
    # Make scripts executable
    chmod +x "$INSTALL_DIR"/*.sh
    
    log_success "Management scripts created in $INSTALL_DIR"
}

# Create health check script
create_health_check() {
    log_info "Creating health check script..."
    
    cat > "$INSTALL_DIR/health-check.sh" << EOF
#!/bin/bash
# Nitrox Server Health Check

SERVER_PORT=11000
LOG_FILE="$INSTALL_DIR/logs/health-check.log"

# Function to log with timestamp
log_health() {
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] \$1" >> "\$LOG_FILE"
}

# Check if server process is running
if ! pgrep -f "NitroxServer-Subnautica.dll" > /dev/null; then
    log_health "CRITICAL: Server process not running"
    exit 2
fi

# Check if port is listening
if ! netstat -tulpn 2>/dev/null | grep ":\$SERVER_PORT " > /dev/null; then
    log_health "WARNING: Server port \$SERVER_PORT not listening"
    exit 1
fi

# Check log file for recent activity
RECENT_LOGS=\$(find "$INSTALL_DIR/server/Logs" -name "*.log" -mmin -5 2>/dev/null | wc -l)
if [ "\$RECENT_LOGS" -eq 0 ]; then
    log_health "WARNING: No recent log activity"
    exit 1
fi

# Check memory usage
MEMORY_USAGE=\$(ps -o pid,ppid,cmd,%mem --sort=-%mem | grep "NitroxServer-Subnautica.dll" | awk '{print \$4}' | head -n1)
if [ -n "\$MEMORY_USAGE" ] && [ "\$(echo "\$MEMORY_USAGE > 80" | bc -l 2>/dev/null || echo 0)" -eq 1 ]; then
    log_health "WARNING: High memory usage: \${MEMORY_USAGE}%"
fi

log_health "OK: Server is healthy"
exit 0
EOF
    
    chmod +x "$INSTALL_DIR/health-check.sh"
    
    log_success "Health check script created"
}

# Configure log rotation
configure_log_rotation() {
    log_info "Configuring log rotation..."
    
    cat > "/etc/logrotate.d/$SERVICE_NAME" << EOF
$INSTALL_DIR/server/Logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    copytruncate
    su $SERVICE_USER $SERVICE_USER
}

$INSTALL_DIR/logs/*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
    su $SERVICE_USER $SERVICE_USER
}
EOF
    
    log_success "Log rotation configured"
}

# Setup monitoring and alerting
setup_monitoring() {
    log_info "Setting up basic monitoring..."
    
    # Create monitoring cron job
    cat > "/etc/cron.d/$SERVICE_NAME-monitor" << EOF
# Nitrox Server Monitoring
*/5 * * * * $SERVICE_USER $INSTALL_DIR/health-check.sh
0 */6 * * * $SERVICE_USER find $INSTALL_DIR/logs -name "*.log" -mtime +7 -delete
EOF
    
    log_success "Basic monitoring configured"
}

# Test server startup
test_server_startup() {
    log_info "Testing server startup..."
    
    # Start server
    if command -v systemctl &> /dev/null; then
        systemctl start "$SERVICE_NAME"
        sleep 10
        
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            log_success "Server started successfully via systemd"
            
            # Check if port is listening
            if netstat -tulpn 2>/dev/null | grep ":11000 " > /dev/null; then
                log_success "Server is listening on port 11000"
            else
                log_warning "Server started but port 11000 not detected"
            fi
            
            # Stop server after test
            systemctl stop "$SERVICE_NAME"
            log_info "Test completed, server stopped"
            
        else
            log_error "Server failed to start via systemd"
            systemctl status "$SERVICE_NAME"
            return 1
        fi
    else
        log_info "Systemd not available, skipping startup test"
    fi
    
    return 0
}

# Show service management information
show_service_info() {
    log_info "Service Management Information:"
    echo "================================"
    echo "Service Name: $SERVICE_NAME"
    echo "Service User: $SERVICE_USER"
    echo "Installation Directory: $INSTALL_DIR"
    echo
    echo "Management Commands:"
    if command -v systemctl &> /dev/null; then
        echo "  Start:   sudo systemctl start $SERVICE_NAME"
        echo "  Stop:    sudo systemctl stop $SERVICE_NAME"
        echo "  Restart: sudo systemctl restart $SERVICE_NAME"
        echo "  Status:  sudo systemctl status $SERVICE_NAME"
        echo "  Logs:    sudo journalctl -u $SERVICE_NAME -f"
    else
        echo "  Start:   $INSTALL_DIR/start-server.sh"
        echo "  Stop:    $INSTALL_DIR/stop-server.sh"
        echo "  Restart: $INSTALL_DIR/restart-server.sh"
        echo "  Status:  $INSTALL_DIR/status-server.sh"
    fi
    echo
    echo "Health Check: $INSTALL_DIR/health-check.sh"
    echo "Log Files: $INSTALL_DIR/server/Logs/"
    echo "================================"
}

# Main system integration function
setup_system_integration() {
    log_info "Setting up system integration and startup management..."
    
    # Create service user
    create_service_user
    
    # Create service files
    if command -v systemctl &> /dev/null; then
        create_systemd_service
    else
        create_sysv_init_script
    fi
    
    # Configure automatic startup
    configure_auto_startup
    
    # Create management scripts
    create_management_scripts
    
    # Create health check
    create_health_check
    
    # Configure log rotation
    configure_log_rotation
    
    # Setup monitoring
    setup_monitoring
    
    # Test server startup
    if ! test_server_startup; then
        log_warning "Server startup test failed, but installation will continue"
    fi
    
    # Show service information
    show_service_info
    
    log_success "System integration and startup management completed successfully"
    return 0
}

# Export functions
export -f setup_system_integration
export -f create_service_user
export -f create_systemd_service
export -f configure_auto_startup
export -f create_management_scripts
export -f create_health_check
export -f test_server_startup
export -f show_service_info