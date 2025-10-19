#!/bin/bash
#
# Slack Alerts Interactive Setup Script
#
# This script guides you through configuring Slack webhooks for monitoring alerts.
#
# Usage:
#   ./setup-slack-alerts.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}║        Slack Alerts Setup - Interactive Configuration     ║${NC}"
echo -e "${BLUE}║                                                            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Step 1: Create Incoming Webhook
echo -e "${GREEN}Step 1: Create Slack Incoming Webhook${NC}"
echo ""
echo "1. Go to: https://api.slack.com/messaging/webhooks"
echo "2. Click 'Create your Slack app'"
echo "3. Choose 'From scratch'"
echo "4. App Name: MutuaPIX Monitoring"
echo "5. Workspace: Select your workspace"
echo "6. Click 'Create App'"
echo ""
echo "7. In the app settings:"
echo "   → Features → Incoming Webhooks"
echo "   → Activate Incoming Webhooks: ON"
echo "   → Click 'Add New Webhook to Workspace'"
echo ""
echo "8. Select channel: #mutuapix-alerts (or create it)"
echo "9. Click 'Allow'"
echo ""
read -p "Have you created the webhook? (y/n): " webhook_created

if [[ "$webhook_created" != "y" ]]; then
    echo -e "${YELLOW}Please create the webhook first, then run this script again.${NC}"
    exit 0
fi

echo ""
echo -e "${GREEN}✓ Webhook created${NC}"
echo ""

# Step 2: Get Webhook URL
echo -e "${GREEN}Step 2: Copy Webhook URL${NC}"
echo ""
echo "The webhook URL looks like:"
echo "  https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX"
echo ""
read -p "Paste your Slack Webhook URL: " webhook_url

if [[ -z "$webhook_url" ]]; then
    echo -e "${RED}Error: Webhook URL is required${NC}"
    exit 1
fi

# Validate URL format
if [[ ! "$webhook_url" =~ ^https://hooks\.slack\.com/services/.+ ]]; then
    echo -e "${RED}Error: Invalid Slack webhook URL format${NC}"
    echo "Expected format: https://hooks.slack.com/services/..."
    exit 1
fi

echo ""
echo -e "${GREEN}✓ Webhook URL validated${NC}"
echo ""

# Step 3: Test Webhook
echo -e "${GREEN}Step 3: Test Webhook${NC}"
echo ""
read -p "Send test message to Slack? (y/n): " send_test

if [[ "$send_test" == "y" ]]; then
    echo "Sending test message..."

    response=$(curl -X POST "$webhook_url" \
        -H 'Content-Type: application/json' \
        -d '{
            "text": "✅ MutuaPIX Monitoring Alerts Configured",
            "attachments": [{
                "color": "good",
                "title": "Test Alert",
                "text": "This is a test message from the monitoring setup script.",
                "footer": "MutuaPIX Health Monitor",
                "ts": '"$(date +%s)"'
            }]
        }' 2>&1)

    if [[ "$response" == "ok" ]]; then
        echo -e "${GREEN}✓ Test message sent successfully!${NC}"
        echo "  Check your #mutuapix-alerts channel"
    else
        echo -e "${YELLOW}⚠️  Response: $response${NC}"
        echo "  If you see the message in Slack, it's working!"
    fi
fi

echo ""

# Generate configuration
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Configuration Complete! ✓${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}Add these lines to your production .env file:${NC}"
echo ""
echo -e "${BLUE}# Slack Monitoring Alerts${NC}"
cat << EOF

# Slack Webhook Configuration
SLACK_WEBHOOK_URL=$webhook_url

# Optional: Email alerts as backup
EMAIL_TO=admin@mutuapix.com
EOF

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Save to file
config_file="slack-config-$(date +%Y%m%d-%H%M%S).txt"
cat > "$config_file" << EOF
# Slack Alerts Configuration
# Generated: $(date)

SLACK_WEBHOOK_URL=$webhook_url
EMAIL_TO=admin@mutuapix.com
EOF

echo -e "${GREEN}✓ Configuration saved to: $config_file${NC}"
echo ""

# Next steps
echo -e "${YELLOW}Next Steps:${NC}"
echo ""
echo "1. SSH to production backend:"
echo "   ${BLUE}ssh root@49.13.26.142${NC}"
echo ""
echo "2. Edit .env file:"
echo "   ${BLUE}nano /var/www/mutuapix-api/.env${NC}"
echo ""
echo "3. Add the configuration above (or from $config_file)"
echo ""
echo "4. Test monitoring alert:"
echo "   ${BLUE}cd /var/www/mutuapix-api${NC}"
echo "   ${BLUE}SLACK_WEBHOOK_URL='$webhook_url' ./scripts/queue-health-check.sh --alert-slack${NC}"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Alert types
echo -e "${YELLOW}Alerts You'll Receive:${NC}"
echo ""
echo "📊 Queue Worker Health:"
echo "  - Stalled workers (0 jobs processed in 60s)"
echo "  - High failed jobs (>100 in failed_jobs table)"
echo ""
echo "🔍 System Monitoring:"
echo "  - Frontend down"
echo "  - Backend API down"
echo "  - SSL certificate expiring (<7 days)"
echo ""
echo "💾 Backup Issues:"
echo "  - Backup too old (>24 hours)"
echo "  - Backup too small (<1MB)"
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}Setup Complete! 🚀${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Test all alert types after deployment!${NC}"
echo ""
