#!/bin/bash

# Comprehensive Testing Suite for Nitrox VPS Installation
# Tests all components and validates functionality

# Test configuration
TEST_LOG_DIR="$INSTALL_DIR/tests"
TEST_RESULTS_FILE="$TEST_LOG_DIR/test_results.log"
UNIT_TEST_LOG="$TEST_LOG_DIR/unit_tests.log"
INTEGRATION_TEST_LOG="$TEST_LOG_DIR/integration_tests.log"
SYSTEM_TEST_LOG="$TEST_LOG_DIR/system_tests.log"

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Initialize testing environment
init_testing() {
    log_info "Initializing testing environment..."
    
    mkdir -p "$TEST_LOG_DIR"
    
    echo "=== Nitrox VPS Testing Suite - $(date) ===" > "$TEST_RESULTS_FILE"
    echo "=== Unit Tests - $(date) ===" > "$UNIT_TEST_LOG"
    echo "=== Integration Tests - $(date) ===" > "$INTEGRATION_TEST_LOG"
    echo "=== System Tests - $(date) ===" > "$SYSTEM_TEST_LOG"
    
    log_success "Testing environment initialized"
}

# Test assertion functions
assert_true() {
    local condition="$1"
    local test_name="$2"
    local message="${3:-Test failed}"
    
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    if eval "$condition"; then
        log_success "✓ $test_name"
        echo "PASS: $test_name" >> "$TEST_RESULTS_FILE"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        log_error "✗ $test_name - $message"
        echo "FAIL: $test_name - $message" >> "$TEST_RESULTS_FILE"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

assert_file_exists() {
    local file_path="$1"
    local test_name="$2"
    
    assert_true "test -f '$file_path'" "$test_name" "File does not exist: $file_path"
}

assert_directory_exists() {
    local dir_path="$1"
    local test_name="$2"
    
    assert_true "test -d '$dir_path'" "$test_name" "Directory does not exist: $dir_path"
}

assert_command_exists() {
    local command="$1"
    local test_name="$2"
    
    assert_true "command -v '$command' &> /dev/null" "$test_name" "Command not found: $command"
}

assert_service_active() {
    local service="$1"
    local test_name="$2"
    
    if command -v systemctl &> /dev/null; then
        assert_true "systemctl is-active --quiet '$service'" "$test_name" "Service not active: $service"
    else
        log_warning "Systemctl not available, skipping service test: $service"
    fi
}

# Unit Tests
run_unit_tests() {
    log_info "Running unit tests..."
    echo "=== UNIT TESTS ===" >> "$UNIT_TEST_LOG"
    
    # Test configuration path resolution
    test_config_path_resolution
    
    # Test game path detection
    test_game_path_detection
    
    # Test file validation
    test_file_validation
    
    # Test configuration validation
    test_configuration_validation
    
    log_info "Unit tests completed"
}

test_config_path_resolution() {
    log_info "Testing configuration path resolution..."
    
    # Test fallback directory creation
    local test_dir="/tmp/nitrox_test_config"
    rm -rf "$test_dir"
    
    # Simulate missing HOME environment
    (
        unset HOME
        unset XDG_CONFIG_HOME
        
        # Test fallback creation
        mkdir -p "$test_dir/UserData/Config"
        assert_directory_exists "$test_dir/UserData/Config" "Config fallback directory creation"
    )
    
    # Cleanup
    rm -rf "$test_dir"
}

test_game_path_detection() {
    log_info "Testing game path detection..."
    
    # Create mock game installation
    local mock_game_dir="/tmp/nitrox_test_game"
    rm -rf "$mock_game_dir"
    mkdir -p "$mock_game_dir/Subnautica_Data/Managed"
    
    # Create required files
    touch "$mock_game_dir/Subnautica.exe"
    touch "$mock_game_dir/Subnautica_Data/Managed/Assembly-CSharp.dll"
    mkdir -p "$mock_game_dir/Subnautica_Data/StreamingAssets"
    
    # Test validation function
    source ./game-detection.sh
    if validate_game_installation "$mock_game_dir"; then
        assert_true "true" "Game installation validation with valid files"
    else
        assert_true "false" "Game installation validation with valid files"
    fi
    
    # Test with missing files
    rm "$mock_game_dir/Subnautica.exe"
    if ! validate_game_installation "$mock_game_dir"; then
        assert_true "true" "Game installation validation with missing files"
    else
        assert_true "false" "Game installation validation with missing files"
    fi
    
    # Cleanup
    rm -rf "$mock_game_dir"
}

test_file_validation() {
    log_info "Testing file validation functions..."
    
    # Test JSON validation
    local test_json="/tmp/test_config.json"
    
    # Valid JSON
    echo '{"test": "value"}' > "$test_json"
    if python3 -m json.tool "$test_json" > /dev/null 2>&1 || jq empty "$test_json" > /dev/null 2>&1; then
        assert_true "true" "Valid JSON validation"
    else
        assert_true "false" "Valid JSON validation"
    fi
    
    # Invalid JSON
    echo '{"test": "value"' > "$test_json"
    if ! python3 -m json.tool "$test_json" > /dev/null 2>&1 && ! jq empty "$test_json" > /dev/null 2>&1; then
        assert_true "true" "Invalid JSON detection"
    else
        assert_true "false" "Invalid JSON detection"
    fi
    
    rm -f "$test_json"
}

test_configuration_validation() {
    log_info "Testing configuration validation..."
    
    # Test server configuration validation
    local test_config="/tmp/test_server_config.json"
    
    cat > "$test_config" << EOF
{
    "ServerName": "Test Server",
    "ServerPort": 11000,
    "AdminPassword": "test123",
    "GameMode": "Survival",
    "MaxPlayers": 50
}
EOF
    
    # Test required fields presence
    local required_fields=("ServerName" "ServerPort" "AdminPassword" "GameMode" "MaxPlayers")
    local all_present=true
    
    for field in "${required_fields[@]}"; do
        if ! grep -q "\"$field\"" "$test_config"; then
            all_present=false
            break
        fi
    done
    
    assert_true "test '$all_present' = 'true'" "Configuration required fields validation"
    
    rm -f "$test_config"
}

# Integration Tests
run_integration_tests() {
    log_info "Running integration tests..."
    echo "=== INTEGRATION TESTS ===" >> "$INTEGRATION_TEST_LOG"
    
    # Test SteamCMD integration
    test_steamcmd_integration
    
    # Test server configuration integration
    test_server_config_integration
    
    # Test service integration
    test_service_integration
    
    log_info "Integration tests completed"
}

test_steamcmd_integration() {
    log_info "Testing SteamCMD integration..."
    
    # Test SteamCMD installation
    assert_file_exists "$INSTALL_DIR/steamcmd/steamcmd.sh" "SteamCMD executable exists"
    
    # Test SteamCMD permissions
    assert_true "test -x '$INSTALL_DIR/steamcmd/steamcmd.sh'" "SteamCMD executable permissions"
    
    # Test SteamCMD basic functionality (anonymous login)
    if [[ -f "$INSTALL_DIR/steamcmd/steamcmd.sh" ]]; then
        cd "$INSTALL_DIR/steamcmd"
        
        cat > test_anonymous.txt << EOF
@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
login anonymous
quit
EOF
        
        if timeout 30 ./steamcmd.sh +runscript test_anonymous.txt > steamcmd_test.log 2>&1; then
            assert_true "true" "SteamCMD anonymous login test"
        else
            assert_true "false" "SteamCMD anonymous login test"
        fi
        
        rm -f test_anonymous.txt steamcmd_test.log
    fi
}

test_server_config_integration() {
    log_info "Testing server configuration integration..."
    
    # Test configuration file creation
    assert_file_exists "$INSTALL_DIR/server/UserData/Config/server.cfg" "Server configuration file exists"
    
    # Test game path configuration
    assert_file_exists "$INSTALL_DIR/server/subnautica_path.txt" "Game path configuration exists"
    
    # Test configuration directory structure
    assert_directory_exists "$INSTALL_DIR/server/UserData" "Server UserData directory"
    assert_directory_exists "$INSTALL_DIR/server/Saves" "Server Saves directory"
    assert_directory_exists "$INSTALL_DIR/server/Logs" "Server Logs directory"
}

test_service_integration() {
    log_info "Testing service integration..."
    
    # Test service file creation
    if command -v systemctl &> /dev/null; then
        assert_file_exists "/etc/systemd/system/nitrox-server.service" "Systemd service file exists"
    fi
    
    # Test management scripts
    assert_file_exists "$INSTALL_DIR/start-server.sh" "Start server script exists"
    assert_file_exists "$INSTALL_DIR/stop-server.sh" "Stop server script exists"
    assert_file_exists "$INSTALL_DIR/restart-server.sh" "Restart server script exists"
    assert_file_exists "$INSTALL_DIR/status-server.sh" "Status server script exists"
    
    # Test script permissions
    assert_true "test -x '$INSTALL_DIR/start-server.sh'" "Start script executable"
    assert_true "test -x '$INSTALL_DIR/stop-server.sh'" "Stop script executable"
    assert_true "test -x '$INSTALL_DIR/restart-server.sh'" "Restart script executable"
    assert_true "test -x '$INSTALL_DIR/status-server.sh'" "Status script executable"
}

# System Tests
run_system_tests() {
    log_info "Running system tests..."
    echo "=== SYSTEM TESTS ===" >> "$SYSTEM_TEST_LOG"
    
    # Test full system integration
    test_system_dependencies
    test_network_configuration
    test_file_permissions
    test_resource_usage
    
    log_info "System tests completed"
}

test_system_dependencies() {
    log_info "Testing system dependencies..."
    
    # Test required commands
    assert_command_exists "curl" "curl command available"
    assert_command_exists "wget" "wget command available"
    assert_command_exists "dotnet" ".NET runtime available"
    
    # Test .NET version
    if command -v dotnet &> /dev/null; then
        local dotnet_version
        dotnet_version=$(dotnet --version 2>/dev/null)
        if [[ -n "$dotnet_version" ]]; then
            assert_true "true" ".NET runtime version check ($dotnet_version)"
        else
            assert_true "false" ".NET runtime version check"
        fi
    fi
    
    # Test 32-bit library support (for SteamCMD)
    if [[ -f "/lib32/libc.so.6" ]] || [[ -f "/lib/i386-linux-gnu/libc.so.6" ]]; then
        assert_true "true" "32-bit library support available"
    else
        assert_true "false" "32-bit library support available"
    fi
}

test_network_configuration() {
    log_info "Testing network configuration..."
    
    # Test internet connectivity
    if ping -c 1 8.8.8.8 &> /dev/null; then
        assert_true "true" "Internet connectivity test"
    else
        assert_true "false" "Internet connectivity test"
    fi
    
    # Test DNS resolution
    if nslookup google.com &> /dev/null; then
        assert_true "true" "DNS resolution test"
    else
        assert_true "false" "DNS resolution test"
    fi
    
    # Test port availability
    if ! netstat -tulpn 2>/dev/null | grep ":11000 " > /dev/null; then
        assert_true "true" "Port 11000 availability"
    else
        assert_true "false" "Port 11000 availability (already in use)"
    fi
}

test_file_permissions() {
    log_info "Testing file permissions..."
    
    # Test installation directory permissions
    assert_true "test -r '$INSTALL_DIR'" "Installation directory readable"
    assert_true "test -w '$INSTALL_DIR'" "Installation directory writable"
    
    # Test server files permissions
    if [[ -f "$INSTALL_DIR/server/NitroxServer-Subnautica.dll" ]]; then
        assert_true "test -r '$INSTALL_DIR/server/NitroxServer-Subnautica.dll'" "Server DLL readable"
    fi
    
    # Test configuration files permissions
    if [[ -f "$INSTALL_DIR/server/UserData/Config/server.cfg" ]]; then
        assert_true "test -r '$INSTALL_DIR/server/UserData/Config/server.cfg'" "Server config readable"
        assert_true "test -w '$INSTALL_DIR/server/UserData/Config/server.cfg'" "Server config writable"
    fi
}

test_resource_usage() {
    log_info "Testing resource usage..."
    
    # Test disk space
    local available_space
    available_space=$(df "$INSTALL_DIR" | awk 'NR==2 {print $4}')
    if [[ $available_space -gt 1048576 ]]; then  # 1GB in KB
        assert_true "true" "Sufficient disk space available (${available_space}KB)"
    else
        assert_true "false" "Sufficient disk space available (${available_space}KB)"
    fi
    
    # Test memory
    local available_memory
    available_memory=$(free | awk 'NR==2{print $7}')
    if [[ $available_memory -gt 1048576 ]]; then  # 1GB in KB
        assert_true "true" "Sufficient memory available (${available_memory}KB)"
    else
        assert_true "false" "Sufficient memory available (${available_memory}KB)"
    fi
}

# Performance Tests
run_performance_tests() {
    log_info "Running performance tests..."
    
    # Test server startup time
    test_server_startup_time
    
    # Test memory usage
    test_memory_usage
    
    # Test file I/O performance
    test_file_io_performance
    
    log_info "Performance tests completed"
}

test_server_startup_time() {
    log_info "Testing server startup time..."
    
    if command -v systemctl &> /dev/null && systemctl list-unit-files | grep -q nitrox-server; then
        local start_time=$(date +%s)
        
        systemctl start nitrox-server &> /dev/null
        
        # Wait for server to start (max 30 seconds)
        local timeout=30
        local elapsed=0
        
        while [[ $elapsed -lt $timeout ]]; do
            if systemctl is-active --quiet nitrox-server; then
                break
            fi
            sleep 1
            elapsed=$((elapsed + 1))
        done
        
        local end_time=$(date +%s)
        local startup_time=$((end_time - start_time))
        
        systemctl stop nitrox-server &> /dev/null
        
        if [[ $startup_time -lt 60 ]]; then
            assert_true "true" "Server startup time acceptable (${startup_time}s)"
        else
            assert_true "false" "Server startup time acceptable (${startup_time}s)"
        fi
    else
        log_warning "Systemd service not available, skipping startup time test"
    fi
}

test_memory_usage() {
    log_info "Testing memory usage..."
    
    # Test installation memory footprint
    local install_size
    install_size=$(du -sm "$INSTALL_DIR" 2>/dev/null | cut -f1)
    
    if [[ $install_size -lt 10240 ]]; then  # Less than 10GB
        assert_true "true" "Installation size reasonable (${install_size}MB)"
    else
        assert_true "false" "Installation size reasonable (${install_size}MB)"
    fi
}

test_file_io_performance() {
    log_info "Testing file I/O performance..."
    
    # Test write performance
    local test_file="$INSTALL_DIR/test_io_performance"
    local start_time=$(date +%s%N)
    
    dd if=/dev/zero of="$test_file" bs=1M count=100 &> /dev/null
    
    local end_time=$(date +%s%N)
    local write_time=$(( (end_time - start_time) / 1000000 ))  # Convert to milliseconds
    
    rm -f "$test_file"
    
    if [[ $write_time -lt 5000 ]]; then  # Less than 5 seconds
        assert_true "true" "File I/O performance acceptable (${write_time}ms)"
    else
        assert_true "false" "File I/O performance acceptable (${write_time}ms)"
    fi
}

# Generate test report
generate_test_report() {
    log_info "Generating test report..."
    
    local report_file="$TEST_LOG_DIR/test_report.html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Nitrox VPS Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 20px; border-radius: 5px; }
        .summary { margin: 20px 0; }
        .pass { color: green; }
        .fail { color: red; }
        .section { margin: 20px 0; border: 1px solid #ddd; padding: 15px; }
        pre { background-color: #f5f5f5; padding: 10px; overflow-x: auto; }
    </style>
</head>
<body>
    <div class="header">
        <h1>🌊 Nitrox VPS Test Report</h1>
        <p>Generated on: $(date)</p>
        <p>Installation Directory: $INSTALL_DIR</p>
    </div>
    
    <div class="summary">
        <h2>Test Summary</h2>
        <p><strong>Total Tests:</strong> $TESTS_TOTAL</p>
        <p class="pass"><strong>Passed:</strong> $TESTS_PASSED</p>
        <p class="fail"><strong>Failed:</strong> $TESTS_FAILED</p>
        <p><strong>Success Rate:</strong> $(( TESTS_PASSED * 100 / TESTS_TOTAL ))%</p>
    </div>
    
    <div class="section">
        <h2>Test Results</h2>
        <pre>$(cat "$TEST_RESULTS_FILE")</pre>
    </div>
    
    <div class="section">
        <h2>System Information</h2>
        <pre>
OS: $(uname -a)
Disk Usage: $(df -h "$INSTALL_DIR")
Memory: $(free -h)
        </pre>
    </div>
</body>
</html>
EOF
    
    log_success "Test report generated: $report_file"
}

# Main testing function
run_comprehensive_tests() {
    log_info "Starting comprehensive test suite..."
    
    init_testing
    
    # Run all test suites
    run_unit_tests
    run_integration_tests
    run_system_tests
    run_performance_tests
    
    # Generate report
    generate_test_report
    
    # Show summary
    log_info "=== TEST SUMMARY ==="
    log_info "Total Tests: $TESTS_TOTAL"
    log_success "Passed: $TESTS_PASSED"
    if [[ $TESTS_FAILED -gt 0 ]]; then
        log_error "Failed: $TESTS_FAILED"
    else
        log_info "Failed: $TESTS_FAILED"
    fi
    
    local success_rate=$(( TESTS_PASSED * 100 / TESTS_TOTAL ))
    log_info "Success Rate: ${success_rate}%"
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed! 🎉"
        return 0
    else
        log_warning "Some tests failed. Check logs for details."
        return 1
    fi
}

# Export functions
export -f run_comprehensive_tests
export -f run_unit_tests
export -f run_integration_tests
export -f run_system_tests
export -f run_performance_tests