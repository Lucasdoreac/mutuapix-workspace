# Quick Deploy Commands - Production Deployment

**PR:** #36 - https://github.com/golberdoria/mutuapix-api/pull/36
**Status:** ⏳ Awaiting approval
**When Ready:** Copy and paste these commands sequentially

---

## ⚡ Quick Reference

**Deployment Time:** 45-60 minutes
**Rollback Time:** <5 minutes
**Server:** 49.13.26.142 (api.mutuapix.com)

---

## 📋 Pre-Deployment Checklist (5 min)

```bash
# 1. Verify PR is merged
gh pr view 36 --json state,mergedAt

# 2. Check production health
curl -s https://api.mutuapix.com/api/v1/health | jq .

# 3. Verify SSH access
ssh root@49.13.26.142 'echo "SSH OK"'

# 4. Check PM2 status
ssh root@49.13.26.142 'pm2 status'
```

---

## 🔧 Phase 1: Backup (5 min)

```bash
# Connect to production server
ssh root@49.13.26.142

# Navigate to project directory
cd /var/www/mutuapix-api

# Create database backup
php artisan db:backup --compress

# Verify backup created
ls -lh storage/backups/ | tail -1

# Create code backup
cd /var/www
tar -czf ~/mutuapix-api-backup-$(date +%Y%m%d-%H%M%S).tar.gz \
  --exclude="node_modules" \
  --exclude="vendor" \
  --exclude="storage/logs" \
  mutuapix-api/

# Verify backup created
ls -lh ~/*.tar.gz | tail -1

# Stay connected for next phase
```

---

## 📦 Phase 2: Deploy Code (15 min)

```bash
# Still connected to server from Phase 1
cd /var/www/mutuapix-api

# Pull latest code from main branch
git fetch origin
git checkout main
git pull origin main

# Verify correct commit
git log --oneline -3
# Should show commits: 2c69290, a5c2cd0, 95b286a

# Install/update dependencies
composer install --no-dev --optimize-autoloader

# Clear all caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Optimize for production
php artisan config:cache
php artisan route:cache
php artisan view:cache
```

---

## 🗄️ Phase 3: Database Migration (10 min)

```bash
# Still connected, in /var/www/mutuapix-api

# Check pending migrations
php artisan migrate:status

# Run migrations (creates support_tickets tables)
php artisan migrate --force

# Verify migrations ran successfully
php artisan migrate:status | grep support_tickets
# Should show:
# [2025_10_19_192807] CreateSupportTicketsTable ........ Ran
# [2025_10_19_192826] CreateSupportTicketMessagesTable . Ran

# Seed permissions (adds gerenciar_suporte)
php artisan db:seed --class=PermissionSeeder --force

# Verify permission created
php artisan tinker
>>> \Spatie\Permission\Models\Permission::where('name', 'gerenciar_suporte')->exists();
# Should return: true
>>> exit
```

---

## 🔄 Phase 4: Restart Services (5 min)

```bash
# Still connected to server

# Restart Laravel API
pm2 restart mutuapix-api

# Restart Laravel Reverb (if applicable)
pm2 restart laravel-reverb

# Wait 10 seconds for services to stabilize
sleep 10

# Verify services are running
pm2 status

# Check logs for any errors
pm2 logs mutuapix-api --lines 50 --nostream
```

---

## ✅ Phase 5: Verification (15 min)

```bash
# Exit SSH (Ctrl+D or type 'exit')
exit

# From your local machine:

# 1. Health check
curl -s https://api.mutuapix.com/api/v1/health | jq .
# Expected: {"status": "ok"}

# 2. Test authentication (get a token first)
# Login via frontend or use existing test account

# 3. Test Support Tickets endpoint (requires auth token)
TOKEN="your-jwt-token-here"

# List tickets (should return empty array or user's tickets)
curl -H "Authorization: Bearer $TOKEN" \
  https://api.mutuapix.com/api/v1/support/tickets

# Create test ticket
curl -X POST https://api.mutuapix.com/api/v1/support/tickets \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "subject": "Test Deployment",
    "description": "Testing Support Tickets after deployment",
    "priority": "low"
  }'

# Should return 201 with ticket data

# 4. Test PIX validation (requires auth token)
curl -H "Authorization: Bearer $TOKEN" \
  https://api.mutuapix.com/api/v1/pix-help/dashboard

# 5. Check Laravel logs for any errors
ssh root@49.13.26.142 'tail -100 /var/www/mutuapix-api/storage/logs/laravel.log'

# If no errors, deployment successful! ✅
```

---

## 📊 Phase 6: Post-Deployment Monitoring (Ongoing)

```bash
# Monitor logs in real-time (optional)
ssh root@49.13.26.142 'tail -f /var/www/mutuapix-api/storage/logs/laravel.log'

# Check PM2 metrics
ssh root@49.13.26.142 'pm2 monit'

# Check database for new tickets
ssh root@49.13.26.142
cd /var/www/mutuapix-api
php artisan tinker
>>> \App\Models\SupportTicket::count();
>>> \App\Models\SupportTicket::latest()->first();
>>> exit
exit
```

---

## 🚨 Rollback Procedure (If Needed)

**Only use if deployment fails or critical errors occur**

```bash
# Connect to server
ssh root@49.13.26.142

# 1. Rollback code
cd /var/www
# Find latest backup
ls -lt ~/*.tar.gz | head -1

# Extract backup (replace timestamp with actual)
tar -xzf ~/mutuapix-api-backup-YYYYMMDD-HHMMSS.tar.gz

# 2. Rollback database
cd /var/www/mutuapix-api
# Find latest backup
ls -lt storage/backups/ | head -1

# Restore database (replace filename with actual)
mysql -u mutuapix_app -p mutuapix_production < storage/backups/backup-YYYYMMDD-HHMMSS.sql

# 3. Restart services
pm2 restart mutuapix-api

# 4. Verify rollback
curl -s https://api.mutuapix.com/api/v1/health | jq .

# Exit
exit
```

**Rollback Time:** <5 minutes

---

## 🎯 Success Criteria

After deployment, verify:

- [x] Health endpoint returns `{"status": "ok"}`
- [x] PM2 shows `mutuapix-api` as `online`
- [x] Support Tickets endpoints respond (GET, POST)
- [x] PIX validation endpoints respond
- [x] No errors in Laravel logs
- [x] Database has `support_tickets` tables
- [x] Permission `gerenciar_suporte` exists

---

## 📞 If Something Goes Wrong

### Common Issues

**1. Migration Fails**
```bash
# Check migration status
php artisan migrate:status

# Rollback last migration
php artisan migrate:rollback --step=1

# Try again
php artisan migrate --force
```

**2. Permission Not Created**
```bash
# Re-run seeder
php artisan db:seed --class=PermissionSeeder --force

# Verify
php artisan tinker
>>> \Spatie\Permission\Models\Permission::pluck('name');
```

**3. Services Won't Start**
```bash
# Check PM2 logs
pm2 logs mutuapix-api --lines 100

# Check Laravel logs
tail -100 /var/www/mutuapix-api/storage/logs/laravel.log

# Restart with full reset
pm2 delete mutuapix-api
pm2 start ecosystem.config.js
```

**4. 500 Errors**
```bash
# Check logs
tail -100 /var/www/mutuapix-api/storage/logs/laravel.log

# Clear all caches
php artisan cache:clear
php artisan config:clear
php artisan route:clear
php artisan view:clear

# Restart
pm2 restart mutuapix-api
```

---

## 🔍 Troubleshooting Commands

```bash
# Check disk space
df -h

# Check memory usage
free -h

# Check database connection
php artisan tinker
>>> \DB::connection()->getPdo();

# Check queue status
php artisan queue:failed

# Check scheduled tasks
php artisan schedule:list

# View specific migration
php artisan migrate:status | grep support

# Test database query
php artisan tinker
>>> \App\Models\SupportTicket::query()->toSql();
```

---

## 📝 Deployment Checklist

**Before Starting:**
- [ ] PR #36 approved and merged
- [ ] Team notified of deployment time
- [ ] Backup window scheduled (low traffic)
- [ ] SSH access verified
- [ ] This guide open and ready

**During Deployment:**
- [ ] Phase 1: Backup complete (5 min)
- [ ] Phase 2: Code deployed (15 min)
- [ ] Phase 3: Migrations run (10 min)
- [ ] Phase 4: Services restarted (5 min)
- [ ] Phase 5: Verification passed (15 min)

**After Deployment:**
- [ ] Health check passing
- [ ] All 6 features tested manually
- [ ] No errors in logs
- [ ] Team notified of success
- [ ] Monitoring for 24-48 hours

---

## ⏱️ Timeline Reference

| Phase | Duration | Start | End |
|-------|----------|-------|-----|
| Pre-Check | 5 min | T+0 | T+5 |
| Backup | 5 min | T+5 | T+10 |
| Deploy Code | 15 min | T+10 | T+25 |
| Migrations | 10 min | T+25 | T+35 |
| Restart | 5 min | T+35 | T+40 |
| Verify | 15 min | T+40 | T+55 |
| **Total** | **55 min** | **T+0** | **T+55** |

---

## 🎉 Deployment Complete!

After successful verification, send team notification:

```
✅ DEPLOYMENT COMPLETE

MVP 100% deployed to production successfully!

Features deployed:
✅ Support Tickets system (Feature #6)
✅ PIX email validation
✅ Critical bug fixes

Status:
✅ Health check: OK
✅ All endpoints responding
✅ Migrations complete
✅ No errors in logs
✅ PM2 services online

Next: Monitoring for 24-48 hours

PR: https://github.com/golberdoria/mutuapix-api/pull/36
```

---

**Quick Deploy Guide - Ready to Use**
**Last Updated:** 2025-10-19
**PR:** #36 - Awaiting approval
