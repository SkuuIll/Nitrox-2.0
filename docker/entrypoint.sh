#!/bin/bash
set -e

echo "=== Nitrox Docker Server Starting ==="
echo "Server Name: $NITROX_SERVER_NAME"
echo "Server Port: $NITROX_SERVER_PORT"
echo "Game Mode: $NITROX_GAME_MODE"
echo "Steam Download Enabled: $NITROX_ENABLE_STEAM_DOWNLOAD"

# Function to handle shutdown gracefully
shutdown_handler() {
    echo "Received shutdown signal, stopping server gracefully..."
    if [ ! -z "$SERVER_PID" ]; then
        kill -TERM "$SERVER_PID" 2>/dev/null || true
        wait "$SERVER_PID" 2>/dev/null || true
    fi
    echo "Server stopped."
    exit 0
}

# Set up signal handlers
trap shutdown_handler SIGTERM SIGINT SIGQUIT SIGHUP

# Validate required directories
echo "Validating directory structure..."
mkdir -p "$NITROX_GAME_FILES_PATH" "$NITROX_SAVE_DATA_PATH" "$NITROX_CONFIG_PATH" /app/logs

# Check if game files exist or need to be downloaded
if [ "$NITROX_ENABLE_STEAM_DOWNLOAD" = "true" ]; then
    echo "Checking Subnautica game files..."
    
    # Check if Subnautica.exe exists
    if [ ! -f "$NITROX_GAME_FILES_PATH/Subnautica.exe" ]; then
        echo "Game files not found, attempting to download..."
        
        if [ -z "$STEAM_USERNAME" ] || [ -z "$STEAM_PASSWORD" ]; then
            echo "ERROR: Steam credentials required for game file download"
            echo "Please set STEAM_USERNAME and STEAM_PASSWORD environment variables"
            exit 1
        fi
        
        # Download game files using SteamCMD
        /app/download-game.sh
        
        if [ $? -ne 0 ]; then
            echo "ERROR: Failed to download game files"
            exit 1
        fi
    else
        echo "Game files found at $NITROX_GAME_FILES_PATH"
    fi
else
    echo "Steam download disabled, checking for manually provided game files..."
    
    if [ ! -f "$NITROX_GAME_FILES_PATH/Subnautica.exe" ]; then
        echo "ERROR: Game files not found and Steam download is disabled"
        echo "Please mount game files to $NITROX_GAME_FILES_PATH or enable Steam download"
        exit 1
    fi
fi

# Validate game files
echo "Validating game files..."
if [ ! -f "$NITROX_GAME_FILES_PATH/Subnautica_Data/Managed/Assembly-CSharp.dll" ]; then
    echo "ERROR: Invalid game files - missing required assemblies"
    exit 1
fi

echo "Game files validation successful"

# Create server configuration
echo "Configuring Nitrox server..."

# Generate server configuration file
cat > "$NITROX_CONFIG_PATH/server.cfg" << EOF
{
  "ServerName": "$NITROX_SERVER_NAME",
  "ServerPort": $NITROX_SERVER_PORT,
  "ServerPassword": "$NITROX_SERVER_PASSWORD",
  "AdminPassword": "$NITROX_ADMIN_PASSWORD",
  "GameMode": "$NITROX_GAME_MODE",
  "DisableAutoSave": $NITROX_DISABLE_AUTO_SAVE,
  "SaveInterval": $NITROX_SAVE_INTERVAL,
  "MaxBackups": $NITROX_MAX_BACKUPS,
  "SerializerMode": "PROTOBUF",
  "CreateFullEntityCache": false,
  "DisableAutoBackup": false
}
EOF

echo "Server configuration created"

# Start the Nitrox server
echo "Starting Nitrox server..."
echo "Game files path: $NITROX_GAME_FILES_PATH"
echo "Save data path: $NITROX_SAVE_DATA_PATH"

cd /app/server

# Start server with game files path as argument
dotnet NitroxServer-Subnautica.dll "$NITROX_GAME_FILES_PATH" --embedded &
SERVER_PID=$!

echo "Nitrox server started with PID: $SERVER_PID"
echo "Server is ready for connections on port $NITROX_SERVER_PORT"

# Wait for server process
wait "$SERVER_PID"