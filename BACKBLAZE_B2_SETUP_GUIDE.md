# Backblaze B2 Setup Guide - Quick Start

**Estimated Time:** 30 minutes
**Cost:** $0.11/month for 1.35GB (first 10GB free)
**Status:** Ready to implement

---

## Why Backblaze B2?

**3-2-1 Backup Strategy:**
- ✅ **3 copies:** Production DB + Local backup + B2 backup
- ✅ **2 media types:** Server disk + Cloud storage
- ✅ **1 off-site:** B2 (different location from servers)

**Current Risk:** All backups on same disk as production (single point of failure)

**B2 Benefits:**
- Cheapest S3-compatible storage ($0.005/GB/month)
- S3-compatible API (Laravel supports natively)
- Simple setup (15 minutes)
- Automatic retention policies
- Instant restore capability

---

## Step-by-Step Setup

### Step 1: Create Backblaze Account (5 minutes)

**1.1 Sign Up:**
```
URL: https://www.backblaze.com/b2/sign-up.html
```

**Fill in:**
- Email: your-email@example.com
- Password: (secure password)
- Company: MutuaPIX (or your name)

**1.2 Verify Email:**
- Check email for verification link
- Click to activate account

**1.3 First Login:**
- URL: https://secure.backblaze.com/user_signin.htm
- Enter credentials

---

### Step 2: Create B2 Bucket (3 minutes)

**2.1 Navigate to B2 Cloud Storage:**
```
Dashboard → B2 Cloud Storage → Buckets → Create a Bucket
```

**2.2 Bucket Settings:**
```
Bucket Name: mutuapix-backups
Files in Bucket: Private
Default Encryption: Disable (optional - saves cost)
Object Lock: Disable
```

**2.3 Click "Create a Bucket"**

**Result:** Bucket created at:
```
s3://mutuapix-backups
```

---

### Step 3: Create Application Key (5 minutes)

**3.1 Navigate to App Keys:**
```
Dashboard → B2 Cloud Storage → Application Keys → Add a New Application Key
```

**3.2 Key Settings:**
```
Name of Key: mutuapix-api-backup
Allow access to Bucket(s): mutuapix-backups (select from dropdown)
Type of Access: Read and Write
Allow List All Bucket Names: No (not needed)
File name prefix: (leave empty)
Duration: (leave empty - does not expire)
```

**3.3 Click "Create New Key"**

**IMPORTANT:** Save these credentials immediately (shown only once):
```
keyID: 005a1b2c3d4e5f6g7h8i9j
applicationKey: K005AbCdEfGhIjKlMnOpQrStUvWxYz1234567890
```

**⚠️ CRITICAL:** Copy these to a secure location (1Password, Vault) NOW!

---

### Step 4: Configure Laravel Backend (5 minutes)

**4.1 Add to `.env` (production server):**

SSH to backend server:
```bash
ssh root@49.13.26.142
cd /var/www/mutuapix-api
nano .env
```

Add these lines:
```bash
# Backblaze B2 Configuration
BACKUP_OFFSITE_ENABLED=true
BACKUP_OFFSITE_DISK=s3
BACKUP_OFFSITE_PATH=backups/database/

# AWS S3-compatible settings for B2
AWS_ACCESS_KEY_ID=005a1b2c3d4e5f6g7h8i9j
AWS_SECRET_ACCESS_KEY=K005AbCdEfGhIjKlMnOpQrStUvWxYz1234567890
AWS_DEFAULT_REGION=us-west-001
AWS_BUCKET=mutuapix-backups
AWS_ENDPOINT=https://s3.us-west-001.backblazeb2.com
AWS_USE_PATH_STYLE_ENDPOINT=true

# Retention Policy
BACKUP_OFFSITE_DAILY_RETENTION=30
BACKUP_OFFSITE_WEEKLY_RETENTION=12
BACKUP_OFFSITE_MONTHLY_RETENTION=12
```

**4.2 Save and exit:**
```bash
Ctrl+O (save)
Ctrl+X (exit)
```

**4.3 Clear config cache:**
```bash
php artisan config:clear
php artisan config:cache
```

---

### Step 5: Test Backup Upload (5 minutes)

**5.1 Create test backup:**
```bash
php artisan db:backup --compress
```

**Expected output:**
```
Starting database backup...
Backing up database: mutuapix_production
Compressing backup...
✓ Backup created successfully: mutuapix_production_2025-10-19_140000.sql.gz

Uploading to off-site storage (s3)...
✓ Upload completed: backups/database/mutuapix_production_2025-10-19_140000.sql.gz
Size: 24.5 MB
Location: s3://mutuapix-backups/backups/database/
```

**5.2 Verify in B2 Dashboard:**
```
Dashboard → B2 Cloud Storage → Buckets → mutuapix-backups → Browse Files
```

**Should see:**
```
backups/database/mutuapix_production_2025-10-19_140000.sql.gz
Size: 24.5 MB
Uploaded: 2025-10-19 14:00:00
```

---

### Step 6: Test Backup Download & Restore (5 minutes)

**6.1 List available backups:**
```bash
php artisan db:backup:list --storage=s3
```

**Expected output:**
```
Available backups on s3:
  mutuapix_production_2025-10-19_140000.sql.gz (24.5 MB) - 2025-10-19 14:00:00
```

**6.2 Download backup (dry-run):**
```bash
# Just download, don't restore
aws s3 cp s3://mutuapix-backups/backups/database/mutuapix_production_2025-10-19_140000.sql.gz /tmp/test-restore.sql.gz --endpoint-url https://s3.us-west-001.backblazeb2.com
```

**6.3 Verify download:**
```bash
ls -lh /tmp/test-restore.sql.gz
# Should show: 24.5 MB

rm /tmp/test-restore.sql.gz
```

---

### Step 7: Automate Daily Off-Site Backups (2 minutes)

**7.1 Verify cron is configured:**

Already configured in `app/Console/Kernel.php`:
```php
$schedule->command('db:backup --compress')->daily();
```

**7.2 Test schedule:**
```bash
php artisan schedule:list
```

**Should show:**
```
0 0 * * * php artisan db:backup --compress ... Next Due: Tomorrow at 00:00
```

**✅ Done!** Backups will automatically upload to B2 daily at midnight.

---

## Verification Checklist

After setup, verify:

- [ ] Backblaze account created
- [ ] Bucket `mutuapix-backups` exists
- [ ] Application key created and saved
- [ ] .env updated with B2 credentials
- [ ] Test backup uploaded successfully
- [ ] Backup visible in B2 dashboard
- [ ] Download test completed
- [ ] Daily schedule verified

**Status:** 8/8 = Ready for production

---

## Cost Estimation

### Current Usage Estimate

**Database Size:** ~50 MB (compressed)

**Monthly Backups:**
- Daily: 30 backups × 50 MB = 1.5 GB
- Weekly: 12 backups × 50 MB = 600 MB (kept separately)
- Monthly: 12 backups × 50 MB = 600 MB (kept separately)
- **Total storage:** ~2.7 GB

### B2 Pricing

**Storage:**
- First 10 GB: FREE
- Above 10 GB: $0.005/GB/month
- **Our usage (2.7 GB):** $0/month (within free tier)

**Download:**
- First 1 GB/day: FREE
- Above 1 GB: $0.01/GB
- **Our usage (restore ~1/month):** $0/month (within free tier)

**API Calls:**
- Class C (writes): $0.004 per 10,000 calls
- Daily backup = 1 call/day = 30 calls/month
- **Cost:** $0.000012/month (~$0)

**Total Monthly Cost:** ~$0.00 (within free tier) 🎉

**When to pay:**
- If DB grows to >100 MB: ~$0.20/month
- If restoring multiple times/month: ~$0.10/month
- **Max expected:** $0.50/month (worst case)

---

## Monitoring & Alerts

### Monitor Backup Success

**Add to monitoring script:**
```bash
# Check last B2 backup age
LAST_BACKUP=$(aws s3 ls s3://mutuapix-backups/backups/database/ --endpoint-url https://s3.us-west-001.backblazeb2.com | tail -1)
BACKUP_AGE=$(date -d "$(echo $LAST_BACKUP | awk '{print $1,$2}')" +%s)
CURRENT_TIME=$(date +%s)
AGE_HOURS=$(( (CURRENT_TIME - BACKUP_AGE) / 3600 ))

if [ $AGE_HOURS -gt 26 ]; then
    echo "⚠️ Last B2 backup is $AGE_HOURS hours old (expected: <24h)"
    # Send alert
fi
```

### Verify Retention Policy

**Monthly check:**
```bash
# Count backups in B2
aws s3 ls s3://mutuapix-backups/backups/database/ --endpoint-url https://s3.us-west-001.backblazeb2.com | wc -l

# Expected: ~54 backups (30 daily + 12 weekly + 12 monthly)
```

---

## Troubleshooting

### Issue #1: Upload Failed - Access Denied

**Error:**
```
AWS Error: Access Denied (403)
```

**Fix:**
```bash
# Check credentials in .env
cat .env | grep AWS_

# Verify Application Key has read+write access
# Dashboard → App Keys → Check permissions
```

---

### Issue #2: Endpoint Not Found

**Error:**
```
Could not connect to endpoint: s3.us-west-001.backblazeb2.com
```

**Fix:**
```bash
# Check region matches bucket region
# B2 Dashboard → Bucket → Settings → Region
# Update AWS_DEFAULT_REGION in .env to match
```

---

### Issue #3: Backup Too Large (Timeout)

**Error:**
```
Upload timeout after 300 seconds
```

**Fix:**
```bash
# Increase timeout in config/backup.php
'timeout' => 900,  // 15 minutes

# Or compress backup more
php artisan db:backup --compress --optimize
```

---

## Recovery Procedure

### Scenario: Production Server Disk Failure

**Steps:**

**1. Download latest backup from B2:**
```bash
# On new server or recovered server
aws s3 cp s3://mutuapix-backups/backups/database/latest.sql.gz /tmp/restore.sql.gz \
    --endpoint-url https://s3.us-west-001.backblazeb2.com
```

**2. Restore database:**
```bash
php artisan db:restore /tmp/restore.sql.gz --force
```

**3. Verify data:**
```bash
php artisan migrate:status
mysql -u root -p -e "SELECT COUNT(*) FROM mutuapix_production.users"
```

**4. Restart services:**
```bash
pm2 restart mutuapix-api
```

**Recovery Time:** ~5-10 minutes (depending on backup size)

---

## Security Best Practices

### 1. Rotate Application Keys

**Frequency:** Every 90 days

**Process:**
1. Create new application key in B2
2. Update .env with new credentials
3. Test backup upload
4. Delete old application key

---

### 2. Encrypt Backups (Optional)

**Enable encryption:**
```bash
# In .env
BACKUP_ENCRYPTION_ENABLED=true
BACKUP_ENCRYPTION_KEY=<generate-with: openssl rand -base64 32>
```

**Note:** Adds ~10% to backup size, but protects data at rest

---

### 3. IP Allowlist (Optional)

**Restrict access to B2 bucket:**
```
B2 Dashboard → Bucket → Settings → IP Allowlist
Add: 49.13.26.142 (backend server IP)
```

**Benefit:** Only production server can access backups

---

## Alternative: DigitalOcean Spaces

If Backblaze unavailable, use DigitalOcean Spaces:

**Pricing:** $5/month (250 GB included)

**Configuration:**
```bash
AWS_ENDPOINT=https://nyc3.digitaloceanspaces.com
AWS_DEFAULT_REGION=nyc3
AWS_BUCKET=mutuapix-backups
```

**Everything else same** (S3-compatible)

---

## Completion Checklist

Before marking Roadmap #1 complete:

- [ ] Backblaze account active
- [ ] Bucket created and configured
- [ ] Application key generated and saved
- [ ] .env updated on production
- [ ] Test backup uploaded successfully
- [ ] Test download completed
- [ ] Retention policy configured
- [ ] Monitoring alerts added
- [ ] Recovery procedure tested (staging)
- [ ] Documentation updated

**Target:** 10/10 complete = Roadmap #1 DONE ✅

---

## Summary

**Setup Time:** 30 minutes
**Monthly Cost:** $0 (within free tier)
**Recovery Time:** <10 minutes
**Data Protection:** 99.999999999% (11 nines)

**Next Steps:**
1. Create Backblaze account
2. Follow steps 1-7 above
3. Verify all checklist items
4. Mark Roadmap #1 as complete

**Status:** Ready to implement - Just need account creation! 🚀

---

**Created by:** Claude Code
**Date:** 2025-10-19
**Session:** Week 2 Infrastructure
**Roadmap Item:** #1 - Off-Site Backup Implementation

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com)
