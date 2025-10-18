# Health Check Command

Run comprehensive health checks on both backend and frontend production servers.

## Backend Health

Check backend API health:

```bash
curl -s https://api.mutuapix.com/api/v1/health | jq .
```

Check backend PM2 status:

```bash
ssh root@49.13.26.142 'pm2 status'
```

## Frontend Health

Check frontend HTTP status:

```bash
curl -I https://matrix.mutuapix.com/login 2>&1 | grep HTTP
```

Check frontend PM2 status:

```bash
ssh root@138.199.162.115 'pm2 status'
```

## Expected Results

**Backend Health API:**
```json
{
  "status": "ok",
  "checks": {
    "app": {"status": "ok"},
    "database": {"status": "ok"},
    "cache": {"status": "ok"},
    "sanctum": {"status": "ok"}
  }
}
```

**PM2 Status:**
Both services should show `online` status.

**Frontend HTTP:**
Should return `HTTP/2 200`
