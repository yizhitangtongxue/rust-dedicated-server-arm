# Rust Server for ARM64 (Docker + Box64 + Box86)

这是专为 **ARM64** 架构设备（如 **Oracle Cloud Ampere A1**、树莓派 5、RK3588 等）设计的 Rust 游戏服务器 Docker 解决方案。

它完美解决了在 ARM 平台上运行 x86_64 架构 Rust Dedicated Server 的难题，核心利用了：
- **Box86**: 运行 32 位 x86 的 `steamcmd` (用于下载和更新游戏)。
- **Box64**: 运行 64 位 x86_64 的 `RustDedicated` (游戏主程序)。

## ⚠️ 真实环境部署须知

在开始之前，请务必了解以下客观限制：
1.  **构建耗时**: Docker 镜像会从源码编译 Box86 和 Box64。在 4 核心 ARM CPU 上，`docker-compose build` **可能需要 15-30 分钟**。请耐心等待。
2.  **首次启动**: 容器启动后会下载 Rust Server 文件（10GB+）。取决于你的网络速度，首次启动**可能需要 30 分钟到数小时**。请查看日志确认进度。
3.  **性能损耗**: 二进制指令转译（Emulation）会有 CPU 损耗。建议地图尺寸（World Size）控制在 **3000** 以内，并定期重启。
4.  **网络模式**: 为避免通过 Docker NAT 转发 UDP 带来的性能问题和端口映射麻烦，本项目默认使用 **Host Network** 模式。

## 目录结构
- `Dockerfile`: 全栈构建脚本（含 Box86/64 编译）。
- `entrypoint.sh`: 智能启动脚本，具备权限修复、自动更新、Box 环境检测功能。
- `docker-compose.yml`: 一键部署编排文件。
- `.env`: 环境变量配置文件。

## 快速部署流程

### 1. 配置环境
复制并编辑环境变量文件。**必须修改 RCON 密码！**

```bash
cp .env.example .env
vim .env
```

### 2. 构建镜像 (一次性)
推荐使用 `tmux`、`screen` 或 `nohup` 运行，防止断连中断编译。

```bash
# 这一步非常慢，请做好心理准备
docker-compose build
```

### 3. 启动服务器

```bash
docker-compose up -d
```

### 4. 验证运行
不要以为启动了就马上能连，请先看日志：

```bash
docker-compose logs -f
```
当你看到 `Server Startup Complete` 时，才是真的启动好了。

## 网络配置
本项目使用 `network_mode: host`。你需要直接在宿主机（以及云服务商的安全组/防火墙）上开放以下端口：

| 端口 | 协议 | 用途 |
|---|---|---|
| `28015` | UDP | **游戏连接** (核心) |
| `28016` | TCP | **RCON 管理** (用于 RustAdmin 等工具) |
| `27015` | UDP | **Steam 查询** (让服务器显示在列表中) |
| `28083` | TCP | **Rust+ App** (手机伴侣应用) |

> **注意**: Oracle Cloud 用户必须在网页控制台的 "Security List" 和机器内部的 `iptables/ufw` 同时开放这些端口。

## 常用运维命令

**手动强制更新服务器:**
重启容器即可触发更新检查（默认 `RUST_APP_UPDATE=1`）。
```bash
docker-compose restart
```

**进入容器调试:**
由于是 Host 模式，端口是共用的。
```bash
docker-compose exec rust-server /bin/bash
```

## 故障排查

**Q: 启动报错 `exec format error`?**
A: 这是 Box86/64 没有正确接管二进制执行。确保宿主机的 `systemd-binfmt` 服务正常，或者重建镜像确保 Docker 内部的 binfmt 配置正确。

**Q: 提示 `Permission denied`?**
A: `entrypoint.sh` 已经内置了 `chown` 逻辑来修复 `server-data` 的权限。如果依然报错，请尝试手动在宿主机执行 `sudo chown -R 1000:1000 server-data`。

**Q: 服务器搜不到?**
A: 检查 UDP 27015 和 28015 端口是否在防火墙放行。这是最常见的问题。

## 许可证
MIT License
