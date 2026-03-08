---
name: btc-monitor
description: "Bitcoin trading signal system combining OKX price data, X/Twitter sentiment analysis, and Telegram notifications. Provides technical analysis (MA, RSI), sentiment scoring, risk management suggestions, and automated alerts."
compatibility: Requires curl, jq, bc. Optional: XAI_TOKEN for sentiment analysis, TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID for notifications.
license: MIT
metadata:
  author: wukaige
  version: "1.0.0"
---

# Bitcoin Trading Signal Monitor

综合比特币交易信号系统，结合技术分析、情绪分析和风险管理。

## 功能特点

### 1. 技术分析（免费 - OKX API）
- 实时价格监控
- 移动平均线（MA7, MA25, MA99）
- RSI 相对强弱指标
- 趋势判断（金叉/死叉）

### 2. 情绪分析（可选 - X API）
- X/Twitter 社交媒体情绪
- 看涨/看跌关键词统计
- 情绪得分（-100 到 +100）

### 3. 综合信号
- 技术分析权重：60%
- 情绪分析权重：40%
- 信号等级：STRONG BUY / BUY / HOLD / SELL / STRONG SELL

### 4. 风险管理
- 自动计算止损位（-5%）
- 止盈建议（+5%, +10%）
- 仓位管理建议（10-20%）

### 5. 通知系统
- Telegram 实时推送
- 详细分析报告
- 历史数据保存

## 环境变量配置

在 `~/.envrc` 中配置（不要提交到 git）：

```bash
# X/Twitter API（可选，用于情绪分析）
export XAI_TOKEN="your_twitter_bearer_token"

# Telegram Bot（可选，用于通知）
export TELEGRAM_BOT_TOKEN="your_bot_token"
export TELEGRAM_CHAT_ID="your_chat_id"
```

## 使用方法

### 基本用法

```bash
# 运行完整分析（技术 + 情绪 + 通知）
/btc-monitor

# 仅技术分析（免费）
/btc-monitor --tech-only

# 仅价格查询
/btc-monitor --price-only

# 查看历史信号
/btc-monitor --history
```

### 定时监控

```bash
# 每天 2 次（推荐）
/btc-monitor --schedule daily

# 每 4 小时
/btc-monitor --schedule 4h

# 每小时（仅技术分析，免费）
/btc-monitor --schedule hourly --tech-only
```

## 信号解读

### 技术指标

- **金叉**：短期 MA > 长期 MA → 看涨
- **死叉**：短期 MA < 长期 MA → 看跌
- **RSI > 70**：超买，可能回调
- **RSI < 30**：超卖，可能反弹

### 综合信号

| 信号 | 操作建议 | 置信度 |
|------|---------|--------|
| 🟢 STRONG BUY | 建议买入 | 高 |
| 🟢 BUY | 可以买入 | 中 |
| ⚪ HOLD | 持有观望 | 低 |
| 🔴 SELL | 可以卖出 | 中 |
| 🔴 STRONG SELL | 建议卖出 | 高 |

## 风险管理原则

1. **仓位管理**：单次交易不超过总资金 10-20%
2. **止损纪律**：严格执行 -5% 止损
3. **止盈策略**：+5% 卖出 50%，+10% 全部卖出
4. **情绪控制**：不追涨杀跌，不满仓操作

## 成本说明

- **OKX 价格数据**：完全免费
- **X 情绪分析**：约 $0.10/次（20 条推文）
- **Telegram 通知**：完全免费

### 成本优化

- **免费模式**：仅技术分析，无限次使用
- **经济模式**：每天 2 次，月成本约 $6
- **标准模式**：每 4 小时，月成本约 $15

## 文件说明

- `scripts/btc_trading_signals.sh` - 完整分析系统
- `scripts/bitcoin_analysis.sh` - 价格 + 情绪分析
- `scripts/bitcoin_sentiment.sh` - 纯情绪分析
- `docs/TRADING_GUIDE.md` - 详细使用指南

## ⚠️ 免责声明

1. 本系统仅供学习和参考，不构成投资建议
2. 加密货币交易风险极高，可能损失全部本金
3. 请根据自身情况谨慎决策，风险自负
4. 建议从小额开始，积累经验后再增加投入

## 示例输出

```
🔍 Bitcoin Trading Signal Analysis
===================================

📊 Technical Analysis (OKX)
  Current Price: $67,199.6
  24h Change: -1.2%
  MA7: $72,207.03
  MA25: $72,636.24
  MA99: $69,843.83
  RSI(14): 64.80
  🔴 Bearish: 价格在短期均线之下

🎯 Sentiment Analysis (X/Twitter)
  Tweets analyzed: 20
  Bullish mentions: 1
  Bearish mentions: 3
  Sentiment Score: -25/100
  ⚪ Market Sentiment: NEUTRAL

🎲 Signal Generation
  Technical Score: -1/2
  Sentiment Score: -25/100
  Final Score: -0.40
  Signal: 🔴 SELL
  Action: 可以卖出
  Confidence: 中

⚠️ Risk Management
  24h Volatility: 2.00%
  建议出场价: $67,199.6
  如持有多单，建议止损离场

📱 Telegram notification sent!
✅ Analysis Complete
```

## 技术栈

- **数据源**：OKX REST API, X/Twitter API
- **通知**：Telegram Bot API
- **依赖**：bash, curl, jq, bc
- **存储**：JSON 格式历史数据

## 更新日志

### v1.0.0 (2026-03-08)
- 初始版本
- 技术分析（MA, RSI）
- 情绪分析（X/Twitter）
- Telegram 通知
- 风险管理建议
