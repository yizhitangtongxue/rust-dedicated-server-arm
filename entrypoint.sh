#!/bin/bash
set -e

# Default variables
RUST_SERVER_IDENTITY="${RUST_SERVER_IDENTITY:-my_server}"
RUST_SERVER_PORT="${RUST_SERVER_PORT:-28015}"
RUST_SERVER_QUERYPORT="${RUST_SERVER_QUERYPORT:-27015}"
RUST_RCON_PORT="${RUST_RCON_PORT:-28016}"
RUST_RCON_PASSWORD="${RUST_RCON_PASSWORD:-docker}"
RUST_SERVER_NAME="${RUST_SERVER_NAME:-Rust Server Docker}"
RUST_SERVER_DESCRIPTION="${RUST_SERVER_DESCRIPTION:-Powered by Box64 on ARM}"
RUST_SERVER_URL="${RUST_SERVER_URL:-}"
RUST_SERVER_BANNER_URL="${RUST_SERVER_BANNER_URL:-}"
RUST_SERVER_WORLDSIZE="${RUST_SERVER_WORLDSIZE:-3000}"
RUST_SERVER_MAXPLAYERS="${RUST_SERVER_MAXPLAYERS:-50}"
RUST_SERVER_SAVEINTERVAL="${RUST_SERVER_SAVEINTERVAL:-600}"
RUST_SERVER_SEED="${RUST_SERVER_SEED:-}" # Empty means random
RUST_APP_PORT="${RUST_APP_PORT:-28083}"
RUST_APP_PUBLICIP="${RUST_APP_PUBLICIP:-}" # Optional, for +app.publicip
RUST_APP_UPDATE="${RUST_APP_UPDATE:-1}"

RUST_SERVER_LEVEL="${RUST_SERVER_LEVEL:-Procedural Map}"

# Check for box86 and box64
if ! command -v box86 &> /dev/null; then
    echo "ERROR: box86 not found in PATH"
    exit 1
fi
if ! command -v box64 &> /dev/null; then
    echo "ERROR: box64 not found in PATH"
    exit 1
fi

echo ">>> Starting Rust Server on ARM64 (Box64/Box86 environment)"
echo ">>> Host Architecture: $(uname -m)"
echo ">>> Current User: $(id)"
echo ">>> Server Level: $RUST_SERVER_LEVEL"

# Ensure permissions for volumes
echo ">>> Fixing permissions for /home/steam/steamcmd and /home/steam/rust..."
chown -R steam:steam /home/steam/steamcmd
chown -R steam:steam /home/steam/rust

# Update Rust Server
if [ "${RUST_APP_UPDATE}" = "1" ]; then
    echo ">>> Updating Rust Server (AppID 258550)..."
    
    cd /home/steam/steamcmd
    
    # Check if steamcmd exists (because volume mount might hide the pre-downloaded files)
    if [ ! -f "./steamcmd.sh" ] && [ ! -f "./linux32/steamcmd" ]; then
        echo ">>> SteamCMD not found (likely due to volume mount). Downloading..."
        # We download as root, but verify permission to write
        if [ ! -w . ]; then
             echo "ERROR: /home/steam/steamcmd is not writable."
             ls -ld .
        fi
        curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -
        chmod +x steamcmd.sh
        if [ -f "./linux32/steamcmd" ]; then
            chmod +x linux32/steamcmd
        fi
        
        # Determine ownership fix after download
        chown -R steam:steam .
    fi
    
    # Run steamcmd with box86 as steam user
    # We directly target the x86 32-bit binary to avoid wrapper script confusion
    if [ -f "./linux32/steamcmd" ]; then
        gosu steam box86 ./linux32/steamcmd \
            +@sSteamCmdForcePlatformType linux \
            +force_install_dir /home/steam/rust \
            +login anonymous \
            +app_update 258550 validate \
            +quit
    elif [ -f "./steamcmd.sh" ]; then
        # Fallback to shell script if binary not directly found (rare)
        gosu steam box86 ./steamcmd.sh \
            +@sSteamCmdForcePlatformType linux \
            +force_install_dir /home/steam/rust \
            +login anonymous \
            +app_update 258550 validate \
            +quit
    else
         echo "ERROR: Could not find steamcmd binary even after download."
         exit 1
    fi
        
    echo ">>> Update completed."
fi

# Prepare to run Server
cd /home/steam/rust

# Check for required library fixes (sometimes needed for Rust)
# Currently handled by Box64 dynamic wrapping, but if specific libs are missing, we might need to symlink them.

echo ">>> Launching RustDedicated via Box64..."

# Construct launch arguments
# Unity flags (Use hyphens for Unity engine parameters)
ARGS="-batchmode -nographics"

# Critical Unity engine fixes for Box64/ARM compatibility
# These MUST use hyphens (-) as they are Unity engine parameters, not Rust server configs
ARGS="$ARGS -noeac"                         # Disable Easy Anti-Cheat (EAC doesn't work in Box64)
ARGS="$ARGS -disable-server-occlusion"      # Disable occlusion culling (prevents NRE in GenerateOcclusionGrid)
ARGS="$ARGS -disable-server-occlusion-rocks"  # Skip rock meshes in occlusion grid bake
ARGS="$ARGS -force-gfx-jobs native"         # Force native graphics jobs
ARGS="$ARGS -force-glcore"                  # Force OpenGL Core

# Rust server configuration (Use plus signs for Rust server configs)
ARGS="$ARGS +server.ip 0.0.0.0"
ARGS="$ARGS +server.port $RUST_SERVER_PORT"
ARGS="$ARGS +server.queryport $RUST_SERVER_QUERYPORT"
ARGS="$ARGS +rcon.port $RUST_RCON_PORT"
ARGS="$ARGS +rcon.password \"$RUST_RCON_PASSWORD\""
ARGS="$ARGS +rcon.web 1"
ARGS="$ARGS +server.identity \"$RUST_SERVER_IDENTITY\""
ARGS="$ARGS +server.level \"$RUST_SERVER_LEVEL\""
ARGS="$ARGS +server.hostname \"$RUST_SERVER_NAME\""
ARGS="$ARGS +server.description \"$RUST_SERVER_DESCRIPTION\""
ARGS="$ARGS +server.url \"$RUST_SERVER_URL\""
ARGS="$ARGS +server.headerimage \"$RUST_SERVER_BANNER_URL\""
ARGS="$ARGS +server.worldsize $RUST_SERVER_WORLDSIZE"
ARGS="$ARGS +server.maxplayers $RUST_SERVER_MAXPLAYERS"
ARGS="$ARGS +server.saveinterval $RUST_SERVER_SAVEINTERVAL"
ARGS="$ARGS +app.port $RUST_APP_PORT"

# Additional Rust server optimizations for Box64/ARM
ARGS="$ARGS +physics.steps 60"              # Reduce physics complexity
ARGS="$ARGS +ai.think false"                # Disable AI processing
ARGS="$ARGS +ai.move false"                 # Disable AI movement
ARGS="$ARGS +server.stability false"        # Disable stability system
ARGS="$ARGS +server.plantlightdetection false"  # Disable plant light detection

if [ ! -z "$RUST_APP_PUBLICIP" ]; then
    ARGS="$ARGS +app.publicip $RUST_APP_PUBLICIP"
fi

if [ ! -z "$RUST_SERVER_SEED" ]; then
    ARGS="$ARGS +server.seed $RUST_SERVER_SEED"
fi

# Export LD_LIBRARY_PATH to include the Rust server directory and its plugins
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$(pwd):$(pwd)/RustDedicated_Data/Plugins/x86_64

# Force Unity to use software rendering (critical for Box64 compatibility)
export UNITY_RENDERER=software
export UNITY_DISABLE_RENDERING=1

# Run with box64
# We use exec to let the server process take over PID 1
echo ">>> Checking permissions..."
chown -R steam:steam /home/steam

# Switch to steam user for the rest of the script
exec gosu steam box64 ./RustDedicated $ARGS
