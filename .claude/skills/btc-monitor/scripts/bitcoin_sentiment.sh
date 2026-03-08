#!/usr/bin/env bash
# Bitcoin Market Sentiment Analysis from X/Twitter
# Usage: ./bitcoin_sentiment.sh [query] [max_results]

set -euo pipefail

# Load environment variables
if [[ -f ~/.envrc ]]; then
  source ~/.envrc
fi

# Check if token exists
if [[ -z "${XAI_TOKEN:-}" ]]; then
  echo "Error: XAI_TOKEN not found in ~/.envrc"
  exit 1
fi

# Configuration
QUERY="${1:-bitcoin OR BTC OR \$BTC}"
MAX_RESULTS="${2:-100}"
API_URL="https://api.x.com/2/tweets/search/recent"
OUTPUT_FILE="bitcoin_tweets_$(date +%Y%m%d_%H%M%S).json"

echo "🔍 Searching for: $QUERY"
echo "📊 Max results: $MAX_RESULTS"
echo ""

# Fetch tweets
response=$(curl -s -X GET "$API_URL" \
  -H "Authorization: Bearer $XAI_TOKEN" \
  -G \
  --data-urlencode "query=$QUERY" \
  --data-urlencode "max_results=$MAX_RESULTS" \
  --data-urlencode "tweet.fields=created_at,public_metrics,text,lang")

# Check for errors
if echo "$response" | jq -e '.errors' > /dev/null 2>&1; then
  echo "❌ API Error:"
  echo "$response" | jq '.errors'
  exit 1
fi

# Save raw data
echo "$response" | jq '.' > "$OUTPUT_FILE"
echo "💾 Raw data saved to: $OUTPUT_FILE"
echo ""

# Extract and analyze tweets
tweet_count=$(echo "$response" | jq '.meta.result_count // 0')
echo "📈 Found $tweet_count tweets"
echo ""

if [[ $tweet_count -eq 0 ]]; then
  echo "No tweets found."
  exit 0
fi

# Sentiment analysis (simple keyword-based)
echo "🎯 Sentiment Analysis:"
echo "===================="

bullish_keywords="bullish|moon|pump|buy|long|rally|surge|breakout|ATH|all.time.high"
bearish_keywords="bearish|dump|sell|short|crash|drop|fall|bear|correction|dip"

bullish_count=$(echo "$response" | jq -r '.data[]?.text // empty' | grep -iEc "$bullish_keywords" || true)
bearish_count=$(echo "$response" | jq -r '.data[]?.text // empty' | grep -iEc "$bearish_keywords" || true)
neutral_count=$((tweet_count - bullish_count - bearish_count))

echo "🟢 Bullish: $bullish_count tweets"
echo "🔴 Bearish: $bearish_count tweets"
echo "⚪ Neutral: $neutral_count tweets"
echo ""

# Calculate sentiment percentage
if [[ $tweet_count -gt 0 ]]; then
  bullish_pct=$(awk "BEGIN {printf \"%.1f\", ($bullish_count / $tweet_count) * 100}")
  bearish_pct=$(awk "BEGIN {printf \"%.1f\", ($bearish_count / $tweet_count) * 100}")
  neutral_pct=$(awk "BEGIN {printf \"%.1f\", ($neutral_count / $tweet_count) * 100}")

  echo "📊 Sentiment Distribution:"
  echo "  Bullish: $bullish_pct%"
  echo "  Bearish: $bearish_pct%"
  echo "  Neutral: $neutral_pct%"
  echo ""
fi

# Top engaging tweets
echo "🔥 Top 5 Most Engaging Tweets:"
echo "=============================="
echo "$response" | jq -r '.data[] |
  select(.public_metrics != null) |
  {
    text: .text,
    likes: .public_metrics.like_count,
    retweets: .public_metrics.retweet_count,
    engagement: (.public_metrics.like_count + .public_metrics.retweet_count)
  } |
  "\(.engagement) engagements | \(.text[0:100])..."' |
  sort -rn |
  head -5 |
  nl

echo ""
echo "✅ Analysis complete!"
