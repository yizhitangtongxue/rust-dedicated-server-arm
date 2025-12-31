# Rust Server for ARM64 (Docker + Box64)

这是基于 [Box64](https://github.com/ptitSeb/box64) 和 [Box86](https://github.com/ptitSeb/box86) 的 Rust 游戏服务器 Docker 解决方案。它允许你在 ARM64 架构的设备（如 Oracle Cloud A1、树莓派 5、RK3588 等）上运行 x86_64 版本的 Rust Dedicated Server。

## 原理
- **Box86**: 用于运行 32 位 x86 的 `steamcmd`，负责下载和更新游戏服务端。
- **Box64**: 用于运行 64 位 x86_64 的 `RustDedicated`，负责运行游戏逻辑。

## 目录结构
- `Dockerfile`: 构建包含 Box86 和 Box64 环境的镜像。
- `entrypoint.sh`: 容器启动脚本，处理 SteamCMD 更新和服务器启动。
- `docker-compose.yml`: 用于快速启动服务的编排文件。

## 快速开始

### 1. 构建镜像
由于需要编译 Box86 和 Box64，构建过程可能需要几分钟到十几分钟（取决于 CPU 性能）。

```bash
docker-compose build
```

### 2. 启动服务器

```bash
docker-compose up -d
```

首次启动时，容器会自动通过 SteamCMD 下载 Rust Server 文件（约 10GB+），请耐心等待。你可以通过查看日志来监控进度：

```bash
docker-compose logs -f
```

### 3. 配置
你可以在 `docker-compose.yml` 中修改环境变量来配置服务器：

| 变量名 | 默认值 | 说明 |
|---|---|---|
| `RUST_SERVER_NAME` | Rust Server Docker | 服务器名称 |
| `RUST_RCON_PASSWORD` | docker | RCON 管理密码 (务必修改) |
| `RUST_SERVER_MAXPLAYERS` | 50 | 最大玩家数 |
| `RUST_SERVER_WORLDSIZE` | 3000 | 地图大小 (建议 ARM 设备不要超过 3000) |
| `RUST_SERVER_SEED` | (随机) | 地图种子 |
| `RUST_APP_UPDATE` | 1 | 每次启动是否检查更新 (1=是, 0=否) |

### 4. 数据持久化
游戏数据保存在当前目录下的 `server-data` 文件夹中。
SteamCMD 的缓存保存在 `steamcmd-data` 文件夹中。

## 注意事项
1. **性能**: 虽然 Box64 性能惊人，但转译必然有损耗。建议分配至少 4 核心 CPU 和 8GB 内存。
2. **Swap**: Rust Server 吃内存很凶，建议在宿主机上配置至少 8GB 的 Swap 空间，防止 OOM。
3. **防火墙**: 记得在云服务商的防火墙（如 Oracle Security List）中开放 UDP 28015, 28016 和 TCP 28017。

## 许可证
本项目代码 MIT 开源。Rust 游戏本身受 Facepunch Studios 许可限制。
