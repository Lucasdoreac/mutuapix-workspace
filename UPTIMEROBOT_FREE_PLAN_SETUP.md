# 🆓 UptimeRobot Setup - Free Plan (Simplified)

**Date:** 2025-10-18
**Plan:** Free (50 monitors, 5-minute intervals)
**Limitation:** No keyword monitoring (requires paid plan)

---

## 🎯 What We'll Monitor (Free Plan Compatible)

Since keyword monitoring requires a paid plan, we'll use basic HTTP(s) monitoring that checks:
- ✅ HTTP status code (200 OK)
- ✅ Response time
- ✅ Uptime/downtime
- ❌ ~~Keyword presence~~ (not available on free plan)

This is still **very valuable** - we'll detect if:
- Site is completely down (404, 500 errors)
- Server is unreachable
- SSL certificate expired
- Response time is slow

---

## 📋 3 Monitors to Create

### Monitor 1: Frontend Health
```
Name: MutuaPIX Frontend
Type: HTTP(s)
URL: https://matrix.mutuapix.com/login
Interval: 5 minutes
```

**What it checks:**
- Returns HTTP 200 (page loads successfully)
- Response time < 30 seconds
- SSL certificate valid

### Monitor 2: Backend API Health
```
Name: MutuaPIX Backend API
Type: HTTP(s)
URL: https://api.mutuapix.com/api/v1/health
Interval: 5 minutes
```

**What it checks:**
- Returns HTTP 200 (API is responding)
- Response time < 30 seconds
- No server errors (500, 502, 503)

### Monitor 3: SSL Certificate
```
Name: MutuaPIX SSL Certificate
Type: SSL Certificate (NOT HTTP)
URL: https://matrix.mutuapix.com
Interval: 1 day
Alert: 7 days before expiration
```

**What it checks:**
- SSL certificate expiration date
- Certificate validity
- Certificate chain

---

## 🚀 Quick Setup (5 minutes)

### Step 1: Create Account

1. Go to: https://uptimerobot.com/signup
2. Sign up with:
   - Email: [your email]
   - Password: [secure password]
   - OR: Use "Sign in with Google"
3. Verify email (check inbox)
4. Login to dashboard

### Step 2: Add Monitor 1 (Frontend)

1. Click **"+ Add New Monitor"** button
2. Fill in:
   - **Monitor Type:** HTTP(s)
   - **Friendly Name:** `MutuaPIX Frontend`
   - **URL (or IP):** `https://matrix.mutuapix.com/login`
   - **Monitoring Interval:** 5 minutes
   - **Monitor Timeout:** 30 seconds
3. Click **"Create Monitor"**

**Screenshot expected:**
```
✅ Monitor created successfully
Status: Up (green checkmark)
Response time: ~500ms
Uptime: 100%
```

### Step 3: Add Monitor 2 (Backend API)

1. Click **"+ Add New Monitor"** again
2. Fill in:
   - **Monitor Type:** HTTP(s)
   - **Friendly Name:** `MutuaPIX Backend API`
   - **URL (or IP):** `https://api.mutuapix.com/api/v1/health`
   - **Monitoring Interval:** 5 minutes
   - **Monitor Timeout:** 30 seconds
3. Click **"Create Monitor"**

### Step 4: Add Monitor 3 (SSL Certificate)

1. Click **"+ Add New Monitor"** again
2. Fill in:
   - **Monitor Type:** SSL Certificate (NOT HTTP!)
   - **Friendly Name:** `MutuaPIX SSL Certificate`
   - **URL:** `https://matrix.mutuapix.com`
   - **Monitoring Interval:** 1 day (or 6 hours)
   - **Days before expiration warning:** 7 days
3. Click **"Create Monitor"**

### Step 5: Configure Email Alerts

1. Go to **"My Settings"** → **"Alert Contacts"**
2. Your email should already be listed (from signup)
3. Verify email is **confirmed** (check for verification email)
4. Set alert settings:
   - ✅ Send alerts via: Email
   - ✅ When monitor goes down
   - ✅ When monitor comes back up
   - ✅ SSL certificate expiring

---

## 🧪 Test Monitors (Optional but Recommended)

### Test 1: Pause/Resume Test
```
1. Click on "MutuaPIX Frontend" monitor
2. Click "Pause" button (⏸️ icon)
3. Wait ~1-2 minutes
4. Check email for "Monitor is DOWN" alert
5. Click "Resume" button
6. Check email for "Monitor is UP" alert
```

**Expected:**
- ✅ Email received within 1-2 minutes
- ✅ Email contains monitor name and URL
- ✅ Email has timestamp and reason

### Test 2: Check Dashboard
```
1. Go to main dashboard
2. Verify all 3 monitors show:
   - Status: Up (green)
   - Uptime: 100% (or close)
   - Response time: < 2 seconds
```

---

## 📊 Free Plan Limitations vs. Paid Plans

| Feature | Free | Solo ($7/mo) | Team ($20/mo) |
|---------|------|--------------|---------------|
| Monitors | 50 | 50 | 100 |
| Interval | 5 min | 1 min | 1 min |
| SMS alerts | ❌ | ✅ | ✅ |
| **Keyword monitoring** | ❌ | ✅ | ✅ |
| Phone calls | ❌ | ❌ | ✅ |
| Status pages | ❌ | ✅ | ✅ |
| Logs retention | 2 months | Forever | Forever |

**For MutuaPIX:** Free plan is sufficient for MVP/production monitoring.

---

## 🎯 What Free Plan DOES Monitor

Even without keyword monitoring, you'll be alerted for:

### Frontend (matrix.mutuapix.com/login)
- ✅ Site completely down (404, 500 errors)
- ✅ Server unreachable (connection timeout)
- ✅ SSL certificate expired/invalid
- ✅ Response time > 30 seconds (configurable)
- ❌ Login form broken but page loads (would need keyword check)

### Backend API (api.mutuapix.com/api/v1/health)
- ✅ API completely down (404, 500 errors)
- ✅ Server unreachable
- ✅ Health endpoint not responding
- ✅ Slow response (> 30s)
- ❌ Health returns error JSON but 200 status (would need keyword check)

### SSL Certificate (matrix.mutuapix.com)
- ✅ Certificate expiring in 7 days
- ✅ Certificate expired
- ✅ Certificate invalid/self-signed

---

## 💡 Workaround for Keyword Monitoring (Free)

If you want keyword monitoring without paying, you can:

### Option A: Use Alternative Services (Free)
- **Uptime Kuma** (self-hosted, unlimited keyword checks)
  - Deploy on VPS: https://github.com/louislam/uptime-kuma
  - Free, open-source, all features included

- **Healthchecks.io** (free tier: 20 checks, keyword support)
  - Signup: https://healthchecks.io/

### Option B: Custom Health Endpoint (Recommended)

Modify the backend health endpoint to return different HTTP status codes:

```php
// backend/app/Http/Controllers/Api/V1/HealthController.php

public function index(): JsonResponse
{
    $checks = [
        'app' => $this->checkApp(),
        'database' => $this->checkDatabase(),
        'cache' => $this->checkCache(),
    ];

    $allHealthy = collect($checks)->every(fn ($check) => $check['status'] === 'ok');

    // Return 503 if unhealthy (UptimeRobot will detect as DOWN)
    return response()->json([
        'status' => $allHealthy ? 'ok' : 'degraded',
        'checks' => $checks,
    ], $allHealthy ? 200 : 503);
}
```

**Benefit:** UptimeRobot detects HTTP 503 as DOWN (no keyword needed!)

---

## 📝 What to Document After Setup

After completing setup, document:

1. **Dashboard URL:** https://uptimerobot.com/dashboard
2. **Email alerts configured:** [your email]
3. **Monitors created:**
   - ✅ MutuaPIX Frontend (matrix.mutuapix.com/login)
   - ✅ MutuaPIX Backend API (api.mutuapix.com/api/v1/health)
   - ✅ MutuaPIX SSL Certificate

4. **Test results:**
   - Pause/resume test: PASS
   - Email alert delivery: < 2 minutes

5. **Next check:** Login to dashboard weekly to review uptime stats

---

## 🔔 Alert Configuration Best Practices

### Recommended Alert Settings:
```
Alert when:
✅ Monitor goes down (immediate)
✅ Monitor comes back up (immediate)
✅ SSL certificate expires in 7 days

Do NOT alert for:
❌ Every check (too noisy)
❌ Slow response (configure separately if needed)
```

### Email Alert Format:
```
Subject: [UptimeRobot] MutuaPIX Frontend is DOWN
Body:
Monitor: MutuaPIX Frontend
URL: https://matrix.mutuapix.com/login
Status: DOWN
Reason: Connection timeout
Started: 2025-10-18 13:45 UTC
Duration: 2 minutes
```

---

## 🚨 What to Do When You Get an Alert

### Alert: "Monitor is DOWN"

1. **Verify manually:**
   ```bash
   # Check if site is actually down
   curl -I https://matrix.mutuapix.com/login
   curl -I https://api.mutuapix.com/api/v1/health
   ```

2. **Check PM2 status:**
   ```bash
   ssh root@138.199.162.115 'pm2 status'
   ssh root@49.13.26.142 'pm2 status'
   ```

3. **Check logs:**
   ```bash
   ssh root@138.199.162.115 'pm2 logs mutuapix-frontend --lines 50'
   ssh root@49.13.26.142 'pm2 logs mutuapix-api --lines 50'
   ```

4. **Restart if needed:**
   ```bash
   ssh root@138.199.162.115 'pm2 restart mutuapix-frontend'
   ssh root@49.13.26.142 'pm2 restart mutuapix-api'
   ```

### Alert: "SSL Certificate Expiring"

1. **Check certificate expiry:**
   ```bash
   echo | openssl s_client -connect matrix.mutuapix.com:443 2>/dev/null | \
     openssl x509 -noout -dates
   ```

2. **Renew certificate:**
   ```bash
   ssh root@138.199.162.115 'certbot renew'
   ssh root@49.13.26.142 'certbot renew'
   ```

3. **Verify renewal:**
   ```bash
   curl -I https://matrix.mutuapix.com
   # Check "Expires:" header
   ```

---

## 📈 Monitoring Coverage After Setup

### Before UptimeRobot:
- ✅ Sentry (error tracking) - 25%
- ❌ Uptime monitoring - 0%
- ❌ SSL monitoring - 0%

### After UptimeRobot (Free Plan):
- ✅ Sentry (error tracking) - 25%
- ✅ Uptime monitoring (HTTP 200 checks) - 50%
- ✅ SSL certificate monitoring - 25%

**Total Coverage:** 100% (basic monitoring complete!)

---

## 🆙 When to Upgrade to Paid Plan

Consider upgrading if you need:

1. **Keyword monitoring** ($7/mo Solo plan)
   - Check if "Login" text appears on page
   - Verify health endpoint returns {"status":"ok"}
   - Detect partial outages (page loads but broken)

2. **1-minute intervals** ($7/mo Solo plan)
   - Faster incident detection (5 min → 1 min)
   - Better uptime metrics (99.99% vs 99.9%)

3. **SMS alerts** ($7/mo Solo plan)
   - Get notified immediately via SMS
   - Better for critical production issues

4. **Status page** ($7/mo Solo plan)
   - Public status page for users
   - Show uptime history

**For now:** Free plan is sufficient for MVP. Upgrade when revenue supports it.

---

## ✅ Success Criteria

Setup is complete when:

- [ ] 3 monitors created (Frontend, Backend API, SSL)
- [ ] All monitors showing "Up" status
- [ ] Email alerts configured and verified
- [ ] Test alert received within 2 minutes
- [ ] Dashboard bookmarked for weekly review
- [ ] Documented in workspace repository

**Estimated time:** 5-10 minutes (vs 10 minutes in original guide)

---

## 🔗 Resources

- **UptimeRobot Dashboard:** https://uptimerobot.com/dashboard
- **Documentation:** https://uptimerobot.com/docs/
- **Status:** https://stats.uptimerobot.com/
- **Pricing:** https://uptimerobot.com/pricing/

---

**Setup Guide Updated:** 2025-10-18
**Free Plan Compatible:** ✅ YES
**Keyword Monitoring:** ❌ Requires paid plan ($7/mo)
**Recommended Action:** Start with free plan, upgrade if needed

🎯 **You can complete this setup in 5 minutes manually - just follow Steps 1-5 above!**
