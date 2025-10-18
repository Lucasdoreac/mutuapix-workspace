#!/bin/bash
#
# MutuaPIX Health Monitor
#
# Custom monitoring script that replaces UptimeRobot free plan functionality.
# Monitors frontend, backend API, and SSL certificate status.
# Sends notifications via Slack or email when issues are detected.
#
# Usage:
#   ./monitor-health.sh [--notify-slack] [--notify-email]
#
# Setup cron (run every 5 minutes):
#   */5 * * * * /path/to/monitor-health.sh --notify-slack >> /var/log/mutuapix-monitor.log 2>&1

set -euo pipefail

# Configuration
FRONTEND_URL="https://matrix.mutuapix.com/login"
BACKEND_URL="https://api.mutuapix.com/api/v1/health"
SSL_CHECK_URL="https://matrix.mutuapix.com"
TIMEOUT=30
STATE_FILE="/tmp/mutuapix-monitor-state.json"

# Notification settings (from environment or parameters)
NOTIFY_SLACK="${NOTIFY_SLACK:-false}"
NOTIFY_EMAIL="${NOTIFY_EMAIL:-false}"
SLACK_WEBHOOK_URL="${SLACK_WEBHOOK_URL:-}"
EMAIL_TO="${EMAIL_TO:-}"

# Parse arguments
for arg in "$@"; do
    case $arg in
        --notify-slack)
            NOTIFY_SLACK=true
            shift
            ;;
        --notify-email)
            NOTIFY_EMAIL=true
            shift
            ;;
        --help)
            echo "Usage: $0 [--notify-slack] [--notify-email]"
            echo ""
            echo "Environment variables:"
            echo "  SLACK_WEBHOOK_URL - Slack incoming webhook URL"
            echo "  EMAIL_TO          - Email address for notifications"
            exit 0
            ;;
    esac
done

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Load previous state (for detecting status changes)
load_state() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo '{"frontend":"unknown","backend":"unknown","ssl":"unknown"}'
    fi
}

# Save current state
save_state() {
    local frontend_status=$1
    local backend_status=$2
    local ssl_status=$3

    cat > "$STATE_FILE" <<EOF
{
    "frontend": "$frontend_status",
    "backend": "$backend_status",
    "ssl": "$ssl_status",
    "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF
}

# Check HTTP endpoint
check_http() {
    local url=$1
    local name=$2

    log_info "Checking $name ($url)..."

    # Make request and capture HTTP status code and response time
    local start_time=$(date +%s%N)
    local http_code
    local response_time

    http_code=$(curl -s -o /dev/null -w "%{http_code}" \
        --connect-timeout "$TIMEOUT" \
        --max-time "$TIMEOUT" \
        "$url" 2>/dev/null || echo "000")

    local end_time=$(date +%s%N)
    response_time=$(( (end_time - start_time) / 1000000 )) # Convert to milliseconds

    if [[ "$http_code" == "200" ]]; then
        log_info "✅ $name is UP (HTTP $http_code, ${response_time}ms)"
        echo "up|$http_code|$response_time"
    elif [[ "$http_code" == "000" ]]; then
        log_error "❌ $name is DOWN (Connection timeout or refused)"
        echo "down|timeout|0"
    else
        log_error "❌ $name returned HTTP $http_code (${response_time}ms)"
        echo "down|$http_code|$response_time"
    fi
}

# Check SSL certificate expiration
check_ssl() {
    local url=$1

    log_info "Checking SSL certificate ($url)..."

    # Extract hostname from URL
    local hostname=$(echo "$url" | sed -e 's|^https\?://||' -e 's|/.*||')

    # Get certificate expiration date
    local expiry_date
    expiry_date=$(echo | openssl s_client -connect "$hostname:443" -servername "$hostname" 2>/dev/null | \
        openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)

    if [[ -z "$expiry_date" ]]; then
        log_error "❌ SSL certificate check failed (connection error)"
        echo "error|0"
        return
    fi

    # Convert to epoch for comparison
    local expiry_epoch
    expiry_epoch=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$expiry_date" +%s 2>/dev/null || echo "0")

    if [[ "$expiry_epoch" == "0" ]]; then
        log_error "❌ SSL certificate date parsing failed"
        echo "error|0"
        return
    fi

    local current_epoch=$(date +%s)
    local days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))

    if [[ $days_until_expiry -lt 0 ]]; then
        log_error "❌ SSL certificate EXPIRED ${days_until_expiry#-} days ago!"
        echo "expired|$days_until_expiry"
    elif [[ $days_until_expiry -lt 7 ]]; then
        log_warn "⚠️  SSL certificate expires in $days_until_expiry days"
        echo "expiring|$days_until_expiry"
    else
        log_info "✅ SSL certificate valid ($days_until_expiry days remaining)"
        echo "valid|$days_until_expiry"
    fi
}

# Send Slack notification
notify_slack() {
    local message=$1
    local color=$2  # good, warning, danger

    if [[ "$NOTIFY_SLACK" != "true" ]] || [[ -z "$SLACK_WEBHOOK_URL" ]]; then
        return
    fi

    log_info "Sending Slack notification..."

    # Get git info if available
    local git_branch="unknown"
    local git_commit="unknown"

    if command -v git &> /dev/null; then
        git_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
        git_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    fi

    curl -X POST "$SLACK_WEBHOOK_URL" \
        -H 'Content-Type: application/json' \
        -d @- <<EOF
{
    "text": "🚨 MutuaPIX Health Alert",
    "attachments": [
        {
            "color": "$color",
            "title": "Health Monitor Alert",
            "text": "$message",
            "fields": [
                {
                    "title": "Environment",
                    "value": "Production",
                    "short": true
                },
                {
                    "title": "Timestamp",
                    "value": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
                    "short": true
                }
            ],
            "footer": "MutuaPIX Health Monitor",
            "footer_icon": "https://mutuapix.com/favicon.ico"
        }
    ]
}
EOF
}

# Send email notification
notify_email() {
    local subject=$1
    local body=$2

    if [[ "$NOTIFY_EMAIL" != "true" ]] || [[ -z "$EMAIL_TO" ]]; then
        return
    fi

    log_info "Sending email notification to $EMAIL_TO..."

    # Use mail command if available
    if command -v mail &> /dev/null; then
        echo "$body" | mail -s "$subject" "$EMAIL_TO"
    else
        log_warn "mail command not found. Install mailutils: sudo apt-get install mailutils"
    fi
}

# Main monitoring logic
main() {
    log_info "🚀 Starting MutuaPIX health check..."
    echo ""

    # Load previous state
    local prev_state
    prev_state=$(load_state)
    local prev_frontend=$(echo "$prev_state" | grep -o '"frontend":"[^"]*"' | cut -d'"' -f4)
    local prev_backend=$(echo "$prev_state" | grep -o '"backend":"[^"]*"' | cut -d'"' -f4)
    local prev_ssl=$(echo "$prev_state" | grep -o '"ssl":"[^"]*"' | cut -d'"' -f4)

    # Check frontend
    local frontend_result
    frontend_result=$(check_http "$FRONTEND_URL" "Frontend")
    local frontend_status=$(echo "$frontend_result" | cut -d'|' -f1)
    local frontend_code=$(echo "$frontend_result" | cut -d'|' -f2)
    local frontend_time=$(echo "$frontend_result" | cut -d'|' -f3)

    echo ""

    # Check backend
    local backend_result
    backend_result=$(check_http "$BACKEND_URL" "Backend API")
    local backend_status=$(echo "$backend_result" | cut -d'|' -f1)
    local backend_code=$(echo "$backend_result" | cut -d'|' -f2)
    local backend_time=$(echo "$backend_result" | cut -d'|' -f3)

    echo ""

    # Check SSL
    local ssl_result
    ssl_result=$(check_ssl "$SSL_CHECK_URL")
    local ssl_status=$(echo "$ssl_result" | cut -d'|' -f1)
    local ssl_days=$(echo "$ssl_result" | cut -d'|' -f2)

    echo ""

    # Detect status changes and send notifications
    local alerts=()

    # Frontend status change
    if [[ "$prev_frontend" != "unknown" ]] && [[ "$prev_frontend" != "$frontend_status" ]]; then
        if [[ "$frontend_status" == "down" ]]; then
            alerts+=("❌ Frontend went DOWN (was: $prev_frontend)")
            notify_slack "Frontend is DOWN\nURL: $FRONTEND_URL\nHTTP Code: $frontend_code" "danger"
            notify_email "🚨 MutuaPIX Frontend DOWN" "Frontend is not responding.\n\nURL: $FRONTEND_URL\nHTTP Code: $frontend_code\nTime: $(date)"
        else
            alerts+=("✅ Frontend recovered (was: $prev_frontend)")
            notify_slack "Frontend is back UP\nURL: $FRONTEND_URL\nResponse time: ${frontend_time}ms" "good"
            notify_email "✅ MutuaPIX Frontend UP" "Frontend is responding again.\n\nURL: $FRONTEND_URL\nResponse time: ${frontend_time}ms\nTime: $(date)"
        fi
    fi

    # Backend status change
    if [[ "$prev_backend" != "unknown" ]] && [[ "$prev_backend" != "$backend_status" ]]; then
        if [[ "$backend_status" == "down" ]]; then
            alerts+=("❌ Backend API went DOWN (was: $prev_backend)")
            notify_slack "Backend API is DOWN\nURL: $BACKEND_URL\nHTTP Code: $backend_code" "danger"
            notify_email "🚨 MutuaPIX Backend DOWN" "Backend API is not responding.\n\nURL: $BACKEND_URL\nHTTP Code: $backend_code\nTime: $(date)"
        else
            alerts+=("✅ Backend API recovered (was: $prev_backend)")
            notify_slack "Backend API is back UP\nURL: $BACKEND_URL\nResponse time: ${backend_time}ms" "good"
            notify_email "✅ MutuaPIX Backend UP" "Backend API is responding again.\n\nURL: $BACKEND_URL\nResponse time: ${backend_time}ms\nTime: $(date)"
        fi
    fi

    # SSL status change
    if [[ "$prev_ssl" != "unknown" ]] && [[ "$prev_ssl" != "$ssl_status" ]]; then
        if [[ "$ssl_status" == "expired" ]]; then
            alerts+=("❌ SSL certificate EXPIRED!")
            notify_slack "SSL certificate EXPIRED\nURL: $SSL_CHECK_URL\nExpired: $ssl_days days ago" "danger"
            notify_email "🚨 MutuaPIX SSL Certificate EXPIRED" "SSL certificate has expired!\n\nURL: $SSL_CHECK_URL\nExpired: $ssl_days days ago\nAction: Run certbot renew immediately"
        elif [[ "$ssl_status" == "expiring" ]]; then
            alerts+=("⚠️  SSL certificate expiring in $ssl_days days")
            notify_slack "SSL certificate expiring soon\nURL: $SSL_CHECK_URL\nDays remaining: $ssl_days" "warning"
            notify_email "⚠️ MutuaPIX SSL Certificate Expiring" "SSL certificate expiring soon.\n\nURL: $SSL_CHECK_URL\nDays remaining: $ssl_days\nAction: Run certbot renew"
        fi
    fi

    # Save current state
    save_state "$frontend_status" "$backend_status" "$ssl_status"

    # Print summary
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "📊 Summary:"
    echo ""
    printf "  Frontend:    "
    if [[ "$frontend_status" == "up" ]]; then
        echo -e "${GREEN}✅ UP${NC} (${frontend_time}ms)"
    else
        echo -e "${RED}❌ DOWN${NC} (HTTP $frontend_code)"
    fi

    printf "  Backend API: "
    if [[ "$backend_status" == "up" ]]; then
        echo -e "${GREEN}✅ UP${NC} (${backend_time}ms)"
    else
        echo -e "${RED}❌ DOWN${NC} (HTTP $backend_code)"
    fi

    printf "  SSL Cert:    "
    if [[ "$ssl_status" == "valid" ]]; then
        echo -e "${GREEN}✅ Valid${NC} ($ssl_days days remaining)"
    elif [[ "$ssl_status" == "expiring" ]]; then
        echo -e "${YELLOW}⚠️  Expiring${NC} ($ssl_days days remaining)"
    else
        echo -e "${RED}❌ $ssl_status${NC}"
    fi

    echo ""

    if [[ ${#alerts[@]} -gt 0 ]]; then
        log_warn "🔔 Alerts generated:"
        for alert in "${alerts[@]}"; do
            echo "    - $alert"
        done
    else
        log_info "✅ No status changes detected"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Run main function
main

exit 0
