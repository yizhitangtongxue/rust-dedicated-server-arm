# Rust Server for ARM64 (Docker + Box64)

这是基于 [Box64](https://github.com/ptitSeb/box64) 和 [Box86](https://github.com/ptitSeb/box86) 的 Rust 游戏服务器 Docker 解决方案。它允许你在 ARM64 架构的设备（如 Oracle Cloud A1、树莓派 5、RK3588 等）上运行 x86_64 版本的 Rust Dedicated Server。

## 原理
- **Box86**: 用于运行 32 位 x86 的 `steamcmd`，负责下载和更新游戏服务端。
- **Box64**: 用于运行 64 位 x86_64 的 `RustDedicated`，负责运行游戏逻辑。

## 目录结构
- `Dockerfile`: 构建包含 Box86 和 Box64 环境的镜像。
- `entrypoint.sh`: 容器启动脚本，处理 SteamCMD 更新和服务器启动。
- `docker-compose.yml`: 用于快速启动服务的编排文件。
- `.env`: 环境变量配置文件。
- `.env.example`: 环境变量示例文件。

## 快速开始

### 1. 配置环境
复制示例配置文件并进行修改：
```bash
cp .env.example .env
nano .env
```
请务必修改 `RUST_RCON_PASSWORD`。

### 2. 构建镜像
由于需要编译 Box86 和 Box64，构建过程可能需要几分钟到十几分钟（取决于 CPU 性能）。

```bash
docker-compose build
```

### 3. 启动服务器

```bash
docker-compose up -d
```

首次启动时，容器会自动通过 SteamCMD 下载 Rust Server 文件（约 10GB+），请耐心等待。你可以通过查看日志来监控进度：

```bash
docker-compose logs -f
```

## 网络配置 (Host Mode)
为了获得最佳性能和最简单的网络配置，本项目现在默认使用 Docker 的 `host` 网络模式。这意味着容器将直接共享宿主机的网络栈。

你需要确保宿主机开启以下端口：

| 端口 | 协议 | 说明 |
|---|---|---|
| `28015` | UDP | Rust 游戏主端口 |
| `28016` | TCP | RCON 管理端口 |
| `27015` | UDP | Steam 查询端口 (用于显示在服务器列表) |
| `28083` | TCP | Rust+ 伴侣应用端口 |

### 4. 数据持久化
游戏数据保存在当前目录下的 `server-data` 文件夹中。
SteamCMD 的缓存保存在 `steamcmd-data` 文件夹中。

## 环境变量说明
详细配置请参考 `.env` 文件。

| 变量名 | 默认值 | 说明 |
|---|---|---|
| `RUST_SERVER_NAME` | My Dockerized ARM Rust Server | 服务器名称 |
| `RUST_SERVER_LEVEL` | Procedural Map | 地图类型 |
| `RUST_RCON_PASSWORD` | change_me_please | RCON 密码 |
| `RUST_SERVER_MAXPLAYERS` | 10 | 最大玩家数 |
| `RUST_SERVER_WORLDSIZE` | 3000 | 地图尺寸 (建议 ARM 设备不要过大) |
| `RUST_SERVER_PORT` | 28015 | 游戏端口 (UDP) |
| `RUST_RCON_PORT` | 28016 | RCON 端口 (TCP) |
| `RUST_SERVER_QUERYPORT` | 27015 | 查询端口 (UDP) |
| `RUST_APP_PORT` | 28083 | Rust+ 端口 (TCP) |

## 注意事项
1. **性能**: 虽然 Box64 性能惊人，但转译必然有损耗。建议分配至少 4 核心 CPU 和 8GB 内存。
2. **Swap**: Rust Server 吃内存很凶，建议在宿主机上配置至少 8GB 的 Swap 空间，防止 OOM。
    ```bash
    # 创建 8G Swap
    sudo fallocate -l 8G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    ```
3. **Rust+**: 如果你想使用 Rust+ App，请确保 `RUST_APP_PORT` 已开放，并且按照官方教程进行配对。

## 许可证
本项目代码 MIT 开源。Rust 游戏本身受 Facepunch Studios 许可限制。
