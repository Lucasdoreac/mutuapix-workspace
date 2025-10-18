# Deploy Backend Changes

Deploy code changes to backend production server.

## Prerequisites

- Changes tested locally
- Backend tests passing: `php artisan test`
- File paths verified

## Steps

### 1. Upload File

```bash
scp <LOCAL_FILE> root@49.13.26.142:/var/www/mutuapix-api/<TARGET_PATH>
```

### 2. Restart Backend

```bash
ssh root@49.13.26.142 'pm2 restart mutuapix-api'
```

### 3. Monitor Logs

```bash
ssh root@49.13.26.142 'pm2 logs mutuapix-api --lines 50'
```

### 4. Verify Health

```bash
curl -s https://api.mutuapix.com/api/v1/health | jq .
```

## Example Usage

Deploy a controller change:

```bash
# Upload
scp app/Http/Controllers/Api/V1/UserController.php \
    root@49.13.26.142:/var/www/mutuapix-api/app/Http/Controllers/Api/V1/

# Restart
ssh root@49.13.26.142 'pm2 restart mutuapix-api'

# Verify
curl -s https://api.mutuapix.com/api/v1/health | jq .status
```

## Rollback

If deployment fails:

```bash
# Restore from VPS backup
ssh root@49.13.26.142 'cd /var/www && tar -xzf ~/mutuapix-api-backup-YYYYMMDD-HHMMSS.tar.gz'

# Restart
ssh root@49.13.26.142 'pm2 restart mutuapix-api'
```
