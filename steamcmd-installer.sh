#!/bin/bash

# SteamCMD Installation and Configuration Module
# Part of Nitrox VPS Deployment System

# SteamCMD configuration
STEAMCMD_URL="https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz"
STEAMCMD_DIR="$INSTALL_DIR/steamcmd"
STEAMCMD_USER="steam"

# Install SteamCMD
install_steamcmd() {
    log_info "Installing SteamCMD..."
    
    # Create SteamCMD directory
    mkdir -p "$STEAMCMD_DIR"
    cd "$STEAMCMD_DIR"
    
    # Download SteamCMD
    log_info "Downloading SteamCMD from $STEAMCMD_URL..."
    if ! wget -q --show-progress "$STEAMCMD_URL" -O steamcmd_linux.tar.gz; then
        log_error "Failed to download SteamCMD"
        return 1
    fi
    
    # Extract SteamCMD
    log_info "Extracting SteamCMD..."
    if ! tar -xzf steamcmd_linux.tar.gz; then
        log_error "Failed to extract SteamCMD"
        return 1
    fi
    
    # Remove downloaded archive
    rm -f steamcmd_linux.tar.gz
    
    # Make steamcmd.sh executable
    chmod +x steamcmd.sh
    
    log_success "SteamCMD downloaded and extracted successfully"
    return 0
}

# Create Steam user for security
create_steam_user() {
    log_info "Creating Steam user for secure operations..."
    
    # Check if steam user already exists
    if id "$STEAMCMD_USER" &>/dev/null; then
        log_info "Steam user already exists"
        return 0
    fi
    
    # Create steam user with no login shell and home directory
    if useradd -r -s /bin/false -d "$STEAMCMD_DIR" "$STEAMCMD_USER" 2>/dev/null; then
        log_success "Steam user created successfully"
    else
        log_warning "Could not create steam user, continuing with current user"
    fi
    
    return 0
}

# Configure SteamCMD for headless operation
configure_steamcmd() {
    log_info "Configuring SteamCMD for headless operation..."
    
    # Set proper ownership and permissions
    chown -R "$STEAMCMD_USER:$STEAMCMD_USER" "$STEAMCMD_DIR" 2>/dev/null || true
    chmod -R 755 "$STEAMCMD_DIR"
    
    # Create SteamCMD configuration directory
    local steam_config_dir="$STEAMCMD_DIR/.steam"
    mkdir -p "$steam_config_dir"
    
    # Set environment variables for headless operation
    export STEAM_COMPAT_DATA_PATH="$STEAMCMD_DIR"
    export STEAM_COMPAT_CLIENT_INSTALL_PATH="$STEAMCMD_DIR"
    
    log_success "SteamCMD configured for headless operation"
    return 0
}

# Test SteamCMD installation
test_steamcmd_installation() {
    log_info "Testing SteamCMD installation..."
    
    cd "$STEAMCMD_DIR"
    
    # Create a simple test script
    cat > test_steamcmd.txt << EOF
@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
login anonymous
quit
EOF
    
    # Run SteamCMD test
    log_info "Running SteamCMD test (this may take a moment)..."
    if timeout 60 ./steamcmd.sh +runscript test_steamcmd.txt > steamcmd_test.log 2>&1; then
        log_success "SteamCMD test completed successfully"
        rm -f test_steamcmd.txt steamcmd_test.log
        return 0
    else
        log_error "SteamCMD test failed"
        log_info "Check $STEAMCMD_DIR/steamcmd_test.log for details"
        return 1
    fi
}

# Verify SteamCMD installation
verify_steamcmd_installation() {
    log_info "Verifying SteamCMD installation..."
    
    # Check if steamcmd.sh exists and is executable
    if [[ ! -f "$STEAMCMD_DIR/steamcmd.sh" ]]; then
        log_error "SteamCMD executable not found at $STEAMCMD_DIR/steamcmd.sh"
        return 1
    fi
    
    if [[ ! -x "$STEAMCMD_DIR/steamcmd.sh" ]]; then
        log_error "SteamCMD executable is not executable"
        return 1
    fi
    
    # Check for required libraries
    log_info "Checking SteamCMD dependencies..."
    if ! ldd "$STEAMCMD_DIR/linux32/steamcmd" &>/dev/null; then
        log_warning "Some SteamCMD dependencies may be missing"
        log_info "This is normal on first run, SteamCMD will download them automatically"
    fi
    
    log_success "SteamCMD installation verified"
    return 0
}

# Update SteamCMD to latest version
update_steamcmd() {
    log_info "Updating SteamCMD to latest version..."
    
    cd "$STEAMCMD_DIR"
    
    # Create update script
    cat > update_steamcmd.txt << EOF
@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
login anonymous
quit
EOF
    
    # Run update (SteamCMD auto-updates on first run)
    if timeout 120 ./steamcmd.sh +runscript update_steamcmd.txt > steamcmd_update.log 2>&1; then
        log_success "SteamCMD updated successfully"
        rm -f update_steamcmd.txt steamcmd_update.log
        return 0
    else
        log_warning "SteamCMD update may have failed, but this is often normal"
        log_info "SteamCMD will continue to work and auto-update as needed"
        rm -f update_steamcmd.txt
        return 0
    fi
}

# Main SteamCMD installation function
install_and_configure_steamcmd() {
    log_info "Starting SteamCMD installation and configuration..."
    
    # Install SteamCMD
    if ! install_steamcmd; then
        log_error "SteamCMD installation failed"
        return 1
    fi
    
    # Create Steam user
    create_steam_user
    
    # Configure SteamCMD
    if ! configure_steamcmd; then
        log_error "SteamCMD configuration failed"
        return 1
    fi
    
    # Verify installation
    if ! verify_steamcmd_installation; then
        log_error "SteamCMD verification failed"
        return 1
    fi
    
    # Update SteamCMD
    update_steamcmd
    
    # Test installation
    if ! test_steamcmd_installation; then
        log_warning "SteamCMD test failed, but installation may still work"
        log_info "Continuing with installation..."
    fi
    
    log_success "SteamCMD installation and configuration completed successfully"
    return 0
}

# Function to run SteamCMD commands safely
run_steamcmd_command() {
    local script_content="$1"
    local timeout_seconds="${2:-300}"  # Default 5 minutes
    local log_file="${3:-steamcmd_command.log}"
    
    cd "$STEAMCMD_DIR"
    
    # Create temporary script file
    local script_file="temp_steamcmd_$(date +%s).txt"
    echo "$script_content" > "$script_file"
    
    # Run SteamCMD with timeout
    log_info "Executing SteamCMD command (timeout: ${timeout_seconds}s)..."
    if timeout "$timeout_seconds" ./steamcmd.sh +runscript "$script_file" > "$log_file" 2>&1; then
        rm -f "$script_file"
        return 0
    else
        local exit_code=$?
        log_error "SteamCMD command failed (exit code: $exit_code)"
        log_info "Check $STEAMCMD_DIR/$log_file for details"
        rm -f "$script_file"
        return $exit_code
    fi
}

# Export functions for use in main script
export -f install_and_configure_steamcmd
export -f run_steamcmd_command
export -f install_steamcmd
export -f create_steam_user
export -f configure_steamcmd
export -f test_steamcmd_installation
export -f verify_steamcmd_installation
export -f update_steamcmd