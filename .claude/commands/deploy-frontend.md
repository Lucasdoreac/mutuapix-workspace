# Deploy Frontend Changes

Deploy code changes to frontend production server.

## Prerequisites

- Changes tested locally
- Frontend builds successfully: `npm run build`
- File paths verified

## Steps

### 1. Upload File

```bash
scp <LOCAL_FILE> root@138.199.162.115:/var/www/mutuapix-frontend-production/<TARGET_PATH>
```

### 2. Clear Cache & Restart

```bash
ssh root@138.199.162.115 'cd /var/www/mutuapix-frontend-production && rm -rf .next && pm2 restart mutuapix-frontend'
```

### 3. Monitor Logs

```bash
ssh root@138.199.162.115 'pm2 logs mutuapix-frontend --lines 50'
```

### 4. Verify

```bash
curl -I https://matrix.mutuapix.com/login 2>&1 | grep HTTP
```

## Example Usage

Deploy a component change:

```bash
# Upload
scp src/components/auth/login-container.tsx \
    root@138.199.162.115:/var/www/mutuapix-frontend-production/src/components/auth/

# Clear cache & restart
ssh root@138.199.162.115 'cd /var/www/mutuapix-frontend-production && rm -rf .next && pm2 restart mutuapix-frontend'

# Verify
curl -I https://matrix.mutuapix.com/login
```

## Important Notes

**ALWAYS clear `.next` cache** before restarting frontend. Next.js caches aggressively and changes won't appear without this step.

## Rollback

If deployment fails:

```bash
# Restore from VPS backup
ssh root@138.199.162.115 'cd /var/www && tar -xzf ~/mutuapix-frontend-backup-YYYYMMDD-HHMMSS.tar.gz'

# Clear cache & restart
ssh root@138.199.162.115 'cd /var/www/mutuapix-frontend-production && rm -rf .next && pm2 restart mutuapix-frontend'
```
