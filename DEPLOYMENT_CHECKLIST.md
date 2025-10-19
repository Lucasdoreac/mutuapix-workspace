# ✅ Deployment Day Checklist - MVP 100%

**Date:** _____________
**Time:** _____________
**Team:** _____________
**PR:** #36 - https://github.com/golberdoria/mutuapix-api/pull/36

---

## 🚦 Pre-Flight Checks (Before Starting)

- [ ] PR #36 approved and merged to main
- [ ] Team notified (developer + technical lead available)
- [ ] Low-traffic time window selected
- [ ] QUICK_DEPLOY_COMMANDS.md guide open
- [ ] SSH access to 49.13.26.142 verified
- [ ] Coffee/water ready ☕

**Time Started:** __________ **Estimated End:** __________ (+55 min)

---

## 📋 Phase 1: Backup (5 min)

**⏱️ Start Time:** __________

- [ ] SSH to production server
- [ ] Navigate to `/var/www/mutuapix-api`
- [ ] Run `php artisan db:backup --compress`
- [ ] Verify database backup created
- [ ] Create code backup with tar
- [ ] Verify code backup created
- [ ] Backups logged (write filenames below):
  - DB: ___________________________________
  - Code: _________________________________

**⏱️ End Time:** __________ **Duration:** __________ min

---

## 📦 Phase 2: Deploy Code (15 min)

**⏱️ Start Time:** __________

- [ ] `cd /var/www/mutuapix-api`
- [ ] `git fetch origin`
- [ ] `git checkout main`
- [ ] `git pull origin main`
- [ ] Verify commits (2c69290, a5c2cd0, 95b286a)
- [ ] `composer install --no-dev --optimize-autoloader`
- [ ] Clear caches (cache, config, route, view)
- [ ] Cache for production (config, route, view)

**Git Commit Verified:** __________

**⏱️ End Time:** __________ **Duration:** __________ min

---

## 🗄️ Phase 3: Database Migration (10 min)

**⏱️ Start Time:** __________

- [ ] `php artisan migrate:status` (check pending)
- [ ] `php artisan migrate --force`
- [ ] Verify `support_tickets` tables created
- [ ] Verify `support_ticket_messages` table created
- [ ] `php artisan db:seed --class=PermissionSeeder --force`
- [ ] Verify `gerenciar_suporte` permission created (tinker)

**Migrations Status:** __________ (all ran successfully?)

**⏱️ End Time:** __________ **Duration:** __________ min

---

## 🔄 Phase 4: Restart Services (5 min)

**⏱️ Start Time:** __________

- [ ] `pm2 restart mutuapix-api`
- [ ] `pm2 restart laravel-reverb`
- [ ] Wait 10 seconds
- [ ] `pm2 status` (verify online)
- [ ] Check PM2 logs for errors

**PM2 Status:** __________ (all online?)

**⏱️ End Time:** __________ **Duration:** __________ min

---

## ✅ Phase 5: Verification (15 min)

**⏱️ Start Time:** __________

### Basic Health Checks
- [ ] Health endpoint: `https://api.mutuapix.com/api/v1/health`
  - **Result:** __________
- [ ] PM2 status: all services online
- [ ] Laravel logs: no errors

### Feature Testing (with auth token)
- [ ] **Authentication:** Login works
- [ ] **Support Tickets:** List tickets (`GET /api/v1/support/tickets`)
- [ ] **Support Tickets:** Create ticket (`POST /api/v1/support/tickets`)
- [ ] **PIX Validation:** Dashboard loads (`GET /api/v1/pix-help/dashboard`)
- [ ] **Subscriptions:** List plans (`GET /api/v1/subscriptions`)
- [ ] **Courses:** List courses (`GET /api/v1/courses`)

### Database Verification
- [ ] `support_tickets` table exists
- [ ] `support_ticket_messages` table exists
- [ ] `gerenciar_suporte` permission exists
- [ ] Test ticket created successfully

**All Tests Passed:** __________ (yes/no)

**⏱️ End Time:** __________ **Duration:** __________ min

---

## 🎯 Final Verification

- [ ] No errors in Laravel logs (last 100 lines)
- [ ] No errors in PM2 logs
- [ ] All 6 MVP features tested and working
- [ ] Database migrations all ran
- [ ] Permissions seeded correctly
- [ ] Services stable (no crashes in 5 min)

**Deployment Status:** __________ (success/rollback needed)

---

## 📊 Deployment Summary

**Total Time:** __________ minutes (target: 55 min)

**Phases Completed:**
- [ ] Backup (5 min)
- [ ] Deploy Code (15 min)
- [ ] Migrations (10 min)
- [ ] Restart (5 min)
- [ ] Verification (15 min)

**Issues Encountered:**
_______________________________________________
_______________________________________________
_______________________________________________

**Resolution:**
_______________________________________________
_______________________________________________
_______________________________________________

---

## 🚨 Rollback Decision Point

**If any verification fails, decide:**

- [ ] **Continue:** Minor issue, can be fixed without rollback
- [ ] **Rollback:** Critical failure, restore backup immediately

**If Rollback Needed:**
- [ ] Restore code backup
- [ ] Restore database backup
- [ ] Restart services
- [ ] Verify rollback successful
- [ ] Document issue for analysis

**Rollback Time:** __________ (<5 min target)

---

## ✅ Post-Deployment

### Immediate (First Hour)
- [ ] Team notified of deployment status
- [ ] Deployment summary shared
- [ ] Monitoring started (Sentry dashboard)
- [ ] Logs being watched

### First 24 Hours
- [ ] Check error rates (target: <0.1%)
- [ ] Monitor API response times (target: <500ms)
- [ ] Track Support Ticket creation
- [ ] Review user feedback
- [ ] Check database performance

### First Week
- [ ] Daily log reviews
- [ ] Performance metrics tracked
- [ ] User satisfaction monitored
- [ ] Support tickets reviewed
- [ ] Optimization opportunities identified

---

## 📞 Emergency Contacts

**Technical Lead:** _______________________________________________

**Backend Developer:** _______________________________________________

**On-Call:** _______________________________________________

**VPS Provider:** Hetzner (https://www.hetzner.com/support)

---

## 🎉 Success Notification Template

**Copy and send to team after successful deployment:**

```
✅ DEPLOYMENT COMPLETE - MVP 100%

Date: [DATE]
Time: [TIME]
Duration: [X] minutes

Features Deployed:
✅ Support Tickets system (Feature #6) - 8 new endpoints
✅ PIX email validation integration
✅ Critical bug fixes (4 fixes)

Database Changes:
✅ 2 new tables (support_tickets, support_ticket_messages)
✅ 6 strategic indexes for performance
✅ 1 new permission (gerenciar_suporte)

Status:
✅ Health check: OK
✅ All 6 MVP features: Working
✅ Migrations: Complete (2/2)
✅ PM2 services: Online
✅ Logs: No errors
✅ Tests: All endpoints responding

Next Steps:
- Monitoring for 24-48 hours
- Daily log reviews
- Performance tracking
- User feedback collection

PR: https://github.com/golberdoria/mutuapix-api/pull/36

Deployment Team: [NAMES]
```

---

## 📝 Notes & Observations

**Unexpected Behaviors:**
_______________________________________________
_______________________________________________
_______________________________________________

**Performance Notes:**
_______________________________________________
_______________________________________________
_______________________________________________

**Improvements for Next Time:**
_______________________________________________
_______________________________________________
_______________________________________________

---

## 🔖 Reference Links

- **PR #36:** https://github.com/golberdoria/mutuapix-api/pull/36
- **Deploy Commands:** QUICK_DEPLOY_COMMANDS.md
- **Full Guide:** PRODUCTION_DEPLOYMENT_GUIDE.md
- **Backend API:** https://api.mutuapix.com
- **Frontend:** https://matrix.mutuapix.com

---

**Deployment Checklist - Ready to Use**
**Version:** 1.0
**Last Updated:** 2025-10-19
**For:** MVP 100% Production Deployment
