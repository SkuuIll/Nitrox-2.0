#!/bin/bash
set -e

echo "=== Downloading Subnautica Game Files ==="

# Subnautica Steam App ID
SUBNAUTICA_APP_ID=264710

# Validate Steam credentials
if [ -z "$STEAM_USERNAME" ] || [ -z "$STEAM_PASSWORD" ]; then
    echo "ERROR: Steam credentials required"
    echo "Please set STEAM_USERNAME and STEAM_PASSWORD environment variables"
    exit 1
fi

echo "Steam Username: $STEAM_USERNAME"
echo "Target Directory: $NITROX_GAME_FILES_PATH"

# Create temporary script for SteamCMD
STEAMCMD_SCRIPT="/tmp/download_subnautica.txt"
cat > "$STEAMCMD_SCRIPT" << EOF
@ShutdownOnFailedCommand 1
@NoPromptForPassword 1
login $STEAM_USERNAME $STEAM_PASSWORD
force_install_dir $NITROX_GAME_FILES_PATH
app_update $SUBNAUTICA_APP_ID validate
quit
EOF

echo "Starting SteamCMD download..."
echo "This may take several minutes depending on your connection..."

# Run SteamCMD with retry logic
MAX_RETRIES=3
RETRY_COUNT=0

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    echo "Download attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES"
    
    if /app/steamcmd/steamcmd.sh +runscript "$STEAMCMD_SCRIPT"; then
        echo "SteamCMD download completed successfully"
        break
    else
        RETRY_COUNT=$((RETRY_COUNT + 1))
        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "Download failed, retrying in 30 seconds..."
            sleep 30
        else
            echo "ERROR: Failed to download game files after $MAX_RETRIES attempts"
            rm -f "$STEAMCMD_SCRIPT"
            exit 1
        fi
    fi
done

# Clean up
rm -f "$STEAMCMD_SCRIPT"

# Verify download
echo "Verifying downloaded files..."

if [ ! -f "$NITROX_GAME_FILES_PATH/Subnautica.exe" ]; then
    echo "ERROR: Subnautica.exe not found after download"
    exit 1
fi

if [ ! -d "$NITROX_GAME_FILES_PATH/Subnautica_Data" ]; then
    echo "ERROR: Subnautica_Data directory not found after download"
    exit 1
fi

if [ ! -f "$NITROX_GAME_FILES_PATH/Subnautica_Data/Managed/Assembly-CSharp.dll" ]; then
    echo "ERROR: Required game assemblies not found after download"
    exit 1
fi

# Calculate and display download size
DOWNLOAD_SIZE=$(du -sh "$NITROX_GAME_FILES_PATH" | cut -f1)
echo "Download completed successfully!"
echo "Total size: $DOWNLOAD_SIZE"
echo "Game files are ready for Nitrox server"