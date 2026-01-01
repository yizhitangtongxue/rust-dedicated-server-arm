# Rust Server for ARM64 (Docker + Box64)

This is a Rust game server Docker solution based on [Box64](https://github.com/ptitSeb/box64) and [Box86](https://github.com/ptitSeb/box86). It allows you to run the x86_64 version of the Rust Dedicated Server on ARM64 devices (such as Oracle Cloud A1, Raspberry Pi 5, RK3588, etc.).

## How it Works
- **Box86**: Runs the 32-bit x86 `steamcmd` to download and update the game server.
- **Box64**: Runs the 64-bit x86_64 `RustDedicated` executable for the game logic.

## Directory Structure
- `Dockerfile`: Builds the image containing Box86 and Box64 environments.
- `entrypoint.sh`: Startup script handling SteamCMD updates and server launch.
- `docker-compose.yml`: Compose file for quick deployment.
- `.env`: Environment configuration file.
- `.env.example`: Example environment configuration.

## Quick Start

### 1. Configuration
Copy the example configuration file and edit it:
```bash
cp .env.example .env
nano .env
```
**Important:** Make sure to change `RUST_RCON_PASSWORD`.

### 2. Build Image
Building Box86 and Box64 from source takes time (a few to several minutes depending on CPU).

```bash
docker-compose build
```

### 3. Start Server

```bash
docker-compose up -d
```

On first run, the container will automatically download Rust Server files via SteamCMD (approx. 10GB+). Please be patient. You can monitor progress via logs:

```bash
docker-compose logs -f
```

## Network Configuration (Host Mode)
 For best performance and simplest configuration, this project defaults to Docker's `host` network mode. The container shares the host's network stack directly.

Ensure the following ports are open on your host firewall:

| Port | Protocol | Description |
|---|---|---|
| `28015` | UDP | Rust Game Port |
| `28016` | TCP | RCON Port |
| `27015` | UDP | Steam Query Port (For Server Browser) |
| `28083` | TCP | Rust+ Companion App Port |

### 4. Data Persistence
Game data is saved in the local `server-data` directory.
SteamCMD cache is saved in the local `steamcmd-data` directory.

## Environment Variables
See `.env` for detailed configuration.

| Variable | Default | Description |
|---|---|---|
| `RUST_SERVER_NAME` | My Dockerized ARM Rust Server | Server Name |
| `RUST_SERVER_LEVEL` | Procedural Map | Map Type |
| `RUST_RCON_PASSWORD` | change_me_please | RCON Password |
| `RUST_SERVER_MAXPLAYERS` | 10 | Max Players |
| `RUST_SERVER_WORLDSIZE` | 3000 | Map Size (Keep <3000 recommended on ARM) |
| `RUST_SERVER_PORT` | 28015 | Game Port (UDP) |
| `RUST_RCON_PORT` | 28016 | RCON Port (TCP) |
| `RUST_SERVER_QUERYPORT` | 27015 | Query Port (UDP) |
| `RUST_APP_PORT` | 28083 | Rust+ Port (TCP) |

## Notes
1. **Performance**: Box64 is impressive, but emulation has overhead. At least 4 CPU cores and 8GB RAM are recommended.
2. **Swap**: Rust Server consumes a lot of RAM. It is highly recommended to configure at least 8GB Swap on the host to prevent OOM.
    ```bash
    # Create 8G Swap
    sudo fallocate -l 8G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    ```
3. **Rust+**: To use the Rust+ App, ensure `RUST_APP_PORT` is open and follow official pairing guides.

## License
Project code is MIT licensed. Rust game usage is subject to Facepunch Studios licensing.
