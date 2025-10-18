# 🔔 UptimeRobot Setup Guide - MutuaPIX

**Created:** 2025-10-18 00:00 BRT
**Time Required:** 10-15 minutes
**Cost:** FREE (up to 50 monitors)

---

## 📋 Quick Setup Checklist

- [ ] Create UptimeRobot account
- [ ] Add Monitor #1: Frontend Health
- [ ] Add Monitor #2: Backend API Health
- [ ] Add Monitor #3: SSL Certificate Monitor
- [ ] Configure email alerts
- [ ] Test monitors
- [ ] (Optional) Create public status page
- [ ] Save credentials securely

---

## 🚀 Step-by-Step Setup

### Step 1: Create Account

1. Go to: https://uptimerobot.com/
2. Click "Free Sign Up"
3. Fill in:
   - Email: (your email)
   - Password: (secure password)
4. Verify email
5. Login to dashboard

**Dashboard URL:** https://uptimerobot.com/dashboard

---

### Step 2: Add Monitor #1 - Frontend Health

**Click:** "Add New Monitor"

**Configuration:**
```
Monitor Type: HTTP(s)
Friendly Name: MutuaPIX - Frontend (Login Page)
URL (or IP): https://matrix.mutuapix.com/login
Monitoring Interval: Every 5 minutes

Advanced Settings:
  Alert Contacts to Notify: (your email)
  Keyword Check: Enabled
    Type: exists
    Case Sensitive: No
    Value: Login

HTTP Settings:
  Method: GET
  Timeout: 30 seconds

Alert Notifications:
  When Down: Send notification
  When Up: Send notification
```

**Click:** "Create Monitor"

**Expected Result:**
- Status: ✅ Up
- Response Time: ~100-300ms
- Uptime: 100%

---

### Step 3: Add Monitor #2 - Backend API Health

**Click:** "Add New Monitor"

**Configuration:**
```
Monitor Type: HTTP(s)
Friendly Name: MutuaPIX - Backend API (Health Endpoint)
URL (or IP): https://api.mutuapix.com/api/v1/health
Monitoring Interval: Every 5 minutes

Advanced Settings:
  Alert Contacts to Notify: (your email)
  Keyword Check: Enabled
    Type: exists
    Case Sensitive: No
    Value: ok

HTTP Settings:
  Method: GET
  Timeout: 30 seconds

Alert Notifications:
  When Down: Send notification
  When Up: Send notification
```

**Click:** "Create Monitor"

**Expected Result:**
- Status: ✅ Up
- Response Time: ~200-500ms
- Keyword Found: "ok"

---

### Step 4: Add Monitor #3 - SSL Certificate

**Click:** "Add New Monitor"

**Configuration:**
```
Monitor Type: HTTP(s)
Friendly Name: MutuaPIX - SSL Certificate (Frontend)
URL (or IP): https://matrix.mutuapix.com
Monitoring Interval: Every 1 day

Advanced Settings:
  Alert Contacts to Notify: (your email)

SSL Settings:
  Ignore SSL errors: No
  Alert if SSL expires in: 30 days

Alert Notifications:
  When SSL expires soon: Send notification
```

**Click:** "Create Monitor"

**Expected Result:**
- Status: ✅ Up
- SSL Valid: Yes
- Expires: (check certificate expiry date)

---

### Step 5: Configure Email Alerts

**Navigate to:** My Settings → Alert Contacts

**Default Email Already Added:** Your signup email

**Optional: Add More Contacts**
1. Click "Add Alert Contact"
2. Choose type:
   - Email (free)
   - SMS (requires Pro)
   - Webhook (for Slack/Discord)
   - Push notification (mobile app)

**Recommended:** Keep email only for free tier

---

### Step 6: Test Monitors

**Test that alerts work:**

1. **Temporarily disable monitor:**
   - Click monitor name
   - Click "Pause"
   - Wait 5 minutes
   - Check email for "Down" alert

2. **Re-enable monitor:**
   - Click "Resume"
   - Wait 1 minute
   - Check email for "Up" alert

**Expected Emails:**
```
Subject: [Alert] MutuaPIX - Frontend (Login Page) is DOWN
Subject: [Alert] MutuaPIX - Frontend (Login Page) is UP
```

---

## 📊 Monitor Dashboard

### View Your Monitors

**Dashboard shows:**
- Current status (Up/Down)
- Response time graph
- Uptime percentage (7 days, 30 days, all time)
- Recent events

**Metrics to Monitor:**
```
Frontend:
  - Uptime: Should be > 99.5%
  - Response Time: ~100-300ms average
  - Status: UP

Backend API:
  - Uptime: Should be > 99.5%
  - Response Time: ~200-500ms average
  - Keyword: "ok" found

SSL:
  - Valid: Yes
  - Expires: (date)
  - Days Until Expiry: > 30
```

---

## 🔔 Alert Configuration

### Alert Settings (Recommended)

**For Each Monitor:**

1. **When to Alert:**
   - [x] When monitor goes down
   - [x] When monitor comes back up
   - [ ] Every downtime notification (disable to avoid spam)

2. **Alert Frequency:**
   - Initial alert: Immediately
   - Re-notification: After 60 minutes if still down

3. **Alert Methods:**
   - [x] Email
   - [ ] SMS (requires Pro - $7/month)
   - [ ] Webhook (for Slack - see next section)

---

## 🔗 Optional: Slack Integration

### Add Slack Webhook as Alert Contact

**Step 1: Create Slack Incoming Webhook**
1. Go to: https://api.slack.com/messaging/webhooks
2. Create new webhook
3. Choose channel (e.g., #mutuapix-alerts)
4. Copy webhook URL

**Step 2: Add to UptimeRobot**
1. My Settings → Alert Contacts
2. Add Alert Contact
3. Type: Webhook
4. URL: (paste Slack webhook URL)
5. POST Value:
```json
{
  "text": "*monitorFriendlyName* is *monitorAlertType*",
  "blocks": [
    {
      "type": "section",
      "text": {
        "type": "mrkdwn",
        "text": "*Status Change*\n🔔 Monitor: *monitorFriendlyName*\n📊 Status: *monitorAlertType*\n⏰ Time: *alertDateTime*\n🔗 URL: *monitorURL*"
      }
    }
  ]
}
```

**Slack Variables (UptimeRobot):**
- `*monitorFriendlyName*` → Monitor name
- `*monitorURL*` → Monitor URL
- `*monitorAlertType*` → DOWN or UP
- `*alertDateTime*` → Time of alert

---

## 📈 Optional: Public Status Page

**Create a status page for users:**

1. **Navigate to:** Public Status Pages
2. **Click:** "Add New Public Status Page"
3. **Configure:**
```
Name: MutuaPIX Status
Description: Real-time status of MutuaPIX services
URL: uptimerobot.com/mutuapix (or custom domain)

Monitors to Show:
  [x] Frontend (Login Page)
  [x] Backend API
  [ ] SSL Certificate (hide technical details)

Display Settings:
  Show Response Times: Yes
  Show Uptime Percentages: Yes (7 days, 30 days)
  Auto-refresh: 60 seconds
```

4. **Click:** "Create Status Page"

**Share URL with:**
- Users (transparency)
- Support team
- Stakeholders

**Example:** https://status.mutuapix.com (if custom domain configured)

---

## 🛠️ Troubleshooting

### Monitor Shows "Down" but Site Works

**Possible Causes:**

1. **Keyword not found**
   - Check page source for exact keyword
   - Case sensitivity matters
   - Keyword might be in dynamic content

   **Fix:** Adjust keyword or remove keyword check

2. **Timeout too short**
   - Server response > 30 seconds

   **Fix:** Increase timeout to 60 seconds

3. **Firewall blocking UptimeRobot**
   - Check server logs for blocked IPs

   **Fix:** Whitelist UptimeRobot IPs in nginx/firewall

**UptimeRobot IP Ranges:**
```
IPv4:
46.137.190.132
63.143.42.242
67.228.130.125
... (see full list at uptimerobot.com)
```

---

### False Positive Alerts

**If receiving too many alerts:**

1. **Increase check interval**
   - Change from 5 min → 10 min

2. **Add "Confirmation" setting**
   - Alert only after 2 consecutive failures
   - Settings → Monitor → "Confirm Before Sending Alert"

3. **Adjust timeout**
   - Increase from 30s → 60s for slow servers

---

### SSL Alerts Before Actual Expiry

**If SSL cert is valid but alerts sent:**

1. **Check expiry date:**
```bash
echo | openssl s_client -connect matrix.mutuapix.com:443 2>/dev/null | openssl x509 -noout -dates
```

2. **Adjust alert threshold:**
   - Change from 30 days → 14 days
   - Or increase to 60 days for early warning

---

## 📊 Performance Monitoring

### Expected Metrics

**Frontend (matrix.mutuapix.com/login):**
```
✅ Uptime: > 99.9% (target)
✅ Response Time: 100-300ms average
✅ Availability: 24/7
```

**Backend (api.mutuapix.com/api/v1/health):**
```
✅ Uptime: > 99.9% (target)
✅ Response Time: 200-500ms average
   (After caching: < 100ms)
✅ Keyword "ok": Always present
```

**SSL Certificate:**
```
✅ Valid: Yes
✅ Expires: > 30 days
✅ Auto-renewal: Configured (via Let's Encrypt/Certbot)
```

---

## 🔐 Security Best Practices

### Credentials Management

**Store securely:**
```
Tool: UptimeRobot
URL: https://uptimerobot.com/dashboard
Email: (your email)
Password: (use password manager)
```

**Do NOT:**
- Share credentials publicly
- Commit to git
- Use simple passwords

**Do:**
- Enable 2FA (two-factor authentication) if available
- Use strong, unique password
- Store in password manager (1Password, Bitwarden)

---

## 📅 Maintenance Schedule

### Daily (Automatic)
- UptimeRobot checks every 5 minutes
- Alerts sent if down > 5 minutes

### Weekly (Manual - 5 min)
- Review uptime percentage
- Check for any downtime incidents
- Verify response times are normal

### Monthly (Manual - 15 min)
- Review alert history
- Adjust thresholds if needed
- Check SSL certificate expiry
- Update monitor URLs if changed

---

## ✅ Setup Completion Checklist

**Account:**
- [ ] UptimeRobot account created
- [ ] Email verified
- [ ] 2FA enabled (optional but recommended)

**Monitors:**
- [ ] Frontend health monitor active
- [ ] Backend API monitor active
- [ ] SSL certificate monitor active
- [ ] All monitors showing "UP" status

**Alerts:**
- [ ] Email alerts configured
- [ ] Test alert received (pause/resume test)
- [ ] Slack webhook added (optional)

**Optional:**
- [ ] Public status page created
- [ ] Custom domain configured (optional)
- [ ] Mobile app installed (optional)

**Documentation:**
- [ ] Credentials stored securely
- [ ] Team notified of new monitors
- [ ] Escalation procedure documented

---

## 📞 Support

**UptimeRobot Support:**
- Docs: https://uptimerobot.com/api/
- Support: https://uptimerobot.com/contact/
- Status: https://status.uptimerobot.com/

**MutuaPIX Internal:**
- This guide: `UPTIMEROBOT_SETUP_GUIDE.md`
- Monitoring overview: `MONITORING_SETUP_GUIDE.md`
- Troubleshooting: See above section

---

## 🎯 Next Steps After Setup

1. **Wait 24 hours** for baseline metrics
2. **Review uptime percentage** (should be 100%)
3. **Check response time trends** (stable?)
4. **Configure Lighthouse CI** (next phase)
5. **Set up Slack notifications** (optional)

---

**Setup Guide Version:** 1.0
**Last Updated:** 2025-10-18
**Estimated Setup Time:** 10-15 minutes
**Status:** ✅ READY TO USE

🚀 **Start setup now at:** https://uptimerobot.com/
