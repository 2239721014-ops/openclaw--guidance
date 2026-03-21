# oMLX 使用说明书

> 本地 macOS LLM 推理服务器 - 持续批处理 + SSD 分层 KV 缓存

## 简介

oMLX 是一个专为 Apple Silicon (M1-M4) Mac 优化的 LLM 推理服务器，支持：
- 文本 LLM、多模态模型 (VLM)、OCR、Embedding、Reranker
- 分层 KV 缓存（热缓存 RAM + 冷缓存 SSD）
- 持续批处理并发请求
- 菜单栏应用 + Web 管理面板
- OpenAI/Anthropic API 兼容

---

## 安装

### 方法一：macOS App（推荐）

1. 从 [Releases](https://github.com/jundot/omlx/releases) 下载 `.dmg`
2. 拖拽到 Applications 文件夹
3. 打开 app，跟随欢迎向导配置模型目录并启动服务

### 方法二：Homebrew

```bash
brew tap jundot/omlx https://github.com/jundot/omlx
brew install omlx

# 升级
brew update && brew upgrade omlx

# 作为后台服务运行（崩溃自动重启）
brew services start omlx
```

### 方法三：源码安装

```bash
git clone https://github.com/jundot/omlx.git
cd omlx
pip install -e .          # 核心功能
pip install -e ".[mcp]"   # + MCP 支持
```

**要求**：macOS 15.0+ (Sequoia), Python 3.10+, Apple Silicon

---

## 快速开始

### 菜单栏 App

打开 oMLX 应用 → 跟随欢迎向导：
1. 选择模型目录（如 `~/models`）
2. 启动服务
3. 下载第一个模型

### 命令行

```bash
omlx serve --model-dir ~/models
```

服务地址：
- API: `http://localhost:8000/v1`
- 管理面板: `http://localhost:8000/admin`
- 内置聊天: `http://localhost:8000/admin/chat`

---

## 核心功能

### 1. 分层 KV 缓存

- **热缓存 (RAM)**：频繁访问的块保持在内存中
- **冷缓存 (SSD)**：满时自动卸载到 SSD，下一次请求命中缓存时从磁盘恢复，无需重新计算

```bash
# 启用 SSD 缓存
omlx serve --model-dir ~/models --paged-ssd-cache-dir ~/.omlx/cache

# 调整热缓存大小（默认 20%）
omlx serve --model-dir ~/models --hot-cache-max-size 20%
```

### 2. 多模型服务

- LRU 自动驱逐：内存不足时自动卸载最久未使用的模型
- 手动加载/卸载：管理面板可点击操作
- 模型固定：常用模型可固定在内存中
- Per-model TTL：设置空闲超时自动卸载

### 3. 多模态模型 (VLM)

支持 Qwen3.5、GLM-4V、Pixtral 等，兼容多图像聊天、base64/URL/文件输入。

### 4. 工具调用

支持 mlx-lm 的所有函数调用格式：
- Llama/Qwen/DeepSeek: JSON `<tool_call>`
- Qwen3.5: XML `<function=...>`
- GLM (4.7, 5): XML `<arg_key>/<arg_value>`
- MiniMax: `<minimax:tool_call>`

---

## 配置

### 常用参数

```bash
# 内存限制
omlx serve --model-dir ~/models --max-model-memory 32GB
omlx serve --model-dir ~/models --max-process-memory 80%

# 批处理大小
omlx serve --model-dir ~/models --prefill-batch-size 8 --completion-batch-size 32

# API 密钥
omlx serve --model-dir ~/models --api-key your-secret-key

# HuggingFace 镜像（国内）
omlx serve --model-dir ~/models --hf-endpoint https://hf-mirror.com
```

### 管理面板配置

所有设置也可在 Web 管理面板 `/admin` 中配置，保存到 `~/.omlx/settings.json`。

---

## API 接口

| 端点 | 说明 |
|------|------|
| `POST /v1/chat/completions` | 对话补全（支持流式） |
| `POST /v1/completions` | 文本补全（支持流式） |
| `POST /v1/messages` | Anthropic Messages API |
| `POST /v1/embeddings` | 文本嵌入 |
| `POST /v1/rerank` | 文档重排序 |
| `GET /v1/models` | 列出可用模型 |

---

## 集成 OpenClaw

在管理面板 `/admin` → Integrations 一键配置 OpenClaw 连接：

```
API 地址: http://localhost:8000/v1
模型: omlx 中可用的模型名称
```

---

## 与 OpenClaw 配置

在 OpenClaw 配置中添加 oMLX 端点：

```json
{
  "providers": {
    "omlx": {
      "apiBase": "http://localhost:8000/v1",
      "models": ["模型名称"]
    }
  }
}
```

---

## 日志位置

- Homebrew 服务日志：`$(brew --prefix)/var/log/omlx.log`
- 服务端日志：`~/.omlx/logs/server.log`

---

## 相关链接

- 官网：https://omlx.ai
- GitHub：https://github.com/jundot/omlx
- Benchmark：https://omlx.ai/benchmarks
