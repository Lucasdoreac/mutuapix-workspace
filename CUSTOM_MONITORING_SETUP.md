# 🔧 Custom Monitoring Setup (curl-based)

**Created:** 2025-10-18
**Alternative to:** UptimeRobot free plan
**Advantages:** 100% control, no limitations, free forever, customizable

---

## 🎯 Why Custom Monitoring?

**UptimeRobot Free Plan Limitations:**
- ❌ No keyword monitoring (requires $7/mo)
- ❌ Only 5-minute intervals
- ❌ Limited to 50 monitors
- ❌ 2-month log retention only

**Custom curl Script Benefits:**
- ✅ Unlimited keyword checks
- ✅ Any interval you want (1 min, 30 sec, etc.)
- ✅ Unlimited monitors
- ✅ Forever log retention
- ✅ Custom notification logic
- ✅ 100% free
- ✅ Full control over data

---

## 📦 What's Included

**Script:** `scripts/monitor-health.sh`

**Features:**
- ✅ Frontend monitoring (HTTP 200 check + response time)
- ✅ Backend API monitoring (HTTP 200 check + response time)
- ✅ SSL certificate monitoring (expiration detection)
- ✅ Status change detection (up → down, down → up)
- ✅ Slack notifications (optional)
- ✅ Email notifications (optional)
- ✅ State persistence (detects changes between runs)
- ✅ Colored terminal output
- ✅ Response time tracking
- ✅ Timeout handling

**Monitored URLs:**
1. `https://matrix.mutuapix.com/login` (Frontend)
2. `https://api.mutuapix.com/api/v1/health` (Backend API)
3. `https://matrix.mutuapix.com` (SSL Certificate)

---

## 🚀 Quick Setup (2 minutes)

### Step 1: Test Script Manually

```bash
cd /Users/lucascardoso/Desktop/MUTUA
./scripts/monitor-health.sh
```

**Expected output:**
```
[INFO] 🚀 Starting MutuaPIX health check...

[INFO] Checking Frontend (https://matrix.mutuapix.com/login)...
[INFO] ✅ Frontend is UP (HTTP 200, 692ms)

[INFO] Checking Backend API (https://api.mutuapix.com/api/v1/health)...
[INFO] ✅ Backend API is UP (HTTP 200, 574ms)

[INFO] Checking SSL certificate (https://matrix.mutuapix.com)...
[INFO] ✅ SSL certificate valid (45 days remaining)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
[INFO] 📊 Summary:

  Frontend:    ✅ UP (692ms)
  Backend API: ✅ UP (574ms)
  SSL Cert:    ✅ Valid (45 days remaining)

[INFO] ✅ No status changes detected
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 2: Setup Cron Job (Run Every 5 Minutes)

```bash
# Edit crontab
crontab -e

# Add this line (replace /path/to with actual path):
*/5 * * * * /Users/lucascardoso/Desktop/MUTUA/scripts/monitor-health.sh >> /var/log/mutuapix-monitor.log 2>&1
```

**What it does:**
- Runs every 5 minutes
- Logs output to `/var/log/mutuapix-monitor.log`
- Detects status changes and sends notifications

### Step 3: Configure Notifications (Optional)

#### Option A: Slack Notifications

```bash
# Set environment variable
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# Run with Slack notifications
./scripts/monitor-health.sh --notify-slack
```

Or add to crontab:
```bash
*/5 * * * * SLACK_WEBHOOK_URL="https://hooks.slack.com/services/..." /path/to/monitor-health.sh --notify-slack >> /var/log/mutuapix-monitor.log 2>&1
```

#### Option B: Email Notifications

```bash
# Install mailutils (if not installed)
sudo apt-get install mailutils  # Ubuntu/Debian
# OR
brew install mailutils  # macOS

# Set email
export EMAIL_TO="your@email.com"

# Run with email notifications
./scripts/monitor-health.sh --notify-email
```

Or add to crontab:
```bash
*/5 * * * * EMAIL_TO="your@email.com" /path/to/monitor-health.sh --notify-email >> /var/log/mutuapix-monitor.log 2>&1
```

#### Option C: Both Slack + Email

```bash
./scripts/monitor-health.sh --notify-slack --notify-email
```

---

## 📊 How It Works

### Status Detection

**First Run:**
```
State file doesn't exist
→ Creates /tmp/mutuapix-monitor-state.json
→ Saves: frontend=up, backend=up, ssl=valid
→ No notifications sent (initial state)
```

**Subsequent Runs:**
```
Loads previous state from file
Checks current status
Compares: previous vs current

If status changed:
  - Frontend up → down: Send alert
  - Backend down → up: Send recovery notification
  - SSL valid → expiring: Send warning
```

### State File Format

**Location:** `/tmp/mutuapix-monitor-state.json`

**Content:**
```json
{
    "frontend": "up",
    "backend": "up",
    "ssl": "valid",
    "timestamp": "2025-10-18T14:58:50Z"
}
```

### HTTP Check Logic

```bash
# Make request with 30-second timeout
curl --connect-timeout 30 --max-time 30 https://matrix.mutuapix.com/login

# Capture:
- HTTP status code (200, 404, 500, etc.)
- Response time in milliseconds
- Connection errors (timeout, refused)

# Determine status:
- HTTP 200 → UP
- HTTP 000 (connection failed) → DOWN (timeout)
- HTTP 4xx/5xx → DOWN (error code)
```

### SSL Check Logic

```bash
# Get certificate expiration date
openssl s_client -connect matrix.mutuapix.com:443 | openssl x509 -noout -enddate

# Calculate days until expiration
expiry_date - current_date = days_remaining

# Determine status:
- days < 0 → EXPIRED
- days < 7 → EXPIRING (warning)
- days >= 7 → VALID
```

---

## 🔔 Notification Examples

### Slack Notification (Frontend Down)

```json
{
  "text": "🚨 MutuaPIX Health Alert",
  "attachments": [{
    "color": "danger",
    "title": "Health Monitor Alert",
    "text": "Frontend is DOWN\nURL: https://matrix.mutuapix.com/login\nHTTP Code: 500",
    "fields": [
      {"title": "Environment", "value": "Production"},
      {"title": "Timestamp", "value": "2025-10-18T14:58:50Z"}
    ]
  }]
}
```

**Slack appearance:**
```
🚨 MutuaPIX Health Alert

[RED] Health Monitor Alert
Frontend is DOWN
URL: https://matrix.mutuapix.com/login
HTTP Code: 500

Environment: Production
Timestamp: 2025-10-18T14:58:50Z
```

### Email Notification (Backend Down)

```
Subject: 🚨 MutuaPIX Backend DOWN

Body:
Backend API is not responding.

URL: https://api.mutuapix.com/api/v1/health
HTTP Code: timeout
Time: Fri Oct 18 14:58:50 UTC 2025
```

### Email Notification (SSL Expiring)

```
Subject: ⚠️ MutuaPIX SSL Certificate Expiring

Body:
SSL certificate expiring soon.

URL: https://matrix.mutuapix.com
Days remaining: 5
Action: Run certbot renew
```

---

## 📈 Monitoring Dashboard (View Logs)

### View Recent Checks (Last 10)

```bash
tail -n 50 /var/log/mutuapix-monitor.log
```

### View Only Summaries

```bash
grep "Summary:" -A 10 /var/log/mutuapix-monitor.log
```

### View Alerts Only

```bash
grep -E "(went DOWN|recovered|EXPIRED|expiring)" /var/log/mutuapix-monitor.log
```

### Count Downtime Events

```bash
grep "went DOWN" /var/log/mutuapix-monitor.log | wc -l
```

### Calculate Uptime (last 24 hours)

```bash
# Total checks in 24h = 24 * 60 / 5 = 288 checks
total_checks=288

# Count DOWN events
down_count=$(grep -c "went DOWN" /var/log/mutuapix-monitor.log)

# Calculate uptime percentage
uptime=$(echo "scale=2; (1 - $down_count / $total_checks) * 100" | bc)
echo "Uptime: ${uptime}%"
```

---

## 🛠️ Customization

### Change Check Interval

**Every 1 minute:**
```bash
* * * * * /path/to/monitor-health.sh
```

**Every 30 seconds (requires two cron entries):**
```bash
* * * * * /path/to/monitor-health.sh
* * * * * sleep 30; /path/to/monitor-health.sh
```

**Every 10 minutes:**
```bash
*/10 * * * * /path/to/monitor-health.sh
```

### Add More URLs to Monitor

Edit `monitor-health.sh`:

```bash
# Add new URL
PAYMENT_URL="https://api.mutuapix.com/api/v1/payments/health"

# Add check in main()
payment_result=$(check_http "$PAYMENT_URL" "Payment API")
```

### Change Timeout

Edit `monitor-health.sh`:

```bash
# Default: 30 seconds
TIMEOUT=30

# Increase to 60 seconds
TIMEOUT=60
```

### Enable Keyword Checking (Custom)

Add to `check_http()` function:

```bash
check_http() {
    local url=$1
    local name=$2
    local keyword=$3  # NEW: expected keyword

    # Make request and save response
    local response=$(curl -s --connect-timeout 30 "$url")
    local http_code=$(curl -s -o /dev/null -w "%{http_code}" "$url")

    # Check if keyword exists in response
    if echo "$response" | grep -q "$keyword"; then
        echo "✅ $name is UP and contains keyword '$keyword'"
    else
        echo "❌ $name returned 200 but missing keyword '$keyword'"
    fi
}
```

Usage:
```bash
check_http "$FRONTEND_URL" "Frontend" "Login"
check_http "$BACKEND_URL" "Backend API" '"status":"ok"'
```

---

## 🔍 Troubleshooting

### Issue: "mail: command not found"

**Fix:**
```bash
# macOS
brew install mailutils

# Ubuntu/Debian
sudo apt-get install mailutils

# Or disable email notifications
./scripts/monitor-health.sh  # Without --notify-email
```

### Issue: SSL check returns "error"

**Possible causes:**
1. OpenSSL not installed
2. Firewall blocking port 443
3. Domain name resolution failed

**Debug:**
```bash
# Test OpenSSL connection manually
openssl s_client -connect matrix.mutuapix.com:443

# Check DNS resolution
nslookup matrix.mutuapix.com

# Test with verbose curl
curl -v https://matrix.mutuapix.com
```

### Issue: Cron job not running

**Check cron logs:**
```bash
# macOS
log show --predicate 'subsystem == "com.apple.cron"' --last 1h

# Linux
grep CRON /var/log/syslog
```

**Verify crontab:**
```bash
crontab -l
```

**Test script manually:**
```bash
/bin/bash /full/path/to/monitor-health.sh
```

### Issue: Notifications not sending

**Slack webhook:**
```bash
# Test webhook manually
curl -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d '{"text":"Test notification"}'
```

**Email:**
```bash
# Test mail command
echo "Test email" | mail -s "Test" your@email.com
```

---

## 📊 Comparison: Custom vs UptimeRobot

| Feature | Custom Script | UptimeRobot Free | UptimeRobot Paid |
|---------|---------------|------------------|------------------|
| **HTTP monitoring** | ✅ Unlimited | ✅ 50 monitors | ✅ 50-100 |
| **Interval** | ✅ Any (30s, 1m, etc.) | ❌ 5 min only | ✅ 1 min |
| **Keyword check** | ✅ Custom code | ❌ Not available | ✅ Yes ($7/mo) |
| **Response time** | ✅ Tracked | ✅ Tracked | ✅ Tracked |
| **SSL monitoring** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Notifications** | ✅ Slack, Email | ✅ Email only | ✅ SMS, Phone |
| **Log retention** | ✅ Forever | ❌ 2 months | ✅ Forever |
| **Status page** | ❌ DIY | ❌ No | ✅ Yes |
| **Cost** | ✅ $0 | ✅ $0 | ❌ $7-20/mo |
| **Setup time** | ⏱️ 5 min | ⏱️ 5 min | ⏱️ 10 min |

---

## 🎯 Recommended Setup

**For MVP/Production:**

1. **Run script every 5 minutes** (same as UptimeRobot free)
2. **Enable Slack notifications** (faster than email)
3. **Keep logs for 30 days** (use logrotate)
4. **Monitor response time trends** (add to docs weekly)

**Cron configuration:**
```bash
# Run every 5 minutes with Slack notifications
*/5 * * * * SLACK_WEBHOOK_URL="https://hooks.slack.com/..." /Users/lucascardoso/Desktop/MUTUA/scripts/monitor-health.sh --notify-slack >> /var/log/mutuapix-monitor.log 2>&1

# Rotate logs weekly (keep 4 weeks)
0 0 * * 0 logrotate /etc/logrotate.d/mutuapix-monitor
```

**Logrotate config** (`/etc/logrotate.d/mutuapix-monitor`):
```
/var/log/mutuapix-monitor.log {
    weekly
    rotate 4
    compress
    missingok
    notifempty
}
```

---

## ✅ Success Criteria

Monitoring is working when:

- [ ] Script runs without errors
- [ ] All 3 checks return UP status
- [ ] State file created at `/tmp/mutuapix-monitor-state.json`
- [ ] Cron job running every 5 minutes
- [ ] Logs writing to `/var/log/mutuapix-monitor.log`
- [ ] Test alert received (pause → down → notification)
- [ ] Response times < 2 seconds consistently

**Estimated setup time:** 5 minutes (2 min test + 3 min cron setup)

---

## 🚀 Next Steps

### Immediate:
1. Test script manually: `./scripts/monitor-health.sh`
2. Setup cron job: `crontab -e`
3. Configure Slack webhook (if using)

### Optional:
1. Add more URLs to monitor
2. Implement keyword checking
3. Create dashboard from logs
4. Setup log rotation

### Future Enhancements:
1. Grafana dashboard integration
2. Historical uptime graphs
3. SLA tracking and reporting
4. Automated incident response

---

**Documentation Created:** 2025-10-18
**Script Location:** `scripts/monitor-health.sh`
**State File:** `/tmp/mutuapix-monitor-state.json`
**Log File:** `/var/log/mutuapix-monitor.log`

🎯 **Custom monitoring setup complete! 100% free, unlimited features.**
