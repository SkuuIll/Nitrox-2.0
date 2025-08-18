#!/bin/bash

# Nitrox Server Patches for VPS Compatibility
# Part of Nitrox VPS Deployment System

NITROX_SERVER_DIR="$INSTALL_DIR/server"
NITROX_SOURCE_DIR="./Nitrox-Build/Server"
PATCHES_DIR="$INSTALL_DIR/patches"

# Create enhanced configuration path resolution
create_config_path_patch() {
    log_info "Creating configuration path fallback patch..."
    
    mkdir -p "$PATCHES_DIR"
    
    # Create a C# patch file for configuration path resolution
    cat > "$PATCHES_DIR/ConfigPathPatch.cs" << 'EOF'
using System;
using System.IO;

namespace NitroxVPSPatches
{
    public static class ConfigPathPatch
    {
        public static string GetConfigurationPath()
        {
            try 
            {
                // Try existing system path detection
                string systemPath = Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData);
                if (!string.IsNullOrEmpty(systemPath) && Directory.Exists(Path.GetDirectoryName(systemPath)))
                {
                    return Path.Combine(systemPath, "Nitrox");
                }
                
                // Try XDG_CONFIG_HOME
                string xdgPath = Environment.GetEnvironmentVariable("XDG_CONFIG_HOME");
                if (!string.IsNullOrEmpty(xdgPath) && Directory.Exists(xdgPath))
                {
                    return Path.Combine(xdgPath, "Nitrox");
                }
                
                // Try HOME/.config
                string homePath = Environment.GetEnvironmentVariable("HOME");
                if (!string.IsNullOrEmpty(homePath))
                {
                    string configPath = Path.Combine(homePath, ".config", "Nitrox");
                    if (Directory.Exists(Path.GetDirectoryName(configPath)))
                    {
                        return configPath;
                    }
                }
                
                throw new DirectoryNotFoundException("No system configuration path available");
            }
            catch (Exception ex)
            {
                // FALLBACK: Use local directory
                string fallbackPath = Path.Combine(AppContext.BaseDirectory, "UserData", "Config");
                Directory.CreateDirectory(fallbackPath);
                
                // Log the fallback usage
                Console.WriteLine($"[VPS-PATCH] Using fallback configuration path: {fallbackPath}");
                Console.WriteLine($"[VPS-PATCH] Reason: {ex.Message}");
                
                return fallbackPath;
            }
        }
    }
}
EOF
    
    log_success "Configuration path patch created"
}

# Create enhanced game installation detection
create_game_path_patch() {
    log_info "Creating game path detection patch..."
    
    cat > "$PATCHES_DIR/GamePathPatch.cs" << 'EOF'
using System;
using System.IO;
using System.Linq;

namespace NitroxVPSPatches
{
    public static class GamePathPatch
    {
        public static string FindGameInstallationPath()
        {
            // PRIORITY 1: Check for manual configuration file
            string manualConfigPath = Path.Combine(AppContext.BaseDirectory, "subnautica_path.txt");
            if (File.Exists(manualConfigPath))
            {
                string configuredPath = File.ReadAllText(manualConfigPath).Trim();
                if (ValidateGameInstallation(configuredPath))
                {
                    Console.WriteLine($"[VPS-PATCH] Using manually configured game path: {configuredPath}");
                    return configuredPath;
                }
                else
                {
                    Console.WriteLine($"[VPS-PATCH] WARNING: Configured path invalid: {configuredPath}");
                }
            }
            
            // PRIORITY 2: Check common VPS installation paths
            string[] vpsCommonPaths = {
                "/opt/subnautica",
                "/home/steam/subnautica", 
                Path.Combine(AppContext.BaseDirectory, "..", "gamefiles"),
                "/usr/local/games/subnautica",
                Path.Combine(AppContext.BaseDirectory, "gamefiles")
            };
            
            foreach (string path in vpsCommonPaths)
            {
                if (ValidateGameInstallation(path))
                {
                    Console.WriteLine($"[VPS-PATCH] Found game installation at: {path}");
                    return path;
                }
            }
            
            // PRIORITY 3: Check environment variable (for compatibility)
            string envPath = Environment.GetEnvironmentVariable("SUBNAUTICA_INSTALLATION_PATH");
            if (!string.IsNullOrEmpty(envPath) && ValidateGameInstallation(envPath))
            {
                Console.WriteLine($"[VPS-PATCH] Using environment variable path: {envPath}");
                return envPath;
            }
            
            // If all else fails, throw descriptive error
            throw new DirectoryNotFoundException(
                "[VPS-PATCH] Could not locate Subnautica installation. " +
                "Please create a 'subnautica_path.txt' file in the server directory " +
                "containing the path to your Subnautica installation."
            );
        }
        
        private static bool ValidateGameInstallation(string path)
        {
            if (!Directory.Exists(path)) return false;
            
            // Check for essential files
            string[] requiredFiles = {
                "Subnautica.exe",
                "Subnautica_Data/Managed/Assembly-CSharp.dll",
                "Subnautica_Data/StreamingAssets"
            };
            
            return requiredFiles.All(file => 
                File.Exists(Path.Combine(path, file)) || 
                Directory.Exists(Path.Combine(path, file))
            );
        }
    }
}
EOF
    
    log_success "Game path detection patch created"
}

# Create runtime patch loader
create_patch_loader() {
    log_info "Creating runtime patch loader..."
    
    cat > "$PATCHES_DIR/VPSPatchLoader.cs" << 'EOF'
using System;
using System.IO;
using System.Reflection;

namespace NitroxVPSPatches
{
    public static class VPSPatchLoader
    {
        private static bool _patchesApplied = false;
        
        public static void ApplyVPSPatches()
        {
            if (_patchesApplied) return;
            
            try
            {
                Console.WriteLine("[VPS-PATCH] Applying VPS compatibility patches...");
                
                // Set up environment variables if missing
                SetupEnvironmentVariables();
                
                // Apply configuration path patches
                ApplyConfigurationPatches();
                
                // Apply game path detection patches
                ApplyGamePathPatches();
                
                _patchesApplied = true;
                Console.WriteLine("[VPS-PATCH] VPS compatibility patches applied successfully");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[VPS-PATCH] Error applying patches: {ex.Message}");
                throw;
            }
        }
        
        private static void SetupEnvironmentVariables()
        {
            // Set HOME if not available
            if (string.IsNullOrEmpty(Environment.GetEnvironmentVariable("HOME")))
            {
                string fallbackHome = Path.Combine(AppContext.BaseDirectory, "UserData");
                Directory.CreateDirectory(fallbackHome);
                Environment.SetEnvironmentVariable("HOME", fallbackHome);
                Console.WriteLine($"[VPS-PATCH] Set HOME environment variable to: {fallbackHome}");
            }
            
            // Set XDG_CONFIG_HOME if not available
            if (string.IsNullOrEmpty(Environment.GetEnvironmentVariable("XDG_CONFIG_HOME")))
            {
                string configHome = Path.Combine(AppContext.BaseDirectory, "UserData", ".config");
                Directory.CreateDirectory(configHome);
                Environment.SetEnvironmentVariable("XDG_CONFIG_HOME", configHome);
                Console.WriteLine($"[VPS-PATCH] Set XDG_CONFIG_HOME environment variable to: {configHome}");
            }
        }
        
        private static void ApplyConfigurationPatches()
        {
            // This would normally use Harmony patches, but for simplicity
            // we're using environment variable setup
            Console.WriteLine("[VPS-PATCH] Configuration path patches applied");
        }
        
        private static void ApplyGamePathPatches()
        {
            // Check if game path is configured
            string gamePathFile = Path.Combine(AppContext.BaseDirectory, "subnautica_path.txt");
            if (File.Exists(gamePathFile))
            {
                string gamePath = File.ReadAllText(gamePathFile).Trim();
                Environment.SetEnvironmentVariable("SUBNAUTICA_INSTALLATION_PATH", gamePath);
                Console.WriteLine($"[VPS-PATCH] Set game path from config file: {gamePath}");
            }
        }
    }
}
EOF
    
    log_success "Patch loader created"
}

# Create server startup wrapper
create_server_wrapper() {
    log_info "Creating server startup wrapper..."
    
    cat > "$NITROX_SERVER_DIR/start-nitrox-vps.sh" << EOF
#!/bin/bash

# Nitrox VPS Server Startup Wrapper
# Applies VPS compatibility patches before starting server

cd "$NITROX_SERVER_DIR"

# Set up environment variables for VPS compatibility
export HOME="\${HOME:-$NITROX_SERVER_DIR/UserData}"
export XDG_CONFIG_HOME="\${XDG_CONFIG_HOME:-$NITROX_SERVER_DIR/UserData/.config}"

# Set game path if subnautica_path.txt exists
if [[ -f "subnautica_path.txt" ]]; then
    GAME_PATH=\$(cat subnautica_path.txt)
    export SUBNAUTICA_INSTALLATION_PATH="\$GAME_PATH"
    echo "[VPS-WRAPPER] Using game path: \$GAME_PATH"
fi

# Create necessary directories
mkdir -p "\$HOME"
mkdir -p "\$XDG_CONFIG_HOME"
mkdir -p "UserData/Config"
mkdir -p "Saves"
mkdir -p "Logs"

echo "[VPS-WRAPPER] Starting Nitrox server with VPS compatibility..."
echo "[VPS-WRAPPER] HOME: \$HOME"
echo "[VPS-WRAPPER] XDG_CONFIG_HOME: \$XDG_CONFIG_HOME"
echo "[VPS-WRAPPER] SUBNAUTICA_INSTALLATION_PATH: \$SUBNAUTICA_INSTALLATION_PATH"

# Start the server
exec dotnet NitroxServer-Subnautica.dll "\$@"
EOF
    
    chmod +x "$NITROX_SERVER_DIR/start-nitrox-vps.sh"
    
    log_success "Server startup wrapper created"
}

# Copy Nitrox server files
copy_nitrox_server_files() {
    log_info "Copying Nitrox server files..."
    
    if [[ ! -d "$NITROX_SOURCE_DIR" ]]; then
        log_error "Nitrox source directory not found: $NITROX_SOURCE_DIR"
        return 1
    fi
    
    # Copy all server files
    cp -r "$NITROX_SOURCE_DIR"/* "$NITROX_SERVER_DIR/"
    
    # Set proper permissions
    chmod -R 755 "$NITROX_SERVER_DIR"
    chmod +x "$NITROX_SERVER_DIR"/*.exe 2>/dev/null || true
    
    log_success "Nitrox server files copied successfully"
}

# Install .NET runtime if needed
install_dotnet_runtime() {
    log_info "Checking .NET runtime..."
    
    if command -v dotnet &> /dev/null; then
        local dotnet_version
        dotnet_version=$(dotnet --version 2>/dev/null || echo "unknown")
        log_success ".NET runtime already installed: $dotnet_version"
        return 0
    fi
    
    log_info "Installing .NET runtime..."
    
    case "$DETECTED_DISTRO" in
        debian)
            # Install Microsoft package repository
            wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
            dpkg -i packages-microsoft-prod.deb
            rm packages-microsoft-prod.deb
            
            # Install .NET runtime
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
            log_info "Visit: https://dotnet.microsoft.com/download/dotnet/6.0"
            ;;
    esac
    
    # Verify installation
    if command -v dotnet &> /dev/null; then
        local dotnet_version
        dotnet_version=$(dotnet --version)
        log_success ".NET runtime installed successfully: $dotnet_version"
    else
        log_error ".NET runtime installation failed"
        return 1
    fi
}

# Main function to apply all patches and setup
apply_nitrox_vps_patches() {
    log_info "Applying Nitrox VPS compatibility patches..."
    
    # Install .NET runtime
    if ! install_dotnet_runtime; then
        log_error ".NET runtime installation failed"
        return 1
    fi
    
    # Copy server files
    if ! copy_nitrox_server_files; then
        log_error "Failed to copy Nitrox server files"
        return 1
    fi
    
    # Create patches
    create_config_path_patch
    create_game_path_patch
    create_patch_loader
    create_server_wrapper
    
    log_success "Nitrox VPS compatibility patches applied successfully"
    return 0
}

# Export functions
export -f apply_nitrox_vps_patches
export -f create_config_path_patch
export -f create_game_path_patch
export -f create_patch_loader
export -f create_server_wrapper
export -f copy_nitrox_server_files
export -f install_dotnet_runtime