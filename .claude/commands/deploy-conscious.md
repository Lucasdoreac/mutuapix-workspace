# Deploy with Conscious Execution

Execute a deployment with **complete pre-checks, post-checks, MCP validation, and automatic rollback capability**.

This command implements the "Conscious Execution Skill" framework for safe, validated deployments.

---

## 🎯 Target

Deploy changes to: **{{target}}** (backend or frontend)

---

## 📋 Deployment Process

### Stage 1: PRE-DEPLOYMENT VALIDATION

**Run all quality checks locally BEFORE deploying:**

#### Frontend Pre-Checks
```bash
cd frontend

# 1. Run linter
npm run lint
# Expected: ✓ No ESLint errors

# 2. Run type checker
npm run type-check
# Expected: ✓ No TypeScript errors

# 3. Run tests
npm test
# Expected: ✓ All tests passing

# 4. Test build
npm run build
# Expected: ✓ Build succeeds, .next directory created
```

#### Backend Pre-Checks
```bash
cd backend

# 1. Run formatter check
composer format-check
# Expected: ✓ No formatting issues

# 2. Run static analysis
composer lint
# Expected: ✓ PHPStan level 5 passes

# 3. Run tests
php artisan test
# Expected: ✓ All tests passing

# 4. Check database migrations
php artisan migrate:status
# Expected: ✓ All migrations run
```

**🔴 STOP if any pre-check fails. Fix issues locally first.**

---

### Stage 2: PRODUCTION HEALTH CHECK

**Verify production is healthy BEFORE deploying:**

#### Check PM2 Status
```bash
# Frontend
ssh root@138.199.162.115 'pm2 status'
# Expected: mutuapix-frontend: online

# Backend
ssh root@49.13.26.142 'pm2 status'
# Expected: mutuapix-api: online
```

#### Check Disk Space
```bash
# Frontend server
ssh root@138.199.162.115 'df -h /'
# Expected: < 80% usage

# Backend server
ssh root@49.13.26.142 'df -h /'
# Expected: < 80% usage
```

#### Check API Health
```bash
curl -s https://api.mutuapix.com/api/v1/health | jq .
# Expected: {"status": "ok"}
```

#### Check Frontend Health
```bash
curl -I https://matrix.mutuapix.com/login
# Expected: HTTP/2 200
```

**🔴 STOP if production is unhealthy. Investigate issues first.**

---

### Stage 3: CREATE BACKUP

**Always create a backup before deployment (rollback insurance):**

#### Frontend Backup
```bash
BACKUP_TIME=$(date +%Y%m%d-%H%M%S)

ssh root@138.199.162.115 "cd /var/www/mutuapix-frontend-production && \
  tar -czf ~/frontend-backup-${BACKUP_TIME}.tar.gz \
  --exclude='node_modules' \
  --exclude='.next' \
  --exclude='.git' \
  ."

# Verify backup size
ssh root@138.199.162.115 "du -sh ~/frontend-backup-${BACKUP_TIME}.tar.gz"
# Expected: > 1MB (non-zero size)
```

#### Backend Backup
```bash
BACKUP_TIME=$(date +%Y%m%d-%H%M%S)

ssh root@49.13.26.142 "cd /var/www/mutuapix-api && \
  tar -czf ~/backend-backup-${BACKUP_TIME}.tar.gz \
  --exclude='vendor' \
  --exclude='node_modules' \
  --exclude='.git' \
  --exclude='storage/logs' \
  ."

# Verify backup size
ssh root@49.13.26.142 "du -sh ~/backend-backup-${BACKUP_TIME}.tar.gz"
# Expected: > 1MB (non-zero size)
```

**🔴 STOP if backup fails or size is 0.**

---

### Stage 4: DEPLOY CODE

**Deploy files to production server:**

#### Frontend Deployment
```bash
# 1. Transfer files
rsync -avz \
  --exclude='node_modules' \
  --exclude='.next' \
  --exclude='.git' \
  frontend/src/ \
  root@138.199.162.115:/var/www/mutuapix-frontend-production/src/

# 2. Clear cache
ssh root@138.199.162.115 'cd /var/www/mutuapix-frontend-production && rm -rf .next'

# 3. Rebuild (with environment variables inline)
ssh root@138.199.162.115 'cd /var/www/mutuapix-frontend-production && \
  NODE_ENV=production \
  NEXT_PUBLIC_NODE_ENV=production \
  NEXT_PUBLIC_API_URL=https://api.mutuapix.com \
  NEXT_PUBLIC_USE_AUTH_MOCK=false \
  npm run build'

# Expected: Build succeeds in ~90-120 seconds
```

#### Backend Deployment
```bash
# 1. Transfer files
rsync -avz \
  --exclude='vendor' \
  --exclude='node_modules' \
  --exclude='.git' \
  --exclude='storage/logs' \
  backend/app/ \
  root@49.13.26.142:/var/www/mutuapix-api/app/

# 2. Run migrations (if needed)
ssh root@49.13.26.142 'cd /var/www/mutuapix-api && php artisan migrate --force'

# 3. Clear cache
ssh root@49.13.26.142 'cd /var/www/mutuapix-api && \
  php artisan cache:clear && \
  php artisan config:clear && \
  php artisan route:clear && \
  php artisan view:clear'

# 4. Optimize
ssh root@49.13.26.142 'cd /var/www/mutuapix-api && \
  php artisan config:cache && \
  php artisan route:cache && \
  php artisan view:cache'
```

---

### Stage 5: RESTART SERVICES

**Restart application servers:**

#### Frontend Restart
```bash
ssh root@138.199.162.115 'pm2 restart mutuapix-frontend'

# Wait for service to stabilize
sleep 5

# Verify PM2 status
ssh root@138.199.162.115 'pm2 status | grep mutuapix-frontend'
# Expected: online, uptime: few seconds
```

#### Backend Restart
```bash
ssh root@49.13.26.142 'pm2 restart mutuapix-api'

# Wait for service to stabilize
sleep 5

# Verify PM2 status
ssh root@49.13.26.142 'pm2 status | grep mutuapix-api'
# Expected: online, uptime: few seconds
```

**🔴 If PM2 shows "errored" or "stopped", PROCEED TO ROLLBACK (Stage 7).**

---

### Stage 6: POST-DEPLOYMENT VALIDATION

**Verify deployment was successful:**

#### Basic Health Checks
```bash
# Frontend health
curl -I https://matrix.mutuapix.com/login
# Expected: HTTP/2 200

# Backend health
curl -s https://api.mutuapix.com/api/v1/health | jq .
# Expected: {"status": "ok"}

# PM2 status
ssh root@138.199.162.115 'pm2 status'
ssh root@49.13.26.142 'pm2 status'
# Expected: Both showing "online"
```

#### MCP Chrome DevTools Validation (Frontend only)

**Use MCP to automatically verify frontend:**

```javascript
// 1. Navigate to login page
mcp__chrome-devtools__navigate_page({
  url: "https://matrix.mutuapix.com/login"
})

// 2. Take visual snapshot
mcp__chrome-devtools__take_snapshot()
// Expected: Login form visible, all elements present

// 3. Check console for errors
mcp__chrome-devtools__list_console_messages()
// Expected: No error messages (only info/log)

// 4. Monitor network requests
mcp__chrome-devtools__list_network_requests({
  resourceTypes: ["xhr", "fetch", "document"]
})
// Expected: All requests return 200 status

// 5. Take screenshot for visual regression
mcp__chrome-devtools__take_screenshot({
  filePath: `/tmp/deploy-${Date.now()}-login.png`,
  fullPage: true
})
// Expected: Screenshot saved successfully

// 6. Test critical user flow (if applicable)
// Example: Navigate to /user/dashboard
mcp__chrome-devtools__navigate_page({
  url: "https://matrix.mutuapix.com/user/dashboard"
})

// Verify redirect to login if not authenticated
// OR verify dashboard loads if authenticated
```

#### Extended Backend Validation

```bash
# Test critical endpoints
curl -X POST https://api.mutuapix.com/api/v1/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"wrong"}' \
  -s | jq .

# Expected: {"success": false, "message": "Invalid credentials"}
# (401 response is expected for wrong credentials)

# Verify queue workers running
ssh root@49.13.26.142 'ps aux | grep "queue:work"'
# Expected: At least 2 queue worker processes

# Check recent logs for errors
ssh root@49.13.26.142 'tail -n 50 /var/www/mutuapix-api/storage/logs/laravel.log | grep ERROR'
# Expected: No recent ERROR entries
```

**🔴 If any validation fails, PROCEED TO ROLLBACK (Stage 7).**

---

### Stage 7: ROLLBACK (if needed)

**If any post-validation check fails, restore from backup:**

#### Frontend Rollback
```bash
# 1. Stop current service
ssh root@138.199.162.115 'pm2 stop mutuapix-frontend'

# 2. Restore from backup
ssh root@138.199.162.115 "cd /var/www && \
  rm -rf mutuapix-frontend-production && \
  tar -xzf ~/frontend-backup-${BACKUP_TIME}.tar.gz && \
  mv frontend-production mutuapix-frontend-production"

# 3. Restart service
ssh root@138.199.162.115 'pm2 restart mutuapix-frontend'

# 4. Verify rollback
curl -I https://matrix.mutuapix.com/login
# Expected: HTTP/2 200
```

#### Backend Rollback
```bash
# 1. Stop current service
ssh root@49.13.26.142 'pm2 stop mutuapix-api'

# 2. Restore from backup
ssh root@49.13.26.142 "cd /var/www && \
  rm -rf mutuapix-api && \
  tar -xzf ~/backend-backup-${BACKUP_TIME}.tar.gz && \
  mv api mutuapix-api"

# 3. Restore database (if migrations were run)
ssh root@49.13.26.142 'cd /var/www/mutuapix-api && php artisan migrate:rollback --step=1'

# 4. Restart service
ssh root@49.13.26.142 'pm2 restart mutuapix-api'

# 5. Verify rollback
curl -s https://api.mutuapix.com/api/v1/health | jq .
# Expected: {"status": "ok"}
```

**After rollback, investigate failure cause before retrying.**

---

### Stage 8: DEPLOYMENT REPORT

**Generate comprehensive deployment report:**

```markdown
# Deployment Report - {{target}}

**Date:** $(date -u +"%Y-%m-%d %H:%M:%S UTC")
**Target:** {{target}} (production)
**Deployed By:** Claude Code (Conscious Execution Skill)

## Pre-Deployment Checks

- [ ] Linting passed
- [ ] Type checking passed (if applicable)
- [ ] Tests passed (X/X)
- [ ] Build succeeded
- [ ] Production health check passed

## Deployment Steps

- [ ] Backup created (size: X MB)
- [ ] Files transferred (X files, X MB)
- [ ] Cache cleared
- [ ] Application rebuilt/optimized
- [ ] Services restarted

## Post-Deployment Validation

### Basic Checks
- [ ] PM2 status: online
- [ ] Health endpoint: HTTP 200
- [ ] Disk space: X% used (OK/WARNING)

### MCP Validation (Frontend)
- [ ] Page loads correctly
- [ ] No console errors
- [ ] Network requests: 200 status
- [ ] Visual regression: PASS
- [ ] Critical user flows: PASS

### Extended Validation (Backend)
- [ ] API endpoints: responding
- [ ] Queue workers: running (X processes)
- [ ] Recent logs: no errors
- [ ] Database: healthy

## Rollback Status

- [x] NOT NEEDED (deployment successful)
- [ ] ROLLBACK EXECUTED (reason: ...)

## Files Deployed

- file1.ts
- file2.tsx
- ...

## Performance Metrics

- Build time: X seconds
- Deployment time: X seconds
- Downtime: 0 seconds (zero-downtime deployment)
- Total time: X minutes

## Next Steps

- [ ] Monitor logs for 15 minutes
- [ ] Check error tracking (Sentry)
- [ ] Verify user-reported issues
- [ ] Update changelog/release notes

## Status

✅ **DEPLOYMENT SUCCESSFUL** (or ❌ DEPLOYMENT FAILED - ROLLED BACK)

---

Generated by Claude Code - Conscious Execution Skill
Report saved: /tmp/deployment-report-{{target}}-$(date +%Y%m%d-%H%M%S).md
```

---

## 🎯 Success Criteria

Deployment is ONLY successful if ALL of these are true:

1. ✅ Pre-checks pass (tests, build, lint)
2. ✅ Backup created successfully
3. ✅ Deployment script exits 0 (no errors)
4. ✅ Services restart successfully (PM2 status: online)
5. ✅ Health checks return 200
6. ✅ MCP validation passes (no console errors, network 200s)
7. ✅ Extended checks pass (logs clean, queue workers running)
8. ✅ No rollback needed

**If ANY check fails → AUTOMATIC ROLLBACK**

---

## 🔄 Reflection and Correction

**If deployment fails, analyze using Chain of Thought:**

1. **Capture Error:** What was the exact error message?
2. **Analyze Root Cause:** Why did it fail?
   - Syntax error in code?
   - Missing dependency?
   - Environment variable misconfiguration?
   - Permission issue?
   - Network timeout?
3. **Identify Violation:** Which validation step was missed?
4. **Propose Fix:** How to prevent this in future?
5. **Document Learning:** Update pre-checks to catch this error class

**Example:**

```
Error: "Error: listen EACCES: permission denied 0.0.0.0:80"

Analysis (CoT):
- Root cause: Trying to bind to privileged port 80
- Violation: Did not check port permissions before deployment
- Fix: Use non-privileged port (3000) or configure nginx reverse proxy
- Learning: Add "Check port configuration" to pre-deployment checklist
```

---

## 🚨 Emergency Procedures

**If production is completely down:**

1. **Immediate Rollback** (< 2 minutes)
   ```bash
   ssh root@SERVER 'pm2 stop APP && \
     tar -xzf ~/backup-TIMESTAMP.tar.gz && \
     pm2 restart APP'
   ```

2. **Verify Restoration**
   ```bash
   curl -I https://DOMAIN/
   # Expected: HTTP 200
   ```

3. **Investigate Offline** (do not retry deployment until root cause found)

4. **Alert Team** (if applicable)

---

## 📚 Related Documentation

- [Conscious Execution Skill](.claude/skills/conscious-execution/SKILL.md)
- [Authentication Management Skill](.claude/skills/authentication-management/SKILL.md)
- [MCP Setup Guide](MCP_SETUP.md)
- [Workflow Rules](WORKFLOW_RULES_FOR_CLAUDE.md)

---

**Execute this deployment for: {{target}}**

Proceed? (This is a high-stakes operation with full validation and rollback capability)
