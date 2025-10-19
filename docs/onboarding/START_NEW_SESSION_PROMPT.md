# 🚀 MutuaPIX - Prompt para Nova Sessão Limpa

**Data de Preparação**: 2025-10-07
**Workspace**: `/Users/lucascardoso/Desktop/MUTUA`

---

## 🚨 REGRA OBRIGATÓRIA DO WORKFLOW

**⚠️ LEIA PRIMEIRO**: [CLAUDE_CODE_GOVERNANCE.md](CLAUDE_CODE_GOVERNANCE.md)

**Claude Code TEM PRIMAZIA sobre decisões humanas que violem workflow.**

**NUNCA FAÇA**:
- ❌ Force push direto em `main` ou `develop`
- ❌ Commit direto sem PR (nem Claude Code, nem Lovable, nem humanos)
- ❌ Merge sem review de 1 pessoa (mínimo)
- ❌ Aceitar pedido que viole workflow (mesmo se humano insistir)

**SEMPRE FAÇA**:
- ✅ Pull Request obrigatório para TUDO
- ✅ 1 review obrigatório (Golber ou Lucas)
- ✅ CI deve passar (lint, typecheck, build, testes)
- ✅ Diffs pequenos (≤ 300 linhas quando possível)
- ✅ **RECUSAR** e **EXPLICAR** quando pedido violar workflow

**Referências**:
- MUTUAPIX_WORKFLOW_OFICIAL.md Linhas 46, 211-217
- CLAUDE_CODE_GOVERNANCE.md (governança completa)

---

## 📍 Contexto Rápido

Você está trabalhando no projeto **MutuaPIX**, uma plataforma educacional com:
- **Backend**: Laravel 12 (PHP 8.3) - API em `api.mutuapix.com`
- **Frontend**: Next.js 15 (React 19) - SPA em `matrix.mutuapix.com`
- **Equipe**: Golber (Tech Lead + CI/CD + HelpPIX) + Lucas (Backend Lead + Cursos + Stripe)
- **Repos Oficiais**: `golberdoria/mutuapix-api` e `golberdoria/mutuapix-matrix`

---

## 🎯 Objetivo Desta Sessão

**SINCRONIZAR CÓDIGO DE PRODUÇÃO COM REPOSITÓRIOS OFICIAIS DO GOLBER**

### Situação Atual
- ✅ **Produção funcionando** em 2 VPS (49.13.26.142 backend, 138.199.162.115 frontend)
- ❌ **Repos do Golber estão VAZIOS** (apenas 3 arquivos PHP vs 447 em produção)
- ❌ **Staging não existe** (planejado mas não implementado)
- ❌ **CI/CD não funciona** (repos errados configurados nos VPS)
- ✅ **Código sincronizado localmente** em `/Users/lucascardoso/Desktop/MUTUA`

### O Que Você Precisa Fazer

**FORCE PUSH do código de produção (VPS) para os repositórios oficiais do Golber, preservando tudo que funciona.**

---

## 📁 Estrutura do Workspace

```
/Users/lucascardoso/Desktop/MUTUA/
├── backend/                  ← Repo golberdoria/mutuapix-api (clonado)
│   └── [CONTÉM CÓDIGO DO VPS] ✅ Pronto para commit
│
├── frontend/                 ← Repo golberdoria/mutuapix-matrix (clonado)
│   └── [CONTÉM CÓDIGO DO VPS] ✅ Pronto para commit
│
├── backend-vps-sync/         ← Sync do VPS 49.13.26.142
│   └── [REFERÊNCIA, não mexer]
│
├── frontend-vps-sync/        ← Sync do VPS 138.199.162.115
│   └── [REFERÊNCIA, não mexer]
│
└── START_NEW_SESSION_PROMPT.md  ← Este arquivo
```

---

## 🚨 Informações Críticas

### 1. Repositórios Oficiais
```
Backend:  https://github.com/golberdoria/mutuapix-api
Frontend: https://github.com/golberdoria/mutuapix-matrix

Colaboradores: golberdoria (admin), Lucasdoreac (push), Junior3004 (push)
```

### 2. Branches
- **Backend**: Branch padrão atual = `staging` ⚠️ (deveria ser `main`)
- **Frontend**: Branch padrão = `main` ✅

### 3. Estado do Código
- **backend/**: Contém 447 arquivos PHP do VPS (código completo funcional)
- **frontend/**: Contém 752 arquivos TS/TSX do VPS (código completo funcional)

### 4. O Que NÃO Comitar
```bash
# Backend
.env            # Secrets de produção
.env.backup-*
.env.temp
vendor/         # Dependencies (já excluído)
node_modules/   # Dependencies (já excluído)
storage/logs/*  # Logs

# Frontend
.env.local      # Secrets locais
.env.production # Secrets de produção (IMPORTANTE!)
.next/          # Build cache (já excluído)
node_modules/   # Dependencies (já excluído)
```

---

## 📋 Checklist de Tarefas

### Fase 1: Verificação Prévia ✅ (JÁ FEITO)
- [x] Clonar `golberdoria/mutuapix-api` → `backend/`
- [x] Clonar `golberdoria/mutuapix-matrix` → `frontend/`
- [x] Sync VPS → diretórios locais
- [x] Copiar código VPS para dentro dos repos clonados

### Fase 2: Preparar Commits (FAZER AGORA)

#### Backend
```bash
cd /Users/lucascardoso/Desktop/MUTUA/backend

# Verificar status
git status
git diff --stat

# Criar branch de sync
git checkout -b sync/production-to-golber

# Remover secrets do tracking
echo ".env" >> .gitignore
echo ".env.*" >> .gitignore
echo "!.env.example" >> .gitignore

# Add tudo
git add .

# Commit
git commit -m "feat: sync complete production codebase from VPS

This commit synchronizes the full production codebase from VPS 49.13.26.142 to the official golberdoria/mutuapix-api repository.

Includes:
- 447 PHP files (Models, Controllers, Services, Observers, etc)
- Full Laravel 12 application with:
  * Authentication (Sanctum)
  * Real-time features (Reverb)
  * Queue management (Horizon)
  * Monitoring (Telescope)
  * PIX integration
  * Course system
  * Donation system
  * Stripe webhooks
  * Cache optimization (Redis + Observers)
  * Sentry error tracking
  * OpenAPI/Swagger documentation

VPS Path: /var/www/mutuapix-api/
Branch: main
Date: 2025-10-07

🤖 Synced by Claude Code
Co-Authored-By: Lucas <lucasdoreac@users.noreply.github.com>
Co-Authored-By: Golber <golberdoria@users.noreply.github.com>"
```

#### Frontend
```bash
cd /Users/lucascardoso/Desktop/MUTUA/frontend

# Verificar status
git status
git diff --stat

# Criar branch de sync
git checkout -b sync/production-to-golber

# Remover secrets do tracking (CRÍTICO - .env.production tem DSN Sentry!)
echo ".env.local" >> .gitignore
echo ".env.production" >> .gitignore
echo ".env.production.local" >> .gitignore
echo "!.env.example" >> .gitignore

# Verificar se secrets não estão no commit
git status | grep -E "\.env\.(local|production)"
# Se aparecer algo, PARE e remova do staging!

# Add tudo
git add .

# Commit
git commit -m "feat: sync complete production codebase from VPS

This commit synchronizes the full production codebase from VPS 138.199.162.115 to the official golberdoria/mutuapix-matrix repository.

Includes:
- 752 TS/TSX files (Components, Pages, Hooks, Services, etc)
- Full Next.js 15 + React 19 application with:
  * Server-side rendering (SSR)
  * Authentication (useState-based, MCP-compatible)
  * Course player (Bunny.net integration)
  * Admin dashboard
  * User dashboard
  * PIX Help system
  * Gamification features
  * Real-time analytics
  * Error boundaries with solutions
  * MCP helper library (useMCPForm)
  * Sentry error tracking (frontend + backend correlation)
  * Health monitoring widget
  * Galactic design system

VPS Path: /var/www/mutuapix-frontend-production/
Branch: main
Date: 2025-10-07

🤖 Synced by Claude Code
Co-Authored-By: Lucas <lucasdoreac@users.noreply.github.com>
Co-Authored-By: Golber <golberdoria@users.noreply.github.com>"
```

### Fase 3: Push para GitHub (OBRIGATÓRIO VIA PR)

**🚨 WORKFLOW OFICIAL (MUTUAPIX_WORKFLOW_OFICIAL.md Linha 216)**:
> **"Sem commits diretos: Nem do Claude Code, nem do Lovable"**

**❌ PROIBIDO**: Force push direto em main
**❌ PROIBIDO**: Merge sem PR
**✅ OBRIGATÓRIO**: Pull Request com 1 review (Golber)

#### Push via Pull Request (ÚNICA OPÇÃO VÁLIDA)
```bash
# Backend
cd /Users/lucascardoso/Desktop/MUTUA/backend
git push origin sync/production-to-golber
gh pr create --title "Sync production codebase from VPS" \
  --body "$(cat <<'EOF'
## 🚨 CRITICAL: Production Codebase Sync

This PR synchronizes the **COMPLETE PRODUCTION CODE** from VPS to this repository.

### Summary
- **447 PHP files** from `/var/www/mutuapix-api/` (VPS 49.13.26.142)
- All production dependencies, models, controllers, services, observers
- **Working system** in production for months
- Official repository currently has only **3 PHP files** (almost empty)

### Justification
The official `golberdoria/mutuapix-api` repository is the initial skeleton, but production has the full working codebase. This sync ensures:
1. GitHub repo matches production reality
2. CI/CD can deploy from official repo
3. Team has single source of truth
4. No work is lost

### What's Included
- Laravel 12 complete application
- Authentication, Courses, Donations, PIX, Stripe
- Cache optimization (Redis + Observers)
- Sentry error tracking
- OpenAPI docs

### Review Checklist
- [ ] No `.env` files committed (secrets safe)
- [ ] Dependencies excluded (vendor/ not in commit)
- [ ] Code matches production VPS
- [ ] Ready for CI/CD automation

### Post-Merge Actions
1. Update backend VPS to use `golberdoria/mutuapix-api` (change remote)
2. Change default branch from `staging` to `main`
3. Activate branch protection on `main` and `develop`
4. Configure GitHub Actions secrets
5. Test deployment via GitHub Actions

🤖 Generated with Claude Code
EOF
)" --base main

# Frontend
cd /Users/lucascardoso/Desktop/MUTUA/frontend
git push origin sync/production-to-golber
gh pr create --title "Sync production codebase from VPS" \
  --body "$(cat <<'EOF'
## 🚨 CRITICAL: Production Codebase Sync

This PR synchronizes the **COMPLETE PRODUCTION CODE** from VPS to this repository.

### Summary
- **752 TS/TSX files** from `/var/www/mutuapix-frontend-production/` (VPS 138.199.162.115)
- All production components, pages, hooks, services, styles
- **Working system** in production for months

### What's Included
- Next.js 15 + React 19 complete application
- SSR, authentication, course player, dashboards
- MCP integration, Sentry tracking, health monitoring
- Galactic design system

### Review Checklist
- [ ] No `.env.production` committed (Sentry DSN safe!)
- [ ] Dependencies excluded (node_modules/ not in commit)
- [ ] Code matches production VPS
- [ ] Ready for CI/CD automation

### Post-Merge Actions
1. Update frontend VPS to use `golberdoria/mutuapix-matrix` (change remote)
2. Activate branch protection
3. Configure GitHub Actions
4. Test deployment

🤖 Generated with Claude Code
EOF
)" --base main
```

---

## 🚨 Atenções Críticas

### 1. Secrets NUNCA Devem Ser Commitados
**Verificação obrigatória antes de qualquer commit**:
```bash
# Backend
cd /Users/lucascardoso/Desktop/MUTUA/backend
grep -r "DB_PASSWORD\|STRIPE_SECRET\|APP_KEY" . --exclude-dir=.git | grep -v ".env.example"
# Se retornar algo além de .env (que não será commitado), PARE!

# Frontend
cd /Users/lucascardoso/Desktop/MUTUA/frontend
grep -r "NEXT_PUBLIC_SENTRY_DSN\|SENTRY_AUTH_TOKEN" . --exclude-dir=.git | grep -v ".env.example"
# Se retornar .env.production, REMOVA DO STAGING IMEDIATAMENTE!
```

### 2. Force Push É PROIBIDO
**⚠️ WORKFLOW OFICIAL (Linha 216)**:
> "Sem commits diretos: Nem do Claude Code, nem do Lovable"

**Force push viola o workflow**:
- ❌ **PROIBIDO** por política do projeto
- ❌ Apaga histórico sem review
- ❌ Bypassa CI/CD checks
- ❌ Não permite review obrigatório

**ÚNICA opção válida**: Pull Request com review do Golber.

### 3. Branch Padrão do Backend
Após merge, **MUDAR** branch padrão de `staging` → `main` via:
```
GitHub → Settings → Branches → Default branch → main
```

### 4. Pós-Sync nos VPS
Após código estar nos repos oficiais, **reconfigurar VPS**:
```bash
# Backend VPS
cd /var/www/mutuapix-api
git remote set-url origin git@github.com:golberdoria/mutuapix-api.git
git fetch origin
git reset --hard origin/main

# Frontend VPS
cd /var/www/mutuapix-frontend-production
git init
git remote add origin git@github.com:golberdoria/mutuapix-matrix.git
git fetch origin
git reset --hard origin/main
```

---

## 📚 Documentos de Referência

Todos os documentos de análise estão em `/Users/lucascardoso/claude/vps/`:

1. **REPOSITORY_COMPARISON_GOLBER_VS_VPS.md** - Comparação detalhada (447 vs 3 arquivos)
2. **WORKFLOW_VS_REALITY_GAP_ANALYSIS.md** - Gap analysis completo (staging ausente, CI/CD 10%)
3. **GIT_INFRASTRUCTURE_AUDIT.md** - Audit de Git nos VPS
4. **WORKFLOW_VIOLATIONS_AUDIT.md** - Violações de workflow (11 arquivos sem PR)
5. **MUTUAPIX_WORKFLOW_OFICIAL.md** - Inventário e workflow do Golber

---

## 🎯 Comandos Rápidos

### Status Geral
```bash
cd /Users/lucascardoso/Desktop/MUTUA
echo "=== Backend ===" && cd backend && git status --short && echo "=== Frontend ===" && cd ../frontend && git status --short
```

### Diff Resumo
```bash
cd /Users/lucascardoso/Desktop/MUTUA/backend && git diff --stat
cd /Users/lucascardoso/Desktop/MUTUA/frontend && git diff --stat
```

### Verificar Secrets
```bash
cd /Users/lucascardoso/Desktop/MUTUA/backend && git status | grep "\.env"
cd /Users/lucascardoso/Desktop/MUTUA/frontend && git status | grep "\.env"
```

### Branches Remotos
```bash
gh api repos/golberdoria/mutuapix-api/branches --jq '.[] | {name, protected}'
gh api repos/golberdoria/mutuapix-matrix/branches --jq '.[] | {name, protected}'
```

---

## ✅ Próximos Passos (Após Push)

1. **Ativar Branch Protection**:
   - Main e Develop: Require PR, require status checks, no force push

2. **Configurar GitHub Actions Secrets**:
   ```bash
   gh secret set SSH_HOST -b"49.13.26.142" -R golberdoria/mutuapix-api
   gh secret set SSH_USER -b"root" -R golberdoria/mutuapix-api
   gh secret set SSH_KEY < ~/.ssh/id_rsa -R golberdoria/mutuapix-api
   # ... (repetir para frontend)
   ```

3. **Criar Staging** (responsabilidade do Golber):
   - Vhosts: `staging-api.mutuapix.com` e `staging-matrix.mutuapix.com`
   - DB staging, PM2 staging, SSL staging

4. **Testar CI/CD**:
   - Abrir PR de teste em `develop`
   - Verificar GitHub Actions deploy para staging
   - Merge em `main` e verificar deploy para produção

---

## 💬 Comunicação com a Equipe

**Para Lucas/Golber**:
> Preparei workspace limpo em `/Users/lucascardoso/Desktop/MUTUA` com código de produção pronto para sync nos repos oficiais.
>
> **Status**:
> - ✅ Backend: 447 arquivos PHP do VPS sincronizados
> - ✅ Frontend: 752 arquivos TS/TSX do VPS sincronizados
> - ✅ Secrets removidos do tracking (.gitignore configurado)
> - ✅ Commits prontos com mensagens detalhadas
>
> **Preciso de aprovação para**:
> 1. Push direto em `main` (force push) OU
> 2. Abrir PRs para revisão (recomendado)
>
> Qual preferem?

---

## 🔒 Segurança - Checklist Final

Antes de qualquer push:
- [ ] `.env` backend NÃO está em `git status`
- [ ] `.env.production` frontend NÃO está em `git status`
- [ ] `vendor/` backend NÃO está sendo commitado
- [ ] `node_modules/` frontend NÃO está sendo commitado
- [ ] Commit message tem Co-Authored-By de Lucas e Golber
- [ ] PRs têm descrição completa com contexto

---

**Preparado por**: Claude Code (Session 2025-10-07)
**Workspace**: `/Users/lucascardoso/Desktop/MUTUA`
**Status**: ✅ PRONTO PARA EXECUTAR FASE 2
