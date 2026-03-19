#!/bin/bash
# AI 资讯抓取脚本 - 定时运行版
# 每天早上运行，去重后推送到 Feishu

DATE=$(date +%Y-%m-%d)
HASH_FILE="logs/news-hash-$DATE.txt"
LOG_FILE="logs/ai-news-$DATE.log"

mkdir -p logs

# 用 web_fetch 抓取 solidot 首页
CONTENT=$(curl -s "https://www.solidot.org/" 2>/dev/null | grep -oP '(?<=<p class="cmt">).*?(?=</p>)' | head -20)

# 生成内容哈希
CONTENT_HASH=$(echo "$CONTENT" | md5sum | cut -d' ' -f1)

# 检查是否重复（今天的哈希是否和昨天相同）
YESTERDAY_HASH=""
if [ -f "logs/news-hash-$(date -d 'yesterday' +%Y-%m-%d).txt" ]; then
    YESTERDAY_HASH=$(cat "logs/news-hash-$(date -d 'yesterday' +%Y-%m-%d).txt")
fi

if [ "$CONTENT_HASH" == "$YESTERDAY_HASH" ]; then
    echo "内容未更新，跳过推送" >> "$LOG_FILE"
    exit 0
fi

# 保存今天哈希
echo "$CONTENT_HASH" > "$HASH_FILE"

# 后续调用 LLM 总结内容（这里先存原始内容）
echo "$CONTENT" > "/tmp/news-raw-$DATE.txt"

echo "已获取新闻，内容哈希: $CONTENT_HASH" >> "$LOG_FILE"
