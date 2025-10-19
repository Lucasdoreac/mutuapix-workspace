# 💬 Slack Notifications Setup - MutuaPIX

**Created:** 2025-10-18 00:20 BRT
**Status:** ✅ READY - Script created, needs webhook URL
**Purpose:** Real-time deployment and system alerts

---

## 📋 Quick Setup (5 minutes)

1. Create Slack incoming webhook
2. Add webhook URL to environment variables
3. Test notification script
4. Integrate with deployment workflows

---

## 🚀 Step 1: Create Slack Webhook

### Option A: New Slack App (Recommended)

1. **Go to:** https://api.slack.com/apps
2. **Click:** "Create New App"
3. **Choose:** "From scratch"
4. **Fill in:**
   - App Name: `MutuaPIX Notifications`
   - Workspace: (select your workspace)
5. **Click:** "Create App"

6. **Navigate to:** "Incoming Webhooks"
7. **Toggle:** "Activate Incoming Webhooks" ON
8. **Click:** "Add New Webhook to Workspace"
9. **Select Channel:** `#mutuapix-alerts` (or create new channel)
10. **Click:** "Allow"

11. **Copy Webhook URL:**
```
https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX
```

### Option B: Legacy Incoming Webhooks

1. **Go to:** https://[your-workspace].slack.com/apps/manage/custom-integrations
2. **Click:** "Incoming Webhooks"
3. **Click:** "Add to Slack"
4. **Choose Channel:** `#mutuapix-alerts`
5. **Click:** "Add Incoming WebHooks integration"
6. **Copy Webhook URL**

---

## 🔐 Step 2: Configure Environment Variables

### For Local Development

**Add to `~/.zshrc` or `~/.bashrc`:**
```bash
# Slack Webhook for MutuaPIX
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
```

**Reload shell:**
```bash
source ~/.zshrc  # or ~/.bashrc
```

### For GitHub Actions

1. **Go to:** Repository Settings → Secrets and variables → Actions
2. **Click:** "New repository secret"
3. **Name:** `SLACK_WEBHOOK_URL`
4. **Value:** (paste webhook URL)
5. **Click:** "Add secret"

### For Production Server (VPS)

**Backend (49.13.26.142):**
```bash
ssh root@49.13.26.142

# Add to .env or environment
echo 'SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL' >> /var/www/mutuapix-api/.env
```

**Frontend (138.199.162.115):**
```bash
ssh root@138.199.162.115

# Add to PM2 ecosystem config
# Edit ecosystem.config.js
```

---

## 🧪 Step 3: Test Notification

### Using the Script

```bash
# Navigate to scripts directory
cd /Users/lucascardoso/Desktop/MUTUA/scripts

# Test basic notification
./notify-slack.sh \
  "$SLACK_WEBHOOK_URL" \
  "Test notification from MutuaPIX" \
  "🧪" \
  "good"

# Test success notification
./notify-slack.sh \
  "$SLACK_WEBHOOK_URL" \
  "Deployment completed successfully" \
  "✅" \
  "good"

# Test failure notification
./notify-slack.sh \
  "$SLACK_WEBHOOK_URL" \
  "Deployment failed - rolling back" \
  "❌" \
  "danger"
```

### Expected Result in Slack

You should see a message in `#mutuapix-alerts`:

```
🧪 MutuaPIX Notification

Message: Test notification from MutuaPIX
Time: 2025-10-18 00:20:00 UTC

Branch: main
Commit: abc1234

Triggered by: Your Name | Environment: Production
```

---

## 🔗 Step 4: Integration Examples

### Example 1: Manual Deployment Notification

```bash
# Before deployment
./scripts/notify-slack.sh \
  "$SLACK_WEBHOOK_URL" \
  "🚀 Starting backend deployment to production" \
  "🚀"

# After successful deployment
./scripts/notify-slack.sh \
  "$SLACK_WEBHOOK_URL" \
  "✅ Backend deployment completed successfully" \
  "✅" \
  "good"

# After failed deployment
./scripts/notify-slack.sh \
  "$SLACK_WEBHOOK_URL" \
  "❌ Backend deployment failed - check logs" \
  "❌" \
  "danger"
```

### Example 2: GitHub Actions Integration

**Add to `.github/workflows/deploy-backend.yml`:**

```yaml
name: Deploy Backend

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      # ... deployment steps ...

      - name: Notify Slack - Success
        if: success()
        run: |
          curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
            -H 'Content-Type: application/json' \
            -d '{
              "text": "✅ Backend deployment successful",
              "blocks": [{
                "type": "section",
                "text": {
                  "type": "mrkdwn",
                  "text": "*Backend Deployment Complete*\n✅ Status: Success\n🚀 Environment: Production\n📝 Commit: ${{ github.sha }}\n👤 Author: ${{ github.actor }}"
                }
              }]
            }'

      - name: Notify Slack - Failure
        if: failure()
        run: |
          curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
            -H 'Content-Type: application/json' \
            -d '{
              "text": "❌ Backend deployment failed",
              "blocks": [{
                "type": "section",
                "text": {
                  "type": "mrkdwn",
                  "text": "*Backend Deployment Failed*\n❌ Status: Failure\n🚨 Environment: Production\n📝 Commit: ${{ github.sha }}\n🔗 Logs: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
                }
              }]
            }'
```

### Example 3: Deploy-Conscious Integration

**Add to `.claude/commands/deploy-conscious.md`:**

```bash
# At start of deployment
./scripts/notify-slack.sh \
  "$SLACK_WEBHOOK_URL" \
  "🚀 Starting conscious deployment: {{target}}" \
  "🚀"

# After each stage
./scripts/notify-slack.sh \
  "$SLACK_WEBHOOK_URL" \
  "✅ Stage complete: Pre-deployment validation" \
  "✅"

# Final success
./scripts/notify-slack.sh \
  "$SLACK_WEBHOOK_URL" \
  "🎉 Deployment complete: All 8 stages passed" \
  "🎉" \
  "good"

# Final failure
./scripts/notify-slack.sh \
  "$SLACK_WEBHOOK_URL" \
  "❌ Deployment failed: Automatic rollback initiated" \
  "❌" \
  "danger"
```

---

## 📊 Notification Types

### Deployment Notifications

```bash
# Starting
./scripts/notify-slack.sh "$SLACK_WEBHOOK_URL" "🚀 Deployment starting..." "🚀"

# Success
./scripts/notify-slack.sh "$SLACK_WEBHOOK_URL" "✅ Deployment successful" "✅" "good"

# Failure
./scripts/notify-slack.sh "$SLACK_WEBHOOK_URL" "❌ Deployment failed" "❌" "danger"

# Rollback
./scripts/notify-slack.sh "$SLACK_WEBHOOK_URL" "⏪ Rolling back deployment" "⏪" "warning"
```

### Health/Monitoring Alerts

```bash
# System down
./scripts/notify-slack.sh "$SLACK_WEBHOOK_URL" "🔴 Frontend is DOWN" "🔴" "danger"

# System recovered
./scripts/notify-slack.sh "$SLACK_WEBHOOK_URL" "🟢 Frontend is UP" "🟢" "good"

# Performance degradation
./scripts/notify-slack.sh "$SLACK_WEBHOOK_URL" "⚠️ Response time > 1s" "⚠️" "warning"
```

### Code Quality Alerts

```bash
# Tests failed
./scripts/notify-slack.sh "$SLACK_WEBHOOK_URL" "❌ Tests failed on PR #123" "❌" "danger"

# Lighthouse CI regression
./scripts/notify-slack.sh "$SLACK_WEBHOOK_URL" "⚠️ Performance score dropped to 75%" "⚠️" "warning"

# Security vulnerability
./scripts/notify-slack.sh "$SLACK_WEBHOOK_URL" "🔒 Security alert: High severity CVE" "🔒" "danger"
```

---

## 🎨 Customization

### Custom Message Format

Create a custom notification script:

```bash
#!/bin/bash
# scripts/deploy-notification.sh

WEBHOOK="$1"
STATUS="$2"  # success|failure|warning
TARGET="$3"  # frontend|backend

case $STATUS in
  success)
    EMOJI="✅"
    COLOR="good"
    MESSAGE="Deployment to $TARGET completed successfully"
    ;;
  failure)
    EMOJI="❌"
    COLOR="danger"
    MESSAGE="Deployment to $TARGET failed"
    ;;
  warning)
    EMOJI="⚠️"
    COLOR="warning"
    MESSAGE="Deployment to $TARGET completed with warnings"
    ;;
esac

./notify-slack.sh "$WEBHOOK" "$MESSAGE" "$EMOJI" "$COLOR"
```

### Rich Formatting

**Add buttons and actions:**

```bash
curl -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d '{
    "text": "Deployment requires approval",
    "blocks": [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "*Production Deployment Ready*\nClick to approve or reject"
        }
      },
      {
        "type": "actions",
        "elements": [
          {
            "type": "button",
            "text": {"type": "plain_text", "text": "Approve"},
            "style": "primary",
            "url": "https://github.com/org/repo/actions"
          },
          {
            "type": "button",
            "text": {"type": "plain_text", "text": "Reject"},
            "style": "danger",
            "url": "https://github.com/org/repo/actions"
          }
        ]
      }
    ]
  }'
```

---

## 🔔 Integration with Monitoring Tools

### Sentry → Slack

**In Sentry Dashboard:**
1. Settings → Integrations → Slack
2. Authorize workspace
3. Configure alert rules:
   - New issue in production
   - Error rate > 10/hour
   - Performance degradation

### UptimeRobot → Slack

**In UptimeRobot:**
1. My Settings → Alert Contacts
2. Add Alert Contact → Webhook
3. URL: `$SLACK_WEBHOOK_URL`
4. POST Value:
```json
{
  "text": "*monitorFriendlyName* is *monitorAlertType*"
}
```

### Lighthouse CI → Slack

**In GitHub Actions:**
```yaml
- name: Notify Slack - Lighthouse Results
  run: |
    SCORE=$(jq '.[] | .summary.performance' .lighthouseci/manifest.json)
    curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
      -H 'Content-Type: application/json' \
      -d "{\"text\": \"Lighthouse CI: Performance score is ${SCORE}%\"}"
```

---

## 🛠️ Troubleshooting

### Webhook Not Working

**Error:** `Invalid webhook URL`

**Fix:**
```bash
# Test webhook manually
curl -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d '{"text": "Test message"}'

# Should return: "ok"
```

### Message Not Appearing in Channel

**Cause:** App not added to channel

**Fix:**
```
1. Go to Slack channel (#mutuapix-alerts)
2. Type: /invite @MutuaPIX Notifications
3. Press Enter
```

### Rate Limiting

**Error:** `rate_limited`

**Cause:** Too many messages sent too quickly

**Limits:**
- 1 message per second per webhook
- Burst limit: 60 messages per minute

**Fix:**
```bash
# Add delay between notifications
sleep 2
./scripts/notify-slack.sh ...
```

---

## 📅 Best Practices

### 1. Use Channels Wisely

```
#mutuapix-deployments  → Deployment notifications
#mutuapix-alerts       → System health alerts
#mutuapix-errors       → Error tracking (Sentry)
#mutuapix-performance  → Lighthouse CI results
```

### 2. Avoid Notification Spam

**Bad:**
```bash
# Every step (too many notifications)
notify "Starting step 1"
notify "Completed step 1"
notify "Starting step 2"
notify "Completed step 2"
```

**Good:**
```bash
# Only important milestones
notify "🚀 Deployment starting"
# ... all steps ...
notify "✅ Deployment complete"
```

### 3. Use Threads for Related Messages

```bash
# Parent message
TIMESTAMP=$(curl -X POST ... | jq -r '.ts')

# Thread replies (requires ts from parent)
curl -X POST ... -d "{\"thread_ts\": \"$TIMESTAMP\", ...}"
```

### 4. Include Actionable Information

**Bad:**
```
"Error occurred"
```

**Good:**
```
"❌ Deployment failed
📝 Commit: abc1234
🔗 Logs: https://...
🔧 Action: Check logs for details"
```

---

## ✅ Setup Completion Checklist

**Slack Configuration:**
- [ ] Slack app created
- [ ] Incoming webhook generated
- [ ] Channel #mutuapix-alerts created
- [ ] Bot added to channel

**Environment Variables:**
- [ ] `SLACK_WEBHOOK_URL` set locally
- [ ] `SLACK_WEBHOOK_URL` added to GitHub Secrets
- [ ] Webhook URL documented securely

**Testing:**
- [ ] Test notification sent successfully
- [ ] Message received in correct channel
- [ ] Formatting looks correct
- [ ] Git info populated correctly

**Integration:**
- [ ] Deployment scripts updated
- [ ] GitHub Actions configured
- [ ] Monitoring tools integrated
- [ ] Team notified of new alerts

---

## 📚 Resources

**Official Docs:**
- Slack API: https://api.slack.com/
- Incoming Webhooks: https://api.slack.com/messaging/webhooks
- Block Kit: https://api.slack.com/block-kit

**Tools:**
- Block Kit Builder: https://app.slack.com/block-kit-builder/
- Message Formatter: https://api.slack.com/tools/block-kit-builder

---

**Setup Status:** ✅ READY
**Script Created:** `scripts/notify-slack.sh`
**Next Action:** Create Slack webhook and test
**Estimated Time:** 5-10 minutes

💬 **Slack notifications ready to keep your team informed!**
