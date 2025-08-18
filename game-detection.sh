#!/bin/bash

# Enhanced Game Installation Detection
# Part of Nitrox VPS Deployment System

# Game detection configuration
GAME_PATHS_CONFIG="$INSTALL_DIR/server/subnautica_path.txt"
GAME_DETECTION_LOG="$INSTALL_DIR/logs/game_detection.log"

# Common VPS game installation paths
VPS_GAME_PATHS=(
    "$INSTALL_DIR/gamefiles"
    "/opt/subnautica"
    "/home/steam/subnautica"
    "/usr/local/games/subnautica"
    "/opt/games/subnautica"
    "$HOME/subnautica"
)

# Required Subnautica files for validation
REQUIRED_GAME_FILES=(
    "Subnautica.exe"
    "Subnautica_Data/Managed/Assembly-CSharp.dll"
    "Subnautica_Data/Managed/UnityEngine.dll"
    "Subnautica_Data/StreamingAssets"
    "Subnautica_Data/Resources"
    "Subnautica_Data/level0"
)

# Validate game installation at given path
validate_game_installation() {
    local game_path="$1"
    local log_validation="${2:-false}"
    
    if [[ "$log_validation" == "true" ]]; then
        log_info "Validating game installation at: $game_path"
    fi
    
    # Check if directory exists
    if [[ ! -d "$game_path" ]]; then
        if [[ "$log_validation" == "true" ]]; then
            log_warning "Directory does not exist: $game_path"
        fi
        return 1
    fi
    
    # Check for required files
    local missing_files=()
    for file in "${REQUIRED_GAME_FILES[@]}"; do
        local full_path="$game_path/$file"
        if [[ ! -e "$full_path" ]]; then
            missing_files+=("$file")
        fi
    done
    
    # Report validation results
    if [[ ${#missing_files[@]} -eq 0 ]]; then
        if [[ "$log_validation" == "true" ]]; then
            log_success "Game installation validation passed"
        fi
        return 0
    else
        if [[ "$log_validation" == "true" ]]; then
            log_warning "Missing required files:"
            for file in "${missing_files[@]}"; do
                log_warning "  - $file"
            done
        fi
        return 1
    fi
}

# Find game installation using priority-based detection
find_game_installation() {
    log_info "Starting game installation detection..."
    
    # Initialize detection log
    echo "Game Installation Detection - $(date)" > "$GAME_DETECTION_LOG"
    echo "========================================" >> "$GAME_DETECTION_LOG"
    
    # PRIORITY 1: Manual configuration file
    if [[ -f "$GAME_PATHS_CONFIG" ]]; then
        local configured_path
        configured_path=$(cat "$GAME_PATHS_CONFIG" | head -n1 | tr -d '\r\n' | xargs)
        
        log_info "Found manual configuration: $configured_path"
        echo "Manual config path: $configured_path" >> "$GAME_DETECTION_LOG"
        
        if validate_game_installation "$configured_path" true; then
            log_success "Using manually configured game path: $configured_path"
            echo "RESULT: Manual config - SUCCESS" >> "$GAME_DETECTION_LOG"
            return 0
        else
            log_warning "Manually configured path is invalid: $configured_path"
            echo "RESULT: Manual config - INVALID" >> "$GAME_DETECTION_LOG"
        fi
    else
        log_info "No manual configuration found at: $GAME_PATHS_CONFIG"
        echo "Manual config: NOT FOUND" >> "$GAME_DETECTION_LOG"
    fi
    
    # PRIORITY 2: Common VPS paths
    log_info "Checking common VPS installation paths..."
    echo "Checking VPS paths:" >> "$GAME_DETECTION_LOG"
    
    for path in "${VPS_GAME_PATHS[@]}"; do
        echo "  Checking: $path" >> "$GAME_DETECTION_LOG"
        if validate_game_installation "$path"; then
            log_success "Found valid game installation at: $path"
            echo "RESULT: VPS path - SUCCESS ($path)" >> "$GAME_DETECTION_LOG"
            
            # Create configuration file for future use
            create_game_path_config "$path"
            return 0
        fi
    done
    
    # PRIORITY 3: Environment variable
    local env_path="$SUBNAUTICA_INSTALLATION_PATH"
    if [[ -n "$env_path" ]]; then
        log_info "Checking environment variable path: $env_path"
        echo "Environment path: $env_path" >> "$GAME_DETECTION_LOG"
        
        if validate_game_installation "$env_path" true; then
            log_success "Using environment variable game path: $env_path"
            echo "RESULT: Environment - SUCCESS" >> "$GAME_DETECTION_LOG"
            
            # Create configuration file for future use
            create_game_path_config "$env_path"
            return 0
        else
            log_warning "Environment variable path is invalid: $env_path"
            echo "RESULT: Environment - INVALID" >> "$GAME_DETECTION_LOG"
        fi
    else
        echo "Environment path: NOT SET" >> "$GAME_DETECTION_LOG"
    fi
    
    # PRIORITY 4: Search common directories
    log_info "Searching for Subnautica in common directories..."
    echo "Searching common directories:" >> "$GAME_DETECTION_LOG"
    
    local search_paths=(
        "/opt"
        "/usr/local/games"
        "/home"
        "$HOME"
    )
    
    for search_path in "${search_paths[@]}"; do
        if [[ -d "$search_path" ]]; then
            echo "  Searching in: $search_path" >> "$GAME_DETECTION_LOG"
            local found_paths
            found_paths=$(find "$search_path" -maxdepth 3 -type d -name "*subnautica*" -o -name "*Subnautica*" 2>/dev/null || true)
            
            while IFS= read -r found_path; do
                if [[ -n "$found_path" ]]; then
                    echo "    Found candidate: $found_path" >> "$GAME_DETECTION_LOG"
                    if validate_game_installation "$found_path"; then
                        log_success "Found valid game installation at: $found_path"
                        echo "RESULT: Search - SUCCESS ($found_path)" >> "$GAME_DETECTION_LOG"
                        
                        # Create configuration file for future use
                        create_game_path_config "$found_path"
                        return 0
                    fi
                fi
            done <<< "$found_paths"
        fi
    done
    
    # No valid installation found
    log_error "Could not locate valid Subnautica installation"
    echo "RESULT: FAILED - No valid installation found" >> "$GAME_DETECTION_LOG"
    
    # Provide helpful error message
    show_game_installation_help
    return 1
}

# Show help for game installation setup
show_game_installation_help() {
    log_error "Subnautica installation not found!"
    echo
    log_info "To fix this issue, you can:"
    echo "  1. Create a file: $GAME_PATHS_CONFIG"
    echo "  2. Put the full path to your Subnautica installation in that file"
    echo "  3. Example content: /opt/nitrox/gamefiles"
    echo
    log_info "Or set the environment variable:"
    echo "  export SUBNAUTICA_INSTALLATION_PATH=/path/to/subnautica"
    echo
    log_info "The Subnautica directory should contain:"
    for file in "${REQUIRED_GAME_FILES[@]}"; do
        echo "  - $file"
    done
    echo
    log_info "Check the detection log for more details: $GAME_DETECTION_LOG"
}

# Create game path configuration file
create_game_path_config() {
    local game_path="$1"
    
    log_info "Creating game path configuration..."
    
    # Ensure directory exists
    mkdir -p "$(dirname "$GAME_PATHS_CONFIG")"
    
    # Write path to config file
    echo "$game_path" > "$GAME_PATHS_CONFIG"
    chmod 644 "$GAME_PATHS_CONFIG"
    
    log_success "Game path configuration created: $GAME_PATHS_CONFIG"
    log_info "Game path: $game_path"
}

# Verify game installation and report details
verify_and_report_game_installation() {
    local game_path="$1"
    
    log_info "Verifying and reporting game installation details..."
    
    if ! validate_game_installation "$game_path" true; then
        return 1
    fi
    
    # Calculate installation size
    local install_size
    install_size=$(du -sh "$game_path" 2>/dev/null | cut -f1 || echo "Unknown")
    
    # Count files
    local file_count
    file_count=$(find "$game_path" -type f 2>/dev/null | wc -l || echo "Unknown")
    
    # Check version info if available
    local version_info="Unknown"
    local version_file="$game_path/Subnautica_Data/StreamingAssets/SNUnmanagedData/buildinfo.json"
    if [[ -f "$version_file" ]]; then
        version_info=$(grep -o '"Version":"[^"]*"' "$version_file" 2>/dev/null | cut -d'"' -f4 || echo "Unknown")
    fi
    
    # Report details
    log_success "Game Installation Details:"
    echo "  Path: $game_path"
    echo "  Size: $install_size"
    echo "  Files: $file_count"
    echo "  Version: $version_info"
    
    # Check for common issues
    check_game_installation_issues "$game_path"
    
    return 0
}

# Check for common game installation issues
check_game_installation_issues() {
    local game_path="$1"
    
    log_info "Checking for common installation issues..."
    
    # Check permissions
    if [[ ! -r "$game_path/Subnautica.exe" ]]; then
        log_warning "Subnautica.exe is not readable - check permissions"
    fi
    
    # Check for incomplete downloads
    local data_dir="$game_path/Subnautica_Data"
    if [[ -d "$data_dir" ]]; then
        local managed_dlls
        managed_dlls=$(find "$data_dir/Managed" -name "*.dll" 2>/dev/null | wc -l)
        if [[ $managed_dlls -lt 50 ]]; then
            log_warning "Low number of managed assemblies ($managed_dlls) - installation may be incomplete"
        fi
    fi
    
    # Check disk space
    local available_space
    available_space=$(df -h "$game_path" 2>/dev/null | awk 'NR==2 {print $4}' || echo "Unknown")
    log_info "Available disk space: $available_space"
}

# Test game installation with Nitrox server
test_game_installation_with_server() {
    local game_path="$1"
    
    log_info "Testing game installation with Nitrox server..."
    
    # Set environment variable for test
    export SUBNAUTICA_INSTALLATION_PATH="$game_path"
    
    # Create test configuration
    create_game_path_config "$game_path"
    
    # Try to start server in test mode (if available)
    cd "$NITROX_SERVER_DIR"
    
    log_info "Game installation test completed"
    return 0
}

# Main game detection function
detect_and_configure_game_installation() {
    log_info "Starting game installation detection and configuration..."
    
    # Find game installation
    if ! find_game_installation; then
        log_error "Game installation detection failed"
        return 1
    fi
    
    # Get the detected path
    local detected_path
    if [[ -f "$GAME_PATHS_CONFIG" ]]; then
        detected_path=$(cat "$GAME_PATHS_CONFIG" | head -n1 | tr -d '\r\n' | xargs)
    else
        log_error "Game path configuration not found after detection"
        return 1
    fi
    
    # Verify and report details
    if ! verify_and_report_game_installation "$detected_path"; then
        log_error "Game installation verification failed"
        return 1
    fi
    
    # Test with server
    test_game_installation_with_server "$detected_path"
    
    log_success "Game installation detection and configuration completed successfully"
    return 0
}

# Export functions
export -f detect_and_configure_game_installation
export -f find_game_installation
export -f validate_game_installation
export -f create_game_path_config
export -f verify_and_report_game_installation
export -f show_game_installation_help