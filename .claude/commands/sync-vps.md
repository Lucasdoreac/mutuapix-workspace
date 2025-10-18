# Sync from Production VPS

Sync production code from VPS servers to local workspace for reference.

## Backend Sync

```bash
rsync -avz --exclude='node_modules' --exclude='vendor' --exclude='.git' \
  root@49.13.26.142:/var/www/mutuapix-api/ \
  /Users/lucascardoso/Desktop/MUTUA/backend/
```

## Frontend Sync

```bash
rsync -avz --exclude='node_modules' --exclude='.next' --exclude='.git' \
  root@138.199.162.115:/var/www/mutuapix-frontend-production/ \
  /Users/lucascardoso/Desktop/MUTUA/frontend/
```

## Important Notes

- Sync is **one-way**: VPS → Local
- Local workspace is for **reference and PR creation only**
- Never push directly from local to VPS
- Always use this command BEFORE starting work on a new feature
- Ensures you have latest production code

## After Sync

Check what changed:

```bash
# Backend
cd /Users/lucascardoso/Desktop/MUTUA/backend
git status

# Frontend
cd /Users/lucascardoso/Desktop/MUTUA/frontend
git status
```

If there are changes, you may need to create a PR to sync them to GitHub.
