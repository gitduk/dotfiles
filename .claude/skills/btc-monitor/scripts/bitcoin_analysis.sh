#!/usr/bin/env bash
# Bitcoin Market Analysis: Price + Sentiment
# Combines OKX price data with X/Twitter sentiment analysis
# Usage: ./bitcoin_analysis.sh

set -euo pipefail

# Load environment variables
if [[ -f ~/.envrc ]]; then
  source ~/.envrc
fi

echo "🔍 Bitcoin Market Analysis"
echo "=========================="
echo ""

# 1. Get BTC price from OKX (FREE API)
echo "📊 Fetching BTC price from OKX..."
okx_data=$(curl -s "https://www.okx.com/api/v5/market/ticker?instId=BTC-USDT")

btc_price=$(echo "$okx_data" | jq -r '.data[0].last')
btc_high_24h=$(echo "$okx_data" | jq -r '.data[0].high24h')
btc_low_24h=$(echo "$okx_data" | jq -r '.data[0].low24h')
btc_vol_24h=$(echo "$okx_data" | jq -r '.data[0].vol24h')
btc_change=$(echo "$okx_data" | jq -r '.data[0].sodUtc8')

echo "💰 Current Price: \$$btc_price"
echo "📈 24h High: \$$btc_high_24h"
echo "📉 24h Low: \$$btc_low_24h"
echo "📊 24h Volume: $btc_vol_24h BTC"
echo "📉 24h Change: ${btc_change}%"
echo ""

# 2. Get sentiment from X/Twitter (PAID API - optional)
if [[ -n "${XAI_TOKEN:-}" ]]; then
  echo "🎯 Fetching sentiment from X/Twitter..."

  # Only fetch 10 tweets to minimize cost
  response=$(curl -s -X GET "https://api.x.com/2/tweets/search/recent" \
    -H "Authorization: Bearer $XAI_TOKEN" \
    -G \
    --data-urlencode "query=bitcoin OR BTC OR \$BTC" \
    --data-urlencode "max_results=10" \
    --data-urlencode "tweet.fields=created_at,public_metrics,text")

  tweet_count=$(echo "$response" | jq '.meta.result_count // 0')

  if [[ $tweet_count -gt 0 ]]; then
    bullish_keywords="bullish|moon|pump|buy|long|rally|surge|breakout"
    bearish_keywords="bearish|dump|sell|short|crash|drop|fall|bear"

    bullish_count=$(echo "$response" | jq -r '.data[]?.text // empty' | grep -iEc "$bullish_keywords" || true)
    bearish_count=$(echo "$response" | jq -r '.data[]?.text // empty' | grep -iEc "$bearish_keywords" || true)

    bullish_pct=$(awk "BEGIN {printf \"%.0f\", ($bullish_count / $tweet_count) * 100}")
    bearish_pct=$(awk "BEGIN {printf \"%.0f\", ($bearish_count / $tweet_count) * 100}")

    echo "🟢 Bullish: $bullish_pct%"
    echo "🔴 Bearish: $bearish_pct%"
    echo ""
  fi
else
  echo "⚠️  X/Twitter sentiment disabled (no XAI_TOKEN)"
  echo ""
fi

# 3. Send Telegram notification
if [[ -n "${TELEGRAM_BOT_TOKEN:-}" ]] && [[ -n "${TELEGRAM_CHAT_ID:-}" ]]; then
  echo "📱 Sending Telegram notification..."

  # Determine price trend emoji
  if (( $(echo "$btc_change > 0" | bc -l) )); then
    trend_emoji="📈"
    trend_text="上涨"
  else
    trend_emoji="📉"
    trend_text="下跌"
  fi

  message="$trend_emoji *比特币市场分析*

💰 *当前价格*: \$$btc_price
$trend_emoji *24h 变化*: ${btc_change}% ($trend_text)
📊 *24h 交易量*: $btc_vol_24h BTC

📈 24h 最高: \$$btc_high_24h
📉 24h 最低: \$$btc_low_24h"

  if [[ -n "${XAI_TOKEN:-}" ]] && [[ $tweet_count -gt 0 ]]; then
    message="$message

*X 平台情绪* (样本: $tweet_count):
🟢 看涨: $bullish_pct%
🔴 看跌: $bearish_pct%"
  fi

  message="$message

---
📅 $(date '+%Y-%m-%d %H:%M')
数据来源: OKX"

  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=${message}" \
    -d "parse_mode=Markdown" > /dev/null

  if [[ $? -eq 0 ]]; then
    echo "✅ Telegram notification sent!"
  else
    echo "❌ Failed to send Telegram notification"
  fi
else
  echo "⚠️  Telegram notification disabled"
fi

echo ""
echo "✅ Analysis complete!"
