#!/bin/bash

# Health check script for Nitrox Docker container
# Returns 0 if healthy, 1 if unhealthy

# Check if server process is running
if ! pgrep -f "NitroxServer-Subnautica.dll" > /dev/null; then
    echo "UNHEALTHY: Nitrox server process not found"
    exit 1
fi

# Check if server port is listening
if ! netstat -ln | grep -q ":${NITROX_SERVER_PORT:-11000}.*UDP"; then
    echo "UNHEALTHY: Server port ${NITROX_SERVER_PORT:-11000} not listening"
    exit 1
fi

# Check if game files are still accessible
if [ ! -f "$NITROX_GAME_FILES_PATH/Subnautica.exe" ]; then
    echo "UNHEALTHY: Game files not accessible"
    exit 1
fi

# Check if save directory is writable
if [ ! -w "$NITROX_SAVE_DATA_PATH" ]; then
    echo "UNHEALTHY: Save directory not writable"
    exit 1
fi

# All checks passed
echo "HEALTHY: All systems operational"
exit 0