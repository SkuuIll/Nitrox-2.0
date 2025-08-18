#!/bin/bash

# Subnautica Download Manager
# Part of Nitrox VPS Deployment System

# Subnautica configuration
SUBNAUTICA_APP_ID=264710
GAME_INSTALL_DIR="$INSTALL_DIR/gamefiles"
MAX_DOWNLOAD_RETRIES=3
DOWNLOAD_TIMEOUT=1800  # 30 minutes
RETRY_DELAY_BASE=30    # Base delay for exponential backoff

# Download Subnautica using SteamCMD
download_subnautica() {
    local steam_user="$1"
    local steam_pass="$2"
    local install_dir="$3"
    
    log_info "Starting Subnautica download..."
    log_info "Steam User: $steam_user"
    log_info "Install Directory: $install_dir"
    log_info "App ID: $SUBNAUTICA_APP_ID"
    
    # Create install directory
    mkdir -p "$install_dir"
    
    # Create SteamCMD download script
    local steamcmd_script="@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
login $steam_user $steam_pass
force_install_dir $install_dir
app_update $SUBNAUTICA_APP_ID validate
quit"
    
    # Execute download with retry logic
    local retry_count=0
    local success=false
    
    while [[ $retry_count -lt $MAX_DOWNLOAD_RETRIES ]]; do
        retry_count=$((retry_count + 1))
        log_info "Download attempt $retry_count of $MAX_DOWNLOAD_RETRIES"
        
        # Calculate delay for exponential backoff
        local delay=$((RETRY_DELAY_BASE * retry_count))
        
        if [[ $retry_count -gt 1 ]]; then
            log_info "Waiting ${delay} seconds before retry..."
            sleep $delay
        fi
        
        # Run SteamCMD download
        if run_steamcmd_command "$steamcmd_script" "$DOWNLOAD_TIMEOUT" "subnautica_download_$retry_count.log"; then
            log_success "Subnautica download completed successfully"
            success=true
            break
        else
            log_warning "Download attempt $retry_count failed"
            
            # Check if it's an authentication error
            if grep -q "Invalid Password\|Invalid Login" "$STEAMCMD_DIR/subnautica_download_$retry_count.log" 2>/dev/null; then
                log_error "Steam authentication failed. Please check your credentials."
                return 1
            fi
            
            # Check if it's a network error
            if grep -q "No connection\|Network\|Timeout" "$STEAMCMD_DIR/subnautica_download_$retry_count.log" 2>/dev/null; then
                log_warning "Network error detected, will retry..."
            fi
        fi
    done
    
    if [[ "$success" != "true" ]]; then
        log_error "Failed to download Subnautica after $MAX_DOWNLOAD_RETRIES attempts"
        return 1
    fi
    
    return 0
}

# Verify Subnautica game files
verify_subnautica_files() {
    local install_dir="$1"
    
    log_info "Verifying Subnautica game files..."
    
    # Check if install directory exists
    if [[ ! -d "$install_dir" ]]; then
        log_error "Game install directory not found: $install_dir"
        return 1
    fi
    
    # Required files and directories for Subnautica
    local required_files=(
        "Subnautica.exe"
        "Subnautica_Data/Managed/Assembly-CSharp.dll"
        "Subnautica_Data/Managed/UnityEngine.dll"
        "Subnautica_Data/StreamingAssets"
        "Subnautica_Data/Resources"
    )
    
    local missing_files=()
    
    # Check each required file/directory
    for file in "${required_files[@]}"; do
        local full_path="$install_dir/$file"
        if [[ ! -e "$full_path" ]]; then
            missing_files+=("$file")
        fi
    done
    
    # Report results
    if [[ ${#missing_files[@]} -eq 0 ]]; then
        log_success "All required Subnautica files are present"
        
        # Calculate and display download size
        local download_size
        download_size=$(du -sh "$install_dir" 2>/dev/null | cut -f1 || echo "Unknown")
        log_info "Total download size: $download_size"
        
        return 0
    else
        log_error "Missing required Subnautica files:"
        for file in "${missing_files[@]}"; do
            log_error "  - $file"
        done
        return 1
    fi
}

# Validate Subnautica installation integrity
validate_subnautica_installation() {
    local install_dir="$1"
    
    log_info "Validating Subnautica installation integrity..."
    
    # Check executable permissions
    local subnautica_exe="$install_dir/Subnautica.exe"
    if [[ -f "$subnautica_exe" ]]; then
        chmod +x "$subnautica_exe"
        log_info "Set executable permissions on Subnautica.exe"
    fi
    
    # Check critical assemblies
    local assemblies_dir="$install_dir/Subnautica_Data/Managed"
    if [[ -d "$assemblies_dir" ]]; then
        local assembly_count
        assembly_count=$(find "$assemblies_dir" -name "*.dll" | wc -l)
        log_info "Found $assembly_count .NET assemblies"
        
        if [[ $assembly_count -lt 50 ]]; then
            log_warning "Low assembly count detected, installation may be incomplete"
        fi
    fi
    
    # Check streaming assets
    local streaming_assets="$install_dir/Subnautica_Data/StreamingAssets"
    if [[ -d "$streaming_assets" ]]; then
        local asset_size
        asset_size=$(du -sh "$streaming_assets" 2>/dev/null | cut -f1 || echo "Unknown")
        log_info "StreamingAssets size: $asset_size"
    fi
    
    # Verify file permissions
    log_info "Setting proper file permissions..."
    chmod -R 755 "$install_dir"
    
    log_success "Subnautica installation validation completed"
    return 0
}

# Clean up failed downloads
cleanup_failed_download() {
    local install_dir="$1"
    
    log_info "Cleaning up failed download..."
    
    # Remove incomplete installation
    if [[ -d "$install_dir" ]]; then
        log_info "Removing incomplete installation at $install_dir"
        rm -rf "$install_dir"
    fi
    
    # Clean up SteamCMD temporary files
    if [[ -d "$STEAMCMD_DIR" ]]; then
        find "$STEAMCMD_DIR" -name "*.log" -mtime +1 -delete 2>/dev/null || true
        find "$STEAMCMD_DIR" -name "temp_steamcmd_*.txt" -delete 2>/dev/null || true
    fi
    
    log_info "Cleanup completed"
}

# Monitor download progress (if possible)
monitor_download_progress() {
    local install_dir="$1"
    local pid="$2"
    
    log_info "Monitoring download progress..."
    
    local last_size=0
    local stall_count=0
    local max_stalls=10
    
    while kill -0 "$pid" 2>/dev/null; do
        if [[ -d "$install_dir" ]]; then
            local current_size
            current_size=$(du -s "$install_dir" 2>/dev/null | cut -f1 || echo "0")
            
            if [[ $current_size -gt $last_size ]]; then
                local size_mb=$((current_size / 1024))
                log_info "Downloaded: ${size_mb}MB"
                last_size=$current_size
                stall_count=0
            else
                stall_count=$((stall_count + 1))
                if [[ $stall_count -ge $max_stalls ]]; then
                    log_warning "Download appears stalled, but continuing..."
                    stall_count=0
                fi
            fi
        fi
        
        sleep 30
    done
}

# Create subnautica_path.txt configuration file
create_game_path_config() {
    local install_dir="$1"
    local config_file="$INSTALL_DIR/server/subnautica_path.txt"
    
    log_info "Creating game path configuration file..."
    
    echo "$install_dir" > "$config_file"
    chmod 644 "$config_file"
    
    log_success "Game path configuration created: $config_file"
    log_info "Game path: $install_dir"
}

# Main Subnautica download function
download_and_verify_subnautica() {
    local steam_user="$1"
    local steam_pass="$2"
    
    log_info "Starting Subnautica download and verification process..."
    
    # Download Subnautica
    if ! download_subnautica "$steam_user" "$steam_pass" "$GAME_INSTALL_DIR"; then
        log_error "Subnautica download failed"
        cleanup_failed_download "$GAME_INSTALL_DIR"
        return 1
    fi
    
    # Verify downloaded files
    if ! verify_subnautica_files "$GAME_INSTALL_DIR"; then
        log_error "Subnautica file verification failed"
        cleanup_failed_download "$GAME_INSTALL_DIR"
        return 1
    fi
    
    # Validate installation
    if ! validate_subnautica_installation "$GAME_INSTALL_DIR"; then
        log_error "Subnautica installation validation failed"
        return 1
    fi
    
    # Create game path configuration
    create_game_path_config "$GAME_INSTALL_DIR"
    
    log_success "Subnautica download and verification completed successfully"
    return 0
}

# Repair corrupted installation
repair_subnautica_installation() {
    local steam_user="$1"
    local steam_pass="$2"
    
    log_info "Attempting to repair Subnautica installation..."
    
    # Create repair script (validate existing installation)
    local repair_script="@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
login $steam_user $steam_pass
force_install_dir $GAME_INSTALL_DIR
app_update $SUBNAUTICA_APP_ID validate
quit"
    
    if run_steamcmd_command "$repair_script" "$DOWNLOAD_TIMEOUT" "subnautica_repair.log"; then
        log_success "Subnautica installation repaired successfully"
        return 0
    else
        log_error "Failed to repair Subnautica installation"
        return 1
    fi
}

# Export functions for use in main script
export -f download_and_verify_subnautica
export -f download_subnautica
export -f verify_subnautica_files
export -f validate_subnautica_installation
export -f cleanup_failed_download
export -f create_game_path_config
export -f repair_subnautica_installation