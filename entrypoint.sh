#!/bin/bash
set -e

# Default variables
RUST_SERVER_IDENTITY="${RUST_SERVER_IDENTITY:-my_server}"
RUST_SERVER_PORT="${RUST_SERVER_PORT:-28015}"
RUST_SERVER_QUERYPORT="${RUST_SERVER_QUERYPORT:-28016}"
RUST_RCON_PORT="${RUST_RCON_PORT:-28017}"
RUST_RCON_PASSWORD="${RUST_RCON_PASSWORD:-123456}"
RUST_SERVER_NAME="${RUST_SERVER_NAME:-My ARM64 Rust Server}"
RUST_SERVER_WORLDSIZE="${RUST_SERVER_WORLDSIZE:-3000}"
RUST_SERVER_SEED="${RUST_SERVER_SEED:-12345}"
RUST_SERVER_MAXPLAYERS="${RUST_SERVER_MAXPLAYERS:-10}"
RUST_APP_UPDATE="${RUST_APP_UPDATE:-1}"
RUST_SERVER_LEVEL="${RUST_SERVER_LEVEL:-Procedural Map}"

echo ">>> Starting Rust Server on ARM64 (Box64/Box86 environment)"

# Ensure permissions for volumes
chown -R steam:steam /home/steam/steamcmd
chown -R steam:steam /home/steam/rust

# Update Rust Server
if [ "${RUST_APP_UPDATE}" = "1" ]; then
    echo ">>> Updating Rust Server (AppID 258550)..."
    cd /home/steam/steamcmd
    
    # Check if steamcmd exists (because volume mount might hide the pre-downloaded files)
    if [ ! -f "./linux32/steamcmd" ]; then
        echo ">>> SteamCMD not found in /home/steam/steamcmd (likely due to empty volume mount). Downloading..."
        curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
        chown -R steam:steam .
    fi
    
    # Run steamcmd with box86 as steam user
    gosu steam box86 ./linux32/steamcmd \
        +login anonymous \
        +force_install_dir /home/steam/rust \
        +app_update 258550 validate \
        +quit
        
    echo ">>> Update completed."
fi

# Launch Server
cd /home/steam/rust

echo ">>> Launching RustDedicated via Box64..."

# Construct launch arguments based on guide
# We keep -noeac as it's critical for Box64 compatibility
ARGS="-batchmode -noeac"
ARGS="$ARGS +server.ip 0.0.0.0"
ARGS="$ARGS +server.port $RUST_SERVER_PORT"
ARGS="$ARGS +server.queryport $RUST_SERVER_QUERYPORT"
ARGS="$ARGS +server.level \"$RUST_SERVER_LEVEL\""
ARGS="$ARGS +server.worldsize $RUST_SERVER_WORLDSIZE"
ARGS="$ARGS +server.seed $RUST_SERVER_SEED"
ARGS="$ARGS +server.maxplayers $RUST_SERVER_MAXPLAYERS"
ARGS="$ARGS +server.hostname \"$RUST_SERVER_NAME\""
ARGS="$ARGS +server.identity \"$RUST_SERVER_IDENTITY\""
ARGS="$ARGS +rcon.port $RUST_RCON_PORT"
ARGS="$ARGS +rcon.password \"$RUST_RCON_PASSWORD\""
ARGS="$ARGS +rcon.web 1"

# Guide mentioned libtcmalloc_minimal.so.4 fix, ensure LD_LIBRARY_PATH
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(pwd):$(pwd)/bin:$(pwd)/RustDedicated_Data/Plugins/x86_64

# Use exec to let the server process take over PID 1
exec gosu steam box64 ./RustDedicated $ARGS
