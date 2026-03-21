# OpenClaw Docker 安装说明书

## 概述

本教程将帮助你把 OpenClaw 安装到 Docker 环境中。Docker 安装是**可选的**，仅在你需要容器化的网关环境或在无本地安装的主机上运行 OpenClaw 时才推荐使用。

---

## 一、准备工作

### 1.1 环境要求

- **Docker Desktop**（macOS/Windows）或 **Docker Engine**（Linux）
- **Docker Compose v2**
- 至少 **2 GB RAM**（构建镜像时需要，1 GB 主机可能会 OOM）
- 足够的磁盘空间用于镜像和日志
- 如果在 VPS/公网主机上运行，需检查防火墙策略

### 1.2 检查 Docker 是否已安装

```bash
docker --version
docker compose version
```

如果未安装，请访问 [Docker 官网](https://www.docker.com/products/docker-desktop/) 下载安装。

---

## 二、快速开始（推荐方式）

### 2.1 一键安装

从 OpenClaw 仓库根目录运行：

```bash
./docker-setup.sh
```

这个脚本会自动完成以下操作：
- ✅ 在本地构建网关镜像（或从远程拉取）
- ✅ 运行初始化向导
- ✅ 打印可选的 provider 设置提示
- ✅ 通过 Docker Compose 启动网关
- ✅ 生成网关 token 并写入 `.env` 文件

### 2.2 初始化配置

安装完成后：

1. 在浏览器中打开 `http://127.0.0.1:18789/`
2. 将 token 粘贴到 Control UI（设置 → token）

> 💡 如果需要再次获取 URL，运行：
> ```bash
> docker compose run --rm openclaw-cli dashboard --no-open
> ```

---

## 三、使用远程镜像（跳过本地构建）

如果你想直接使用官方预构建的镜像，而不是本地构建：

```bash
export OPENCLAW_IMAGE="ghcr.io/openclaw/openclaw:latest"
./docker-setup.sh
```

### 官方镜像标签

| 标签 | 说明 |
|------|------|
| `main` | main 分支的最新构建 |
| `<version>` | 发布版本（如 `2026.2.26`） |
| `latest` | 最新稳定版 |

镜像地址：https://github.com/openclaw/openclaw/pkgs/container/openclaw

---

## 四、启用 Agent 沙箱（可选）

如果你想在 Docker 部署中启用沙箱隔离：

```bash
export OPENCLAW_SANDBOX=1
./docker-setup.sh
```

自定义 Docker socket 路径（如 rootless Docker）：

```bash
export OPENCLAW_SANDBOX=1
export OPENCLAW_DOCKER_SOCKET=/run/user/1000/docker.sock
./docker-setup.sh
```

---

## 五、常用操作命令

### 5.1 启动网关

```bash
docker compose up -d openclaw-gateway
```

### 5.2 停止网关

```bash
docker compose down
```

### 5.3 查看日志

```bash
docker compose logs -f openclaw-gateway
```

### 5.4 查看状态

```bash
docker compose ps
```

### 5.5 重启网关

```bash
docker compose restart openclaw-gateway
```

### 5.6 手动初始化（高级）

如果 `docker-setup.sh` 不适用，可以手动运行：

```bash
# 构建镜像
docker build -t openclaw:local -f Dockerfile .

# 初始化配置
docker compose run --rm openclaw-cli onboard

# 启动网关
docker compose up -d openclaw-gateway
```

---

## 六、频道设置（可选）

### 6.1 WhatsApp（扫码登录）

```bash
docker compose run --rm openclaw-cli channels login
```

### 6.2 Telegram

```bash
docker compose run --rm openclaw-cli channels add --channel telegram --token "<你的bot_token>"
```

### 6.3 Discord

```bash
docker compose run --rm openclaw-cli channels add --channel discord --token "<你的bot_token>"
```

---

## 七、健康检查

### 7.1 基础健康检查

```bash
curl -fsS http://127.0.0.1:18789/healthz
curl -fsS http://127.0.0.1:18789/readyz
```

### 7.2 深度健康检查（含频道状态）

```bash
docker compose exec openclaw-gateway node dist/index.js health --token "$OPENCLAW_GATEWAY_TOKEN"
```

---

## 八、故障排除

### 8.1 Token 过期或需要重新配对

```bash
# 获取新的 dashboard 链接
docker compose run --rm openclaw-cli dashboard --no-open

# 列出设备请求
docker compose run --rm openclaw-cli devices list

# 批准设备
docker compose run --rm openclaw-cli devices approve <requestId>
```

### 8.2 权限问题（EACCES）

镜像以非 root 用户 `node`（uid 1000）运行。如果遇到权限错误：

```bash
# Linux 主机上
sudo chown -R 1000:1000 /path/to/openclaw-config /path/to/openclaw-workspace
```

### 8.3 网络连接问题

如果看到 `Gateway target: ws://172.x.x.x:18789` 或重复的 `pairing required` 错误：

```bash
docker compose run --rm openclaw-cli config set gateway.mode local
docker compose run --rm openclaw-cli config set gateway.bind lan
docker compose run --rm openclaw-cli devices list --url ws://127.0.0.1:18789
```

---

## 九、Shell 辅助工具（可选）

安装 `ClawDock` 让日常 Docker 管理更方便：

```bash
mkdir -p ~/.clawdock && curl -sL https://raw.githubusercontent.com/openclaw/openclaw/main/scripts/shell-helpers/clawdock-helpers.sh -o ~/.clawdock/clawdock-helpers.sh
```

添加到 zsh 配置：

```bash
echo 'source ~/.clawdock/clawdock-helpers.sh' >> ~/.zshrc && source ~/.zshrc
```

可用命令：`clawdock-start`、`clawdock-stop`、`clawdock-dashboard` 等。

---

## 十、高级配置

### 10.1 持久化配置目录

默认情况下，配置通过 bind mount 保存在主机：
- `~/.openclaw/`
- `~/.openclaw/workspace`

### 10.2 持久化整个容器 home 目录

```bash
export OPENCLAW_HOME_VOLUME="openclaw_home"
./docker-setup.sh
```

### 10.3 额外挂载主机目录

```bash
export OPENCLAW_EXTRA_MOUNTS="$HOME/.codex:/home/node/.codex:ro,$HOME/github:/home/node/github:rw"
./docker-setup.sh
```

### 10.4 预装系统包

```bash
export OPENCLAW_DOCKER_APT_PACKAGES="ffmpeg build-essential git curl jq"
./docker-setup.sh
```

### 10.5 预装扩展依赖

```bash
export OPENCLAW_EXTENSIONS="diagnostics-otel matrix"
./docker-setup.sh
```

---

## 十一、相关文档

- [官方文档](https://docs.openclaw.ai/install/docker)
- [Control UI 使用指南](/web/dashboard)
- [设备配对说明](/cli/devices)
- [沙箱安全配置](/gateway/sandboxing)

---

*文档更新时间：2026-03-15*
