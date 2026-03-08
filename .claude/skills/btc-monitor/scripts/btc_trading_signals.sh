#!/usr/bin/env bash
# Advanced Bitcoin Trading Signal System
# 综合技术分析 + 情绪分析 + 风险管理
# Usage: ./btc_trading_signals.sh

set -euo pipefail

# Load environment variables
if [[ -f ~/.envrc ]]; then
  source ~/.envrc
fi

# Configuration
SIGNAL_FILE="$HOME/btc_signals_$(date +%Y%m%d).json"
LOG_FILE="$HOME/btc_analysis.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "========================================="
log "Bitcoin Trading Signal Analysis Started"
log "========================================="

# ============================================
# 1. 技术分析 - OKX 数据（免费）
# ============================================

log "📊 Step 1: Technical Analysis (OKX)"

# 获取当前价格
ticker=$(curl -s "https://www.okx.com/api/v5/market/ticker?instId=BTC-USDT")
current_price=$(echo "$ticker" | jq -r '.data[0].last')
high_24h=$(echo "$ticker" | jq -r '.data[0].high24h')
low_24h=$(echo "$ticker" | jq -r '.data[0].low24h')
vol_24h=$(echo "$ticker" | jq -r '.data[0].vol24h')
change_24h=$(echo "$ticker" | jq -r '.data[0].sodUtc8')

log "  Current Price: \$$current_price"
log "  24h Change: ${change_24h}%"

# 获取 K 线数据（1小时，最近100根）
candles=$(curl -s "https://www.okx.com/api/v5/market/candles?instId=BTC-USDT&bar=1H&limit=100")

# 提取收盘价
closes=$(echo "$candles" | jq -r '.data[] | .[4]' | tac)

# 计算移动平均线
ma_7=$(echo "$closes" | head -7 | awk '{sum+=$1} END {printf "%.2f", sum/NR}')
ma_25=$(echo "$closes" | head -25 | awk '{sum+=$1} END {printf "%.2f", sum/NR}')
ma_99=$(echo "$closes" | head -99 | awk '{sum+=$1} END {printf "%.2f", sum/NR}')

log "  MA7: \$$ma_7"
log "  MA25: \$$ma_25"
log "  MA99: \$$ma_99"

# 计算 RSI (简化版，14周期)
rsi_period=14
price_changes=$(echo "$closes" | head -$((rsi_period + 1)) | awk 'NR>1 {print $1-prev} {prev=$1}')
gains=$(echo "$price_changes" | awk '$1>0 {sum+=$1; count++} END {if(count>0) print sum/count; else print 0}')
losses=$(echo "$price_changes" | awk '$1<0 {sum+=-$1; count++} END {if(count>0) print sum/count; else print 0}')

if (( $(echo "$losses > 0" | bc -l) )); then
  rs=$(echo "scale=4; $gains / $losses" | bc)
  rsi=$(echo "scale=2; 100 - (100 / (1 + $rs))" | bc)
else
  rsi=100
fi

log "  RSI(14): $rsi"

# 技术信号判断
tech_signal="NEUTRAL"
tech_score=0

# MA 交叉信号
if (( $(echo "$current_price > $ma_7 && $ma_7 > $ma_25 && $ma_25 > $ma_99" | bc -l) )); then
  tech_signal="STRONG_BUY"
  tech_score=2
  log "  ✅ Golden Cross: 短期均线上穿长期均线"
elif (( $(echo "$current_price > $ma_7 && $ma_7 > $ma_25" | bc -l) )); then
  tech_signal="BUY"
  tech_score=1
  log "  🟢 Bullish: 价格在短期均线之上"
elif (( $(echo "$current_price < $ma_7 && $ma_7 < $ma_25 && $ma_25 < $ma_99" | bc -l) )); then
  tech_signal="STRONG_SELL"
  tech_score=-2
  log "  ❌ Death Cross: 短期均线下穿长期均线"
elif (( $(echo "$current_price < $ma_7 && $ma_7 < $ma_25" | bc -l) )); then
  tech_signal="SELL"
  tech_score=-1
  log "  🔴 Bearish: 价格在短期均线之下"
fi

# RSI 超买超卖
if (( $(echo "$rsi > 70" | bc -l) )); then
  log "  ⚠️  RSI 超买 (>70): 可能回调"
  ((tech_score--)) || true
elif (( $(echo "$rsi < 30" | bc -l) )); then
  log "  💡 RSI 超卖 (<30): 可能反弹"
  ((tech_score++)) || true
fi

# ============================================
# 2. 情绪分析 - X/Twitter（可选，付费）
# ============================================

sentiment_score=0
sentiment_signal="UNKNOWN"

if [[ -n "${XAI_TOKEN:-}" ]]; then
  log ""
  log "🎯 Step 2: Sentiment Analysis (X/Twitter)"

  response=$(curl -s -X GET "https://api.x.com/2/tweets/search/recent" \
    -H "Authorization: Bearer $XAI_TOKEN" \
    -G \
    --data-urlencode "query=bitcoin OR BTC lang:en -is:retweet" \
    --data-urlencode "max_results=20" \
    --data-urlencode "tweet.fields=created_at,public_metrics,text")

  tweet_count=$(echo "$response" | jq '.meta.result_count // 0')

  if [[ $tweet_count -gt 0 ]]; then
    # 情绪关键词分析
    bullish_strong="moon|rocket|ATH|breakout|rally|surge"
    bullish_weak="bullish|buy|long|pump"
    bearish_strong="crash|dump|collapse|panic|fear"
    bearish_weak="bearish|sell|short|drop|fall"

    bull_strong=$(echo "$response" | jq -r '.data[]?.text // empty' | grep -iEc "$bullish_strong" || true)
    bull_weak=$(echo "$response" | jq -r '.data[]?.text // empty' | grep -iEc "$bullish_weak" || true)
    bear_strong=$(echo "$response" | jq -r '.data[]?.text // empty' | grep -iEc "$bearish_strong" || true)
    bear_weak=$(echo "$response" | jq -r '.data[]?.text // empty' | grep -iEc "$bearish_weak" || true)

    # 计算情绪得分 (-100 到 +100)
    sentiment_score=$(( (bull_strong * 10 + bull_weak * 5 - bear_strong * 10 - bear_weak * 5) * 100 / tweet_count ))

    log "  Tweets analyzed: $tweet_count"
    log "  Bullish mentions: $((bull_strong + bull_weak))"
    log "  Bearish mentions: $((bear_strong + bear_weak))"
    log "  Sentiment Score: $sentiment_score/100"

    if (( sentiment_score > 30 )); then
      sentiment_signal="BULLISH"
      log "  🟢 Market Sentiment: BULLISH"
    elif (( sentiment_score < -30 )); then
      sentiment_signal="BEARISH"
      log "  🔴 Market Sentiment: BEARISH"
    else
      sentiment_signal="NEUTRAL"
      log "  ⚪ Market Sentiment: NEUTRAL"
    fi
  fi
else
  log ""
  log "⚠️  Step 2: Sentiment Analysis SKIPPED (no XAI_TOKEN)"
fi

# ============================================
# 3. 综合信号生成
# ============================================

log ""
log "🎲 Step 3: Signal Generation"

# 综合得分 = 技术分析 (60%) + 情绪分析 (40%)
if [[ "$sentiment_signal" != "UNKNOWN" ]]; then
  sentiment_weight=$(echo "scale=2; $sentiment_score / 100 * 0.4" | bc)
  tech_weight=$(echo "scale=2; $tech_score / 2 * 0.6" | bc)
  final_score=$(echo "scale=2; $tech_weight + $sentiment_weight" | bc)
else
  final_score=$(echo "scale=2; $tech_score / 2" | bc)
fi

# 生成交易信号
if (( $(echo "$final_score > 0.5" | bc -l) )); then
  final_signal="🟢 STRONG BUY"
  action="建议买入"
  confidence="高"
elif (( $(echo "$final_score > 0.2" | bc -l) )); then
  final_signal="🟢 BUY"
  action="可以买入"
  confidence="中"
elif (( $(echo "$final_score < -0.5" | bc -l) )); then
  final_signal="🔴 STRONG SELL"
  action="建议卖出"
  confidence="高"
elif (( $(echo "$final_score < -0.2" | bc -l) )); then
  final_signal="🔴 SELL"
  action="可以卖出"
  confidence="中"
else
  final_signal="⚪ HOLD"
  action="持有观望"
  confidence="低"
fi

log "  Technical Score: $tech_score/2"
log "  Sentiment Score: $sentiment_score/100"
log "  Final Score: $final_score"
log "  Signal: $final_signal"
log "  Action: $action"
log "  Confidence: $confidence"

# ============================================
# 4. 风险管理建议
# ============================================

log ""
log "⚠️  Step 4: Risk Management"

# 计算波动率
volatility=$(echo "scale=2; ($high_24h - $low_24h) / $current_price * 100" | bc)
log "  24h Volatility: ${volatility}%"

# 止损止盈建议
if [[ "$action" == "建议买入" ]] || [[ "$action" == "可以买入" ]]; then
  stop_loss=$(echo "scale=2; $current_price * 0.95" | bc)
  take_profit_1=$(echo "scale=2; $current_price * 1.05" | bc)
  take_profit_2=$(echo "scale=2; $current_price * 1.10" | bc)

  log "  建议入场价: \$$current_price"
  log "  止损价 (-5%): \$$stop_loss"
  log "  止盈价1 (+5%): \$$take_profit_1"
  log "  止盈价2 (+10%): \$$take_profit_2"
  log "  建议仓位: 总资金的 10-20%"
elif [[ "$action" == "建议卖出" ]] || [[ "$action" == "可以卖出" ]]; then
  log "  建议出场价: \$$current_price"
  log "  如持有多单，建议止损离场"
fi

# ============================================
# 5. 保存信号数据
# ============================================

cat > "$SIGNAL_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "price": {
    "current": $current_price,
    "high_24h": $high_24h,
    "low_24h": $low_24h,
    "change_24h": $change_24h
  },
  "technical": {
    "ma7": $ma_7,
    "ma25": $ma_25,
    "ma99": $ma_99,
    "rsi": $rsi,
    "signal": "$tech_signal",
    "score": $tech_score
  },
  "sentiment": {
    "score": $sentiment_score,
    "signal": "$sentiment_signal"
  },
  "final": {
    "score": $final_score,
    "signal": "$final_signal",
    "action": "$action",
    "confidence": "$confidence"
  }
}
EOF

log ""
log "💾 Signal data saved to: $SIGNAL_FILE"

# ============================================
# 6. Telegram 通知
# ============================================

if [[ -n "${TELEGRAM_BOT_TOKEN:-}" ]] && [[ -n "${TELEGRAM_CHAT_ID:-}" ]]; then
  log ""
  log "📱 Step 5: Sending Telegram Notification"

  message="$final_signal *比特币交易信号*

💰 *当前价格*: \$$current_price
📊 *24h 变化*: ${change_24h}%
📈 *波动率*: ${volatility}%

*技术分析*:
• MA7: \$$ma_7
• MA25: \$$ma_25
• RSI: $rsi
• 信号: $tech_signal

*情绪分析*:
• 得分: $sentiment_score/100
• 信号: $sentiment_signal

*综合信号*:
• 得分: $final_score
• 操作: $action
• 置信度: $confidence"

  if [[ "$action" == "建议买入" ]] || [[ "$action" == "可以买入" ]]; then
    message="$message

*风险管理*:
• 止损: \$$stop_loss (-5%)
• 止盈1: \$$take_profit_1 (+5%)
• 止盈2: \$$take_profit_2 (+10%)
• 仓位: 10-20%"
  fi

  message="$message

---
⚠️ 仅供参考，不构成投资建议
📅 $(date '+%Y-%m-%d %H:%M')"

  curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
    -d "chat_id=${TELEGRAM_CHAT_ID}" \
    -d "text=${message}" \
    -d "parse_mode=Markdown" > /dev/null

  if [[ $? -eq 0 ]]; then
    log "✅ Telegram notification sent!"
  else
    log "❌ Failed to send Telegram notification"
  fi
else
  log ""
  log "⚠️  Telegram notification disabled"
fi

log ""
log "========================================="
log "Analysis Complete"
log "========================================="
