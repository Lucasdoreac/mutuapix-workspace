#!/bin/bash
set -euo pipefail

##############################################################################
# Slack Notification Script - MutuaPIX
#
# Usage: ./notify-slack.sh <webhook_url> <message> [emoji] [color]
#
# Examples:
#   ./notify-slack.sh "$SLACK_WEBHOOK" "Deployment successful" "✅" "good"
#   ./notify-slack.sh "$SLACK_WEBHOOK" "Deployment failed" "❌" "danger"
##############################################################################

# Arguments
WEBHOOK_URL="${1:-}"
MESSAGE="${2:-}"
EMOJI="${3:-📢}"
COLOR="${4:-#36a64f}"  # Default: green

# Validate arguments
if [ -z "$WEBHOOK_URL" ]; then
  echo "Error: Webhook URL is required"
  echo "Usage: $0 <webhook_url> <message> [emoji] [color]"
  exit 1
fi

if [ -z "$MESSAGE" ]; then
  echo "Error: Message is required"
  echo "Usage: $0 <webhook_url> <message> [emoji] [color]"
  exit 1
fi

# Get git info (if in git repo)
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
  GIT_BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
  GIT_COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
  GIT_AUTHOR=$(git log -1 --pretty=format:'%an' 2>/dev/null || echo "unknown")
else
  GIT_BRANCH="N/A"
  GIT_COMMIT="N/A"
  GIT_AUTHOR="N/A"
fi

# Get timestamp
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

# Send notification to Slack
curl -X POST "$WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d '{
    "text": "'"$EMOJI"' '"$MESSAGE"'",
    "blocks": [
      {
        "type": "header",
        "text": {
          "type": "plain_text",
          "text": "'"$EMOJI"' MutuaPIX Notification"
        }
      },
      {
        "type": "section",
        "fields": [
          {
            "type": "mrkdwn",
            "text": "*Message:*\n'"$MESSAGE"'"
          },
          {
            "type": "mrkdwn",
            "text": "*Time:*\n'"$TIMESTAMP"'"
          }
        ]
      },
      {
        "type": "section",
        "fields": [
          {
            "type": "mrkdwn",
            "text": "*Branch:*\n`'"$GIT_BRANCH"'`"
          },
          {
            "type": "mrkdwn",
            "text": "*Commit:*\n`'"$GIT_COMMIT"'`"
          }
        ]
      },
      {
        "type": "context",
        "elements": [
          {
            "type": "mrkdwn",
            "text": "Triggered by: '"$GIT_AUTHOR"' | Environment: Production"
          }
        ]
      }
    ]
  }'

# Check if notification was sent successfully
if [ $? -eq 0 ]; then
  echo "✅ Slack notification sent successfully"
  exit 0
else
  echo "❌ Failed to send Slack notification"
  exit 1
fi
