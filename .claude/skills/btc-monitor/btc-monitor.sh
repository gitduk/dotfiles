#!/usr/bin/env bash
# Bitcoin Trading Signal Monitor - Main Entry Point
# Part of btc-monitor skill

set -euo pipefail

SKILL_DIR="$HOME/.claude/skills/btc-monitor"
SCRIPTS_DIR="$SKILL_DIR/scripts"

# Load environment variables
if [[ -f ~/.envrc ]]; then
  source ~/.envrc
fi

# Parse arguments
MODE="full"
SCHEDULE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --tech-only)
      MODE="tech"
      shift
      ;;
    --price-only)
      MODE="price"
      shift
      ;;
    --history)
      MODE="history"
      shift
      ;;
    --schedule)
      SCHEDULE="$2"
      shift 2
      ;;
    --help|-h)
      cat << 'EOF'
Bitcoin Trading Signal Monitor

Usage:
  /btc-monitor [options]

Options:
  --tech-only       仅技术分析（免费）
  --price-only      仅价格查询（免费）
  --history         查看历史信号
  --schedule <freq> 设置定时任务
                    daily   - 每天 2 次（9:00, 21:00）
                    4h      - 每 4 小时
                    hourly  - 每小时（建议配合 --tech-only）
  --help, -h        显示此帮助信息

Examples:
  /btc-monitor                    # 完整分析
  /btc-monitor --tech-only        # 仅技术分析（免费）
  /btc-monitor --price-only       # 快速查价
  /btc-monitor --history          # 查看历史
  /btc-monitor --schedule daily   # 每天 2 次定时分析

Environment Variables:
  XAI_TOKEN           - X/Twitter API token（可选）
  TELEGRAM_BOT_TOKEN  - Telegram bot token（可选）
  TELEGRAM_CHAT_ID    - Telegram chat ID（可选）

Documentation:
  $SKILL_DIR/docs/TRADING_GUIDE.md
EOF
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Handle scheduling
if [[ -n "$SCHEDULE" ]]; then
  case $SCHEDULE in
    daily)
      echo "⏰ 设置定时任务：每天 9:00 和 21:00"
      echo "运行命令："
      echo "  crontab -e"
      echo ""
      echo "添加以下行："
      echo "  0 9,21 * * * source ~/.envrc && $SCRIPTS_DIR/btc_trading_signals.sh >> ~/btc_analysis.log 2>&1"
      ;;
    4h)
      echo "⏰ 设置定时任务：每 4 小时"
      echo "运行命令："
      echo "  crontab -e"
      echo ""
      echo "添加以下行："
      echo "  0 */4 * * * source ~/.envrc && $SCRIPTS_DIR/btc_trading_signals.sh >> ~/btc_analysis.log 2>&1"
      ;;
    hourly)
      echo "⏰ 设置定时任务：每小时"
      echo "运行命令："
      echo "  crontab -e"
      echo ""
      echo "添加以下行："
      if [[ "$MODE" == "tech" ]]; then
        echo "  0 * * * * unset XAI_TOKEN && source ~/.envrc && $SCRIPTS_DIR/btc_trading_signals.sh >> ~/btc_analysis.log 2>&1"
      else
        echo "  0 * * * * source ~/.envrc && $SCRIPTS_DIR/btc_trading_signals.sh >> ~/btc_analysis.log 2>&1"
      fi
      ;;
    *)
      echo "❌ 未知的调度频率: $SCHEDULE"
      echo "支持的选项: daily, 4h, hourly"
      exit 1
      ;;
  esac
  exit 0
fi

# Execute based on mode
case $MODE in
  full)
    echo "🚀 运行完整分析（技术 + 情绪 + 通知）"
    exec "$SCRIPTS_DIR/btc_trading_signals.sh"
    ;;
  tech)
    echo "📊 运行技术分析（免费模式）"
    unset XAI_TOKEN
    exec "$SCRIPTS_DIR/btc_trading_signals.sh"
    ;;
  price)
    echo "💰 快速查价"
    exec "$SCRIPTS_DIR/bitcoin_analysis.sh"
    ;;
  history)
    echo "📜 历史信号"
    echo ""
    if ls ~/btc_signals_*.json >/dev/null 2>&1; then
      for file in ~/btc_signals_*.json; do
        echo "=== $(basename "$file") ==="
        jq -r '
          "时间: \(.timestamp)",
          "价格: $\(.price.current)",
          "信号: \(.final.signal)",
          "操作: \(.final.action)",
          "置信度: \(.final.confidence)",
          ""
        ' "$file"
      done
    else
      echo "暂无历史信号数据"
    fi
    ;;
esac
