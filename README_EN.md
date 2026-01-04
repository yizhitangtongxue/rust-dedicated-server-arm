# Rust Server for ARM64 (Docker + Box64 + Box86)

This generates a Docker solution specifically designed for **ARM64** devices (such as **Oracle Cloud Ampere A1**, Raspberry Pi 5, RK3588, etc.) to run the x86_64 version of the Rust Dedicated Server.

It bridges the architecture gap using:
- **Box86**: Runs the 32-bit x86 `steamcmd` (for downloading/updating the game).
- **Box64**: Runs the 64-bit x86_64 `RustDedicated` (the game server itself).

## ⚠️ Real-World Deployment Notes

Before you begin, please acknowledge these realities:
1.  **Build Time**: The Docker image compiles Box86 and Box64 from source. On a 4-core ARM CPU, `docker-compose build` **can take 15-30 minutes**.
2.  **First Run**: The container downloads 10GB+ of game files on the first launch. Depending on your network, this **may take 30 minutes to several hours**. Check the logs!
3.  **Performance Overhead**: Emulation has a CPU cost. It is recommended to keep `World Size` under **3000** and restart the server periodically.
4.  **Network Mode**: We default to **Host Network** mode to avoid Docker NAT overhead for UDP traffic and simplify port management.

## Directory Structure
- `Dockerfile`: Full-stack build script (compiles Box86/64).
- `entrypoint.sh`: Smart startup script with permission fix, auto-update, and env checks.
- `docker-compose.yml`: One-click deployment file.
- `.env`: Configuration file.

## Quick Start Configuration

### 1. Setup Environment
Copy and edit the configuration file. **You MUST change the RCON password!**

```bash
cp .env.example .env
vim .env
```

### 2. Build Image (One-time)
Use `tmux`, `screen` or `nohup` if you are on an unstable SSH connection.

```bash
# This is slow. Grab a coffee.
docker-compose build
```

### 3. Start Server

```bash
docker-compose up -d
```

### 4. Verify Status
Don't try to connect immediately. Watch the logs:

```bash
docker-compose logs -f
```
Wait until you see `Server Startup Complete`.

## Network Configuration
This project uses `network_mode: host`. Open these ports directly on your host firewall (and Cloud Security Lists):

| Port | Protocol | Usage |
|---|---|---|
| `28015` | UDP | **Game Connection** (Core) |
| `28016` | TCP | **RCON** (Admin tools) |
| `27015` | UDP | **Steam Query** (Server Browser) |
| `28083` | TCP | **Rust+ App** (Companion) |

> **Oracle Cloud**: Ensure ports are open in the Web Console "Security List" AND the local `iptables/ufw`.

## Changelog

### 2026-01-04: Migrated to Ubuntu 20.04 and Simplified Environment

**Improvements:**
- **Base Image**: Switched from `ubuntu:22.04` to `ubuntu:20.04` (more stable LTS for this workload).
- **Build Fix**: Added cross-compiler to `Dockerfile` to solve `box86` compilation errors on ARM64.
- **Boot Logic**: Refactored `entrypoint.sh` to use Bash arrays, fixing issues with truncated parameters (e.g., `Procedural Map`).
- **Resilience**: Added auto-download for `steamcmd` when mounted volumes are empty.
- **Stability**: Refined Unity flags, specifically using `-disable-server-occlusion` to bypass `GenerateOcclusionGrid` NRE crashes on ARM.

**Results:**
- ✅ Server now loads maps correctly and reaches "Ready" state.
- ✅ Client connectivity restored, fixing previous connection and crash issues.

### 2026-01-02: Fixed NullReferenceException Error

**Issue:**  
Server crashed during startup at `Preparing Occlusion Grid` with:
```
NullReferenceException: Object reference not set to an instance of an object
  at ServerOcclusion.GenerateOcclusionGrid ()
```

**Root Cause:**  
Rust server (Unity-based) has two parameter formats:
- **Unity engine params**: Use hyphens `-` (e.g., `-batchmode`, `-disable-server-occlusion`)
- **Rust server configs**: Use plus signs `+` (e.g., `+server.port`, `+server.hostname`)

Previously used `+server.occlusion 0` which is NOT a valid Rust config, thus had no effect.

**Solution:**  
Use correct Unity engine parameters in `entrypoint.sh`:
```bash
ARGS="$ARGS -disable-server-occlusion"       # Disable occlusion system
ARGS="$ARGS -disable-server-occlusion-rocks" # Skip rock mesh baking
```

**Additional Optimizations:**
- Added 7 Box64 environment variables for stability (`BOX64_DYNAREC_STRONGMEM=3`, etc.)
- Installed Mesa graphics libraries for Unity software rendering
- Disabled AI and stability systems to reduce Box64 compatibility issues

**Impact:**
- ✅ Server now starts reliably on ARM64
- ⚠️ NPC AI disabled (no animals/scientists)
- ⚠️ Building stability system disabled

## Troubleshooting

**Q: `exec format error` at startup?**
A: Box86/64 isn't catching the binary. Ensure `systemd-binfmt` is active on the host, or rebuild the image properly.

**Q: `Permission denied` errors?**
A: `entrypoint.sh` includes logic to `chown` the `server-data` directory. If it fails, run `sudo chown -R 1000:1000 server-data` on the host.

**Q: Server not showing in browser?**
A: Double-check UDP port 27015 and 28015. This is almost always a firewall issue.

## License
MIT License
