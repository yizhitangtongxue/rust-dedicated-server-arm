#!/bin/bash
set -e

# Default variables
RUST_SERVER_IDENTITY="${RUST_SERVER_IDENTITY:-my_server}"
RUST_SERVER_PORT="${RUST_SERVER_PORT:-28015}"
RUST_SERVER_QUERYPORT="${RUST_SERVER_QUERYPORT:-28016}"
RUST_RCON_PORT="${RUST_RCON_PORT:-28017}"
RUST_RCON_PASSWORD="${RUST_RCON_PASSWORD:-docker}"
RUST_SERVER_NAME="${RUST_SERVER_NAME:-Rust Server Docker}"
RUST_SERVER_DESCRIPTION="${RUST_SERVER_DESCRIPTION:-Powered by Box64 on ARM}"
RUST_SERVER_URL="${RUST_SERVER_URL:-}"
RUST_SERVER_BANNER_URL="${RUST_SERVER_BANNER_URL:-}"
RUST_SERVER_WORLDSIZE="${RUST_SERVER_WORLDSIZE:-3000}"
RUST_SERVER_MAXPLAYERS="${RUST_SERVER_MAXPLAYERS:-50}"
RUST_SERVER_SAVEINTERVAL="${RUST_SERVER_SAVEINTERVAL:-600}"
RUST_SERVER_SEED="${RUST_SERVER_SEED:-}" # Empty means random
RUST_APP_UPDATE="${RUST_APP_UPDATE:-1}"

echo ">>> Starting Rust Server on ARM64 (Box64/Box86 environment)"
echo ">>> Host Architecture: $(uname -m)"

# Update Rust Server
if [ "${RUST_APP_UPDATE}" = "1" ]; then
    echo ">>> Updating Rust Server (AppID 258550)..."
    # Use box86 to run the 32-bit steamcmd
    # Note: steamcmd itself might try to download a 64-bit version if it detects a 64-bit OS, 
    # but the initial bootstrap is usually 32-bit.
    # We force the platform if needed, but standard update usually works.
    
    cd /home/steam/steamcmd
    
    # Run steamcmd with box86
    # We might need to specific +@sSteamCmdForcePlatformType linux
    box86 ./steamcmd.sh \
        +@sSteamCmdForcePlatformType linux \
        +force_install_dir /home/steam/rust \
        +login anonymous \
        +app_update 258550 validate \
        +quit
        
    echo ">>> Update completed."
fi

# Prepare to run Server
cd /home/steam/rust

# Check for required library fixes (sometimes needed for Rust)
# Currently handled by Box64 dynamic wrapping, but if specific libs are missing, we might need to symlink them.

echo ">>> Launching RustDedicated via Box64..."

# Construct launch arguments
ARGS="-batchmode"
ARGS="$ARGS +server.ip 0.0.0.0"
ARGS="$ARGS +server.port $RUST_SERVER_PORT"
ARGS="$ARGS +server.queryport $RUST_SERVER_QUERYPORT"
ARGS="$ARGS +rcon.port $RUST_RCON_PORT"
ARGS="$ARGS +rcon.password \"$RUST_RCON_PASSWORD\""
ARGS="$ARGS +rcon.web 1"
ARGS="$ARGS +server.identity \"$RUST_SERVER_IDENTITY\""
ARGS="$ARGS +server.hostname \"$RUST_SERVER_NAME\""
ARGS="$ARGS +server.description \"$RUST_SERVER_DESCRIPTION\""
ARGS="$ARGS +server.url \"$RUST_SERVER_URL\""
ARGS="$ARGS +server.headerimage \"$RUST_SERVER_BANNER_URL\""
ARGS="$ARGS +server.worldsize $RUST_SERVER_WORLDSIZE"
ARGS="$ARGS +server.maxplayers $RUST_SERVER_MAXPLAYERS"
ARGS="$ARGS +server.saveinterval $RUST_SERVER_SAVEINTERVAL"

if [ ! -z "$RUST_SERVER_SEED" ]; then
    ARGS="$ARGS +server.seed $RUST_SERVER_SEED"
fi

# Export LD_LIBRARY_PATH to include the Rust server directory and its plugins
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(pwd):$(pwd)/RustDedicated_Data/Plugins/x86_64

# Run with box64
# We use exec to let the server process take over PID 1
exec box64 ./RustDedicated $ARGS
