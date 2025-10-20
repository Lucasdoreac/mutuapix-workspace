# MutuaPIX - Claude Code Guide

**Last Updated:** 2025-10-20  
**Stack:** Laravel 12 (backend) + Next.js 15 (frontend)

---

## ⚠️ CRITICAL: Deploy Process

**VPS is NOT a git repo!** Always copy manually after `git push`:

```bash
# 1. Push to GitHub
git push origin main

# 2. Copy to VPS (GitHub doesn't sync automatically!)
scp src/file.ts root@138.199.162.115:/var/www/mutuapix-frontend-production/src/

# 3. Rebuild
ssh root@138.199.162.115 'cd /var/www/mutuapix-frontend-production && rm -rf .next && npm run build && pm2 restart mutuapix-frontend'
```

**ALWAYS test in incognito first:** Cmd+Shift+N / Ctrl+Shift+N

---

## Servers

- Frontend: https://matrix.mutuapix.com (138.199.162.115)
- Backend: https://api.mutuapix.com (49.13.26.142)

---

## Quick Commands

```bash
# Health
curl -s https://api.mutuapix.com/api/v1/health | jq .

# Deploy Backend
scp app/file.php root@49.13.26.142:/var/www/mutuapix-api/app/
ssh root@49.13.26.142 'pm2 restart mutuapix-api'

# Deploy Frontend (see warning above!)
scp src/file.tsx root@138.199.162.115:/var/www/mutuapix-frontend-production/src/
ssh root@138.199.162.115 'cd /var/www/mutuapix-frontend-production && rm -rf .next && npm run build && pm2 restart mutuapix-frontend'

# MCP Test (ALWAYS incognito!)
pkill -f "remote-debugging-port=9222" && sleep 2 && \
open -na "Google Chrome" --args --remote-debugging-port=9222 \
  --incognito --new-window "https://matrix.mutuapix.com/login"
```

---

## Git Rules

- ❌ NEVER commit to main or force push  
- ✅ Create PR ≤300 lines, wait for CI

---

## Common Issues

- **"TypeError: v is not a function"** → Browser cache, use incognito
- **Login works, dashboard doesn't** → VPS not updated, use `scp`
- **Build OK, errors persist** → Clear `.next` before rebuild

---

## Key Files

- Backend: `routes/api.php`, `app/Http/Controllers/Api/V1/`
- Frontend: `src/stores/authStore.ts` (NO `environment` import!), `next.config.js` (cache: 1 hour)

---

## Skills

- **MCP Testing:** ALWAYS use incognito mode → @.claude/skills/mcp-testing-incognito/SKILL.md
- **Authentication:** Laravel Sanctum + Next.js → @.claude/skills/authentication-management/SKILL.md
- **PIX Validation:** Email matching rules → @.claude/skills/pix-validation/SKILL.md

## More Info

- [README.md](README.md) - Overview
- [LICOES_APRENDIDAS_ANTI_CIRCULO.md](LICOES_APRENDIDAS_ANTI_CIRCULO.md) - Avoid debugging loops
- [CLAUDE_CODE_MEMORIA_OFICIAL.md](CLAUDE_CODE_MEMORIA_OFICIAL.md) - How Claude Code memory works (official)
- [WORKFLOW_RULES_FOR_CLAUDE.md](WORKFLOW_RULES_FOR_CLAUDE.md) - Git workflow
- Archive: `docs/archive/` - Historical docs
