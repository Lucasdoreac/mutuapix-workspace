# Plano de Auto-Melhoria - Automação e Prevenção

**Data:** 2025-10-07
**Projeto:** MutuaPIX (MUTUA)
**Objetivo:** Prevenir código legado e automatizar melhoria contínua
**Baseado em:** Claude Code 2025 + Laravel 12 + Next.js 15 + Stripe Best Practices

---

## 📋 Sumário Executivo

Este documento define estratégias de **automação** e **prevenção** para garantir:

- ✅ **Código limpo** - Sem arquivos órfãos ou legado
- ✅ **Qualidade garantida** - Testes e validações automáticas
- ✅ **Segurança** - Prevenção de commits perigosos
- ✅ **Documentação viva** - Sempre atualizada
- ✅ **Manutenção zero** - Sistema auto-suficiente

**Meta:** Nunca mais encontrar código legado ou vestígios de tentativas antigas.

---

## 🎯 Princípios de Auto-Melhoria

### 1. **Prevenir > Corrigir**
Bloqueie problemas ANTES de entrarem no código.

### 2. **Automatizar > Lembrar**
Se pode ser automatizado, não dependa de memória humana.

### 3. **Documentar > Explicar**
Código auto-explicativo + docs automáticas > explicações manuais.

### 4. **Validar > Confiar**
Sempre valide: testes, linters, hooks, CI/CD.

### 5. **Evoluir > Estagnar**
Melhoria contínua incremental, não grandes refactorings.

---

## 🛡️ Camada 1 - Prevenção via Git Hooks

### Hook 1: `pre-commit` - Validação ANTES de Commit

**Localização:** `.git/hooks/pre-commit`

```bash
#!/bin/bash

echo "🔍 Pre-commit validations..."

# ====================
# 1. ARQUIVOS SENSÍVEIS
# ====================
echo "Checking for sensitive files..."

SENSITIVE_FILES=".env .env.local .env.production credentials.json private.key"
for file in $SENSITIVE_FILES; do
  if git diff --cached --name-only | grep -q "$file"; then
    echo "❌ BLOCKED: $file cannot be committed"
    echo ""
    echo "Sensitive files detected:"
    git diff --cached --name-only | grep "$file"
    echo ""
    echo "To fix: Remove from staging with 'git reset $file'"
    exit 1
  fi
done

# ====================
# 2. ARQUIVOS ÓRFÃOS PHP
# ====================
echo "Checking for orphaned PHP files in backend root..."

if git diff --cached --name-only | grep -E '^backend/[^/]+\.php$'; then
  ORPHANED=$(git diff --cached --name-only | grep -E '^backend/[^/]+\.php$' | grep -v 'artisan')
  if [ ! -z "$ORPHANED" ]; then
    echo "❌ BLOCKED: Orphaned PHP files in backend root"
    echo ""
    echo "Files:"
    echo "$ORPHANED"
    echo ""
    echo "PHP files should be in app/, routes/, config/, etc."
    echo "Not in root directory."
    exit 1
  fi
fi

# ====================
# 3. CONSOLE.LOG EM PRODUÇÃO
# ====================
echo "Checking for console.log in production code..."

if git diff --cached --name-only | grep -E '^frontend/src/.*\.(ts|tsx)$'; then
  # Permitir em arquivos de desenvolvimento/debug
  PROD_FILES=$(git diff --cached --name-only | grep -E '^frontend/src/' | grep -v -E '(debug|test|example|mock)')

  if [ ! -z "$PROD_FILES" ]; then
    if git diff --cached | grep -E '^\+.*console\.(log|debug)' | grep -v '// DEBUG:'; then
      echo "⚠️  WARNING: console.log found in production code"
      echo ""
      git diff --cached | grep -E '^\+.*console\.(log|debug)' | head -5
      echo ""
      echo "Consider using logger instead:"
      echo "  import { logger } from '@/lib/logger';"
      echo "  logger.debug('message');"
      echo ""
      read -p "Continue anyway? (y/N) " -n 1 -r
      echo
      if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
      fi
    fi
  fi
fi

# ====================
# 4. IMPORTS NÃO UTILIZADOS
# ====================
echo "Checking for unused imports (TypeScript)..."

if git diff --cached --name-only | grep -E '\.(ts|tsx)$'; then
  # Usar eslint para detectar imports não utilizados
  if command -v npx &> /dev/null; then
    cd frontend 2>/dev/null && npx eslint --quiet --rule 'no-unused-vars: error' $(git diff --cached --name-only --relative | grep -E '\.(ts|tsx)$') 2>/dev/null || true
    cd - > /dev/null
  fi
fi

# ====================
# 5. TESTES QUEBRADOS
# ====================
echo "Running tests for modified code..."

# Backend - rodar testes afetados
if git diff --cached --name-only | grep -E '^backend/(app|tests)/'; then
  echo "Running backend tests..."
  cd backend

  # Rodar apenas testes dos arquivos modificados
  MODIFIED_PHP=$(git diff --cached --name-only --relative | grep -E '^(app|tests)/.*\.php$')

  if [ ! -z "$MODIFIED_PHP" ]; then
    php artisan test --parallel --stop-on-failure || {
      echo ""
      echo "❌ BLOCKED: Backend tests failed"
      echo ""
      echo "Fix the tests before committing:"
      echo "  cd backend && php artisan test"
      exit 1
    }
  fi

  cd ..
fi

# Frontend - rodar testes afetados
if git diff --cached --name-only | grep -E '^frontend/src/'; then
  echo "Running frontend tests..."
  cd frontend

  # Rodar apenas testes dos arquivos modificados
  MODIFIED_TS=$(git diff --cached --name-only --relative | grep -E '^src/.*\.(ts|tsx)$')

  if [ ! -z "$MODIFIED_TS" ]; then
    npm run test:changed --silent || {
      echo ""
      echo "❌ BLOCKED: Frontend tests failed"
      echo ""
      echo "Fix the tests before committing:"
      echo "  cd frontend && npm run test"
      exit 1
    }
  fi

  cd ..
fi

# ====================
# 6. FORMATAÇÃO
# ====================
echo "Checking code formatting..."

# Backend - Laravel Pint
if git diff --cached --name-only | grep -E '^backend/.*\.php$'; then
  cd backend

  MODIFIED_PHP=$(git diff --cached --name-only --relative | grep -E '\.php$')

  if [ ! -z "$MODIFIED_PHP" ]; then
    echo "Formatting PHP files with Pint..."
    vendor/bin/pint $MODIFIED_PHP || {
      echo "❌ BLOCKED: PHP formatting failed"
      exit 1
    }

    # Re-add arquivos formatados
    git add $MODIFIED_PHP
  fi

  cd ..
fi

# Frontend - Prettier
if git diff --cached --name-only | grep -E '^frontend/src/.*\.(ts|tsx|js|jsx)$'; then
  cd frontend

  MODIFIED_TS=$(git diff --cached --name-only --relative | grep -E '^src/.*\.(ts|tsx|js|jsx)$')

  if [ ! -z "$MODIFIED_TS" ]; then
    echo "Formatting TypeScript files with Prettier..."
    npx prettier --write $MODIFIED_TS || {
      echo "❌ BLOCKED: TypeScript formatting failed"
      exit 1
    }

    # Re-add arquivos formatados
    git add $MODIFIED_TS
  fi

  cd ..
fi

# ====================
# 7. COMMIT MESSAGE VALIDATION
# ====================
# Validar mensagem será feito em commit-msg hook

echo ""
echo "✅ Pre-commit checks passed"
exit 0
```

**Instalação:**
```bash
chmod +x .git/hooks/pre-commit
```

---

### Hook 2: `commit-msg` - Validar Mensagem de Commit

**Localização:** `.git/hooks/commit-msg`

```bash
#!/bin/bash

COMMIT_MSG_FILE=$1
COMMIT_MSG=$(cat "$COMMIT_MSG_FILE")

echo "🔍 Validating commit message..."

# Conventional Commits format: type(scope): description
# Exemplos:
#   feat(auth): add login with Google
#   fix(pix): resolve QR code generation
#   docs(readme): update installation steps

PATTERN="^(feat|fix|docs|style|refactor|test|chore|perf)(\([a-z-]+\))?: .{10,}"

if ! echo "$COMMIT_MSG" | grep -qE "$PATTERN"; then
  echo ""
  echo "❌ BLOCKED: Invalid commit message format"
  echo ""
  echo "Current message:"
  echo "  $COMMIT_MSG"
  echo ""
  echo "Expected format:"
  echo "  <type>(<scope>): <description>"
  echo ""
  echo "Types:"
  echo "  feat     - New feature"
  echo "  fix      - Bug fix"
  echo "  docs     - Documentation"
  echo "  style    - Code style (formatting)"
  echo "  refactor - Code refactoring"
  echo "  test     - Tests"
  echo "  chore    - Maintenance"
  echo "  perf     - Performance"
  echo ""
  echo "Examples:"
  echo "  feat(auth): add Google login"
  echo "  fix(pix): resolve QR generation bug"
  echo "  docs(api): update authentication docs"
  echo ""
  exit 1
fi

# Verificar se tem issue/ticket reference (opcional mas recomendado)
if ! echo "$COMMIT_MSG" | grep -qE "#[0-9]+"; then
  echo ""
  echo "⚠️  WARNING: No issue reference found"
  echo ""
  echo "Consider adding issue number: #123"
  echo ""
fi

echo "✅ Commit message valid"
exit 0
```

**Instalação:**
```bash
chmod +x .git/hooks/commit-msg
```

---

### Hook 3: `post-checkout` - Atualizar Dependências

**Localização:** `.git/hooks/post-checkout`

```bash
#!/bin/bash

PREV_COMMIT=$1
NEW_COMMIT=$2
BRANCH_CHECKOUT=$3

echo "🔄 Post-checkout: Checking for dependency changes..."

# Verificar se mudou composer.json ou composer.lock
if git diff --name-only $PREV_COMMIT $NEW_COMMIT | grep -qE '^backend/composer\.(json|lock)$'; then
  echo "📦 Backend dependencies changed"
  echo "Running: composer install"
  cd backend && composer install --no-interaction
  cd ..
fi

# Verificar se mudou package.json ou package-lock.json
if git diff --name-only $PREV_COMMIT $NEW_COMMIT | grep -qE '^frontend/package(-lock)?\.json$'; then
  echo "📦 Frontend dependencies changed"
  echo "Running: npm install"
  cd frontend && npm install
  cd ..
fi

# Verificar se mudou migrations
if git diff --name-only $PREV_COMMIT $NEW_COMMIT | grep -qE '^backend/database/migrations/'; then
  echo "🗄️  Database migrations changed"
  echo "Consider running: cd backend && php artisan migrate"
fi

echo "✅ Post-checkout complete"
exit 0
```

**Instalação:**
```bash
chmod +x .git/hooks/post-checkout
```

---

### Hook 4: `pre-push` - Validação Final

**Localização:** `.git/hooks/pre-push`

```bash
#!/bin/bash

echo "🚀 Pre-push validations..."

# Impedir push direto para main/master
BRANCH=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')

if [ "$BRANCH" = "main" ] || [ "$BRANCH" = "master" ]; then
  echo ""
  echo "❌ BLOCKED: Direct push to $BRANCH is not allowed"
  echo ""
  echo "Use pull requests instead:"
  echo "  1. Create feature branch: git checkout -b feature/my-feature"
  echo "  2. Push feature: git push -u origin feature/my-feature"
  echo "  3. Create PR on GitHub"
  echo ""
  exit 1
fi

# Rodar todos os testes antes de push
echo "Running full test suite..."

# Backend
cd backend
echo "Testing backend..."
php artisan test --parallel || {
  echo ""
  echo "❌ BLOCKED: Backend tests failed"
  exit 1
}
cd ..

# Frontend
cd frontend
echo "Testing frontend..."
npm run test -- --run || {
  echo ""
  echo "❌ BLOCKED: Frontend tests failed"
  exit 1
}
cd ..

echo ""
echo "✅ Pre-push checks passed"
exit 0
```

**Instalação:**
```bash
chmod +x .git/hooks/pre-push
```

---

## 🤖 Camada 2 - Claude Code Hooks

### Hook 1: `SessionStart` - Setup Automático

**Localização:** `.claude/hooks/session-start.sh`

```bash
#!/bin/bash

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🚀 MUTUA Session Starting..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ====================
# 1. SYSTEM HEALTH CHECK
# ====================
echo "📊 System Health Check:"
echo ""

# API Health
API_STATUS=$(curl -s https://api.mutuapix.com/api/v1/health | jq -r '.status' 2>/dev/null)
if [ "$API_STATUS" = "ok" ]; then
  echo "  ✅ API: Healthy"
else
  echo "  ❌ API: Degraded or offline"
fi

# Frontend Status
FRONTEND_STATUS=$(ssh root@138.199.162.115 'pm2 status | grep mutuapix-frontend | grep online' 2>/dev/null)
if [ ! -z "$FRONTEND_STATUS" ]; then
  echo "  ✅ Frontend: Online"
else
  echo "  ❌ Frontend: Offline"
fi

# Backend Status
BACKEND_STATUS=$(ssh root@49.13.26.142 'pm2 status | grep mutuapix-api | grep online' 2>/dev/null)
if [ ! -z "$BACKEND_STATUS" ]; then
  echo "  ✅ Backend: Online"
else
  echo "  ❌ Backend: Offline"
fi

# ====================
# 2. GIT STATUS
# ====================
echo ""
echo "📝 Git Status:"
echo ""

cd /Users/lucascardoso/Desktop/MUTUA

# Backend
cd backend
BACKEND_GIT=$(git status -s)
if [ -z "$BACKEND_GIT" ]; then
  echo "  ✅ Backend: Clean"
else
  echo "  ⚠️  Backend: Uncommitted changes"
  git status -s | head -5
fi
cd ..

# Frontend
cd frontend
FRONTEND_GIT=$(git status -s)
if [ -z "$FRONTEND_GIT" ]; then
  echo "  ✅ Frontend: Clean"
else
  echo "  ⚠️  Frontend: Uncommitted changes"
  git status -s | head -5
fi
cd ..

# ====================
# 3. DEPENDENCY CHECK
# ====================
echo ""
echo "📦 Dependencies Check:"
echo ""

# Check if composer.lock ou package.json foram atualizados
LAST_PULL=$(git log -1 --format="%H")

if git diff $LAST_PULL HEAD --name-only | grep -q 'backend/composer.lock'; then
  echo "  ⚠️  Backend dependencies updated - run 'composer install'"
fi

if git diff $LAST_PULL HEAD --name-only | grep -q 'frontend/package-lock.json'; then
  echo "  ⚠️  Frontend dependencies updated - run 'npm install'"
fi

# ====================
# 4. PENDING TASKS
# ====================
echo ""
echo "📋 Pending Tasks (TODOs):"
echo ""

# Backend TODOs críticos
BACKEND_TODOS=$(grep -r "TODO\|FIXME" backend/app/ 2>/dev/null | wc -l | xargs)
echo "  Backend: $BACKEND_TODOS TODOs/FIXMEs"

# Frontend TODOs críticos
FRONTEND_TODOS=$(grep -r "TODO\|FIXME" frontend/src/ 2>/dev/null | wc -l | xargs)
echo "  Frontend: $FRONTEND_TODOS TODOs/FIXMEs"

# ====================
# 5. AVAILABLE COMMANDS
# ====================
echo ""
echo "🎯 Quick Commands:"
echo ""
echo "  /status          - Detailed system status"
echo "  /deploy:frontend - Deploy frontend to production"
echo "  /deploy:backend  - Deploy backend to production"
echo "  /debug:logs      - View recent errors"
echo "  /debug:health    - Full health check"
echo ""

# ====================
# 6. REMINDERS
# ====================
echo "💡 Reminders:"
echo ""

# Verificar se há commits não pushados
UNPUSHED_BACKEND=$(cd backend && git log @{u}.. --oneline 2>/dev/null | wc -l | xargs)
UNPUSHED_FRONTEND=$(cd frontend && git log @{u}.. --oneline 2>/dev/null | wc -l | xargs)

if [ "$UNPUSHED_BACKEND" -gt 0 ]; then
  echo "  ⚠️  Backend has $UNPUSHED_BACKEND unpushed commits"
fi

if [ "$UNPUSHED_FRONTEND" -gt 0 ]; then
  echo "  ⚠️  Frontend has $UNPUSHED_FRONTEND unpushed commits"
fi

# Verificar se há PRs abertos (requer gh CLI)
if command -v gh &> /dev/null; then
  OPEN_PRS=$(gh pr list --state open 2>/dev/null | wc -l | xargs)
  if [ "$OPEN_PRS" -gt 0 ]; then
    echo "  📬 $OPEN_PRS open pull requests"
  fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ Session ready"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
```

**Configuração no Claude Code:**
```bash
# Registrar hook
/hooks
# Select: SessionStart
# Script path: .claude/hooks/session-start.sh
```

---

### Hook 2: `PreToolUse` - Validação Antes de Editar

**Configuração:**
```bash
/hooks
# Select: PreToolUse
# Select tool: Edit
```

**Script:**
```bash
#!/bin/bash

# $TOOL_NAME - Nome da ferramenta (Edit)
# $FILE_PATH - Caminho do arquivo sendo editado

# ====================
# 1. PROTEGER ARQUIVOS SENSÍVEIS
# ====================
if [[ "$FILE_PATH" =~ \.env ]]; then
  echo ""
  echo "❌ BLOCKED: Cannot edit .env files directly"
  echo ""
  echo "File: $FILE_PATH"
  echo ""
  echo "To update environment variables:"
  echo "  1. Use /config:update command"
  echo "  2. Or edit manually and restart services"
  echo ""
  exit 1
fi

# ====================
# 2. PROTEGER CONFIGURAÇÕES CRÍTICAS
# ====================
CRITICAL_CONFIGS=(
  "backend/config/app.php"
  "backend/config/database.php"
  "backend/bootstrap/app.php"
  "frontend/next.config.js"
)

for config in "${CRITICAL_CONFIGS[@]}"; do
  if [[ "$FILE_PATH" = "$config" ]]; then
    echo ""
    echo "⚠️  WARNING: Editing critical config file"
    echo ""
    echo "File: $FILE_PATH"
    echo ""
    echo "This file affects core application behavior."
    echo "Make sure you know what you're doing."
    echo ""
    # Não bloquear, apenas avisar
  fi
done

# ====================
# 3. AVISAR SOBRE ARQUIVOS DE PRODUÇÃO
# ====================
if [[ "$FILE_PATH" =~ production ]] || [[ "$FILE_PATH" =~ prod ]]; then
  echo ""
  echo "⚠️  WARNING: This appears to be a production file"
  echo ""
  echo "File: $FILE_PATH"
  echo ""
  echo "Changes will affect production environment."
  echo ""
fi

# ====================
# 4. VERIFICAR SE ARQUIVO EXISTE NO GIT
# ====================
if ! git ls-files --error-unmatch "$FILE_PATH" 2>/dev/null; then
  echo ""
  echo "ℹ️  INFO: Creating new file (not in git yet)"
  echo ""
  echo "File: $FILE_PATH"
  echo ""
  echo "Remember to add it to git after editing:"
  echo "  git add $FILE_PATH"
  echo ""
fi

exit 0
```

---

### Hook 3: `PostToolUse` - Auto-Formatação

**Configuração:**
```bash
/hooks
# Select: PostToolUse
# Select tool: Edit
```

**Script:**
```bash
#!/bin/bash

# $TOOL_NAME - Nome da ferramenta (Edit)
# $FILE_PATH - Caminho do arquivo editado
# $SUCCESS - true se ferramenta executou com sucesso

if [ "$SUCCESS" != "true" ]; then
  exit 0
fi

# ====================
# 1. AUTO-FORMATAR PHP
# ====================
if [[ "$FILE_PATH" =~ \.php$ ]] && [[ "$FILE_PATH" =~ ^backend/ ]]; then
  echo ""
  echo "🎨 Formatting PHP file with Pint..."

  cd backend
  vendor/bin/pint "$FILE_PATH" --quiet 2>/dev/null || true
  cd ..

  echo "  ✅ Formatted: $FILE_PATH"
fi

# ====================
# 2. AUTO-FORMATAR TYPESCRIPT/JAVASCRIPT
# ====================
if [[ "$FILE_PATH" =~ \.(ts|tsx|js|jsx)$ ]] && [[ "$FILE_PATH" =~ ^frontend/ ]]; then
  echo ""
  echo "🎨 Formatting TypeScript file with Prettier..."

  cd frontend
  npx prettier --write "$FILE_PATH" --log-level silent 2>/dev/null || true
  cd ..

  echo "  ✅ Formatted: $FILE_PATH"
fi

# ====================
# 3. RODAR TESTES RELACIONADOS (opcional)
# ====================
# Descomente se quiser rodar testes após cada edit

# if [[ "$FILE_PATH" =~ ^backend/app/.*\.php$ ]]; then
#   echo ""
#   echo "🧪 Running related tests..."
#
#   cd backend
#   php artisan test --filter=$(basename "$FILE_PATH" .php) --quiet || true
#   cd ..
# fi

# ====================
# 4. ATUALIZAR DOCS AUTOMÁTICAS (se aplicável)
# ====================
if [[ "$FILE_PATH" =~ ^backend/app/Http/Controllers/.*\.php$ ]]; then
  echo ""
  echo "📚 Updating API documentation..."

  cd backend
  php artisan l5-swagger:generate --quiet 2>/dev/null || true
  cd ..

  echo "  ✅ API docs updated"
fi

exit 0
```

---

## 🔄 Camada 3 - CI/CD Automação

### GitHub Actions - Validação Contínua

**Localização:** `.github/workflows/ci.yml`

```yaml
name: CI Pipeline

on:
  push:
    branches: [ main, develop, 'feature/**' ]
  pull_request:
    branches: [ main, develop ]

jobs:
  # ====================
  # BACKEND TESTS
  # ====================
  backend-tests:
    name: Backend Tests (Laravel)
    runs-on: ubuntu-latest

    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: root
          MYSQL_DATABASE: testing
        ports:
          - 3306:3306
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3

    steps:
      - uses: actions/checkout@v3

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          extensions: mbstring, pdo_mysql

      - name: Install Dependencies
        working-directory: ./backend
        run: composer install --prefer-dist --no-progress

      - name: Copy .env
        working-directory: ./backend
        run: cp .env.example .env

      - name: Generate Key
        working-directory: ./backend
        run: php artisan key:generate

      - name: Run Migrations
        working-directory: ./backend
        run: php artisan migrate --force

      - name: Run Tests
        working-directory: ./backend
        run: php artisan test --parallel --coverage --min=80

      - name: Laravel Pint (Code Style)
        working-directory: ./backend
        run: vendor/bin/pint --test

  # ====================
  # FRONTEND TESTS
  # ====================
  frontend-tests:
    name: Frontend Tests (Next.js)
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '20'
          cache: 'npm'
          cache-dependency-path: frontend/package-lock.json

      - name: Install Dependencies
        working-directory: ./frontend
        run: npm ci

      - name: Run Tests
        working-directory: ./frontend
        run: npm run test -- --coverage --run

      - name: Build
        working-directory: ./frontend
        run: npm run build

      - name: ESLint
        working-directory: ./frontend
        run: npm run lint

  # ====================
  # SECURITY SCAN
  # ====================
  security-scan:
    name: Security Scan
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'

  # ====================
  # CODE QUALITY
  # ====================
  code-quality:
    name: Code Quality Analysis
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0  # Full history for better analysis

      - name: SonarCloud Scan
        uses: SonarSource/sonarcloud-github-action@master
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

---

### GitHub Actions - Deploy Automático

**Localização:** `.github/workflows/deploy-production.yml`

```yaml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*.*.*'  # Trigger on version tags (v1.0.0, v1.0.1, etc)

jobs:
  deploy-backend:
    name: Deploy Backend
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Deploy to VPS
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.BACKEND_HOST }}
          username: root
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /var/www/mutuapix-api
            git pull origin main
            composer install --no-dev --optimize-autoloader
            php artisan migrate --force
            php artisan config:cache
            php artisan route:cache
            php artisan view:cache
            pm2 restart mutuapix-api

      - name: Verify Deployment
        run: |
          sleep 5
          curl -f https://api.mutuapix.com/api/v1/health || exit 1

  deploy-frontend:
    name: Deploy Frontend
    runs-on: ubuntu-latest
    needs: deploy-backend  # Deploy backend primeiro

    steps:
      - uses: actions/checkout@v3

      - name: Deploy to VPS
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.FRONTEND_HOST }}
          username: root
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /var/www/mutuapix-frontend-production
            git pull origin main
            npm install
            rm -rf .next
            npm run build
            cp -r .next/static .next/standalone/.next/
            cp -r public .next/standalone/
            pm2 restart mutuapix-frontend

      - name: Verify Deployment
        run: |
          sleep 5
          curl -f https://matrix.mutuapix.com/login || exit 1

      - name: Notify Success
        if: success()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: 'Production deployment successful! 🚀'
          webhook_url: ${{ secrets.SLACK_WEBHOOK }}
```

---

## 📊 Camada 4 - Monitoramento e Alertas

### Cron Job - Limpeza Automática de Código Legado

**Localização:** `scripts/cleanup-legacy-code.sh`

```bash
#!/bin/bash

echo "🧹 Legacy Code Cleanup"
echo "====================="
echo ""

WORKSPACE="/Users/lucascardoso/Desktop/MUTUA"
REPORT_FILE="$WORKSPACE/legacy-cleanup-report-$(date +%Y%m%d).md"

echo "# Legacy Code Cleanup Report" > $REPORT_FILE
echo "**Date:** $(date +%Y-%m-%d)" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# ====================
# 1. ARQUIVOS ÓRFÃOS PHP
# ====================
echo "## Orphaned PHP Files" >> $REPORT_FILE
echo "" >> $REPORT_FILE

ORPHANED_PHP=$(find $WORKSPACE/backend -maxdepth 1 -name "*.php" ! -name "artisan" 2>/dev/null)

if [ ! -z "$ORPHANED_PHP" ]; then
  echo "⚠️  Found orphaned PHP files:" | tee -a $REPORT_FILE
  echo "$ORPHANED_PHP" | tee -a $REPORT_FILE
  echo "" >> $REPORT_FILE
  echo "**Action:** Remove these files" >> $REPORT_FILE
else
  echo "✅ No orphaned PHP files" | tee -a $REPORT_FILE
fi

echo "" >> $REPORT_FILE

# ====================
# 2. DIRETÓRIOS DE ARQUIVO
# ====================
echo "## Archive Directories" >> $REPORT_FILE
echo "" >> $REPORT_FILE

ARCHIVE_DIRS=$(find $WORKSPACE/frontend -type d -name "*archive*" -o -name "*temp*" 2>/dev/null)

if [ ! -z "$ARCHIVE_DIRS" ]; then
  echo "⚠️  Found archive directories:" | tee -a $REPORT_FILE
  echo "$ARCHIVE_DIRS" | tee -a $REPORT_FILE
  echo "" >> $REPORT_FILE

  # Calcular tamanho
  for dir in $ARCHIVE_DIRS; do
    SIZE=$(du -sh "$dir" | cut -f1)
    echo "  - $dir ($SIZE)" | tee -a $REPORT_FILE
  done

  echo "" >> $REPORT_FILE
  echo "**Action:** Review and remove if > 6 months old" >> $REPORT_FILE
else
  echo "✅ No archive directories" | tee -a $REPORT_FILE
fi

echo "" >> $REPORT_FILE

# ====================
# 3. TODOs ANTIGOS (> 90 dias)
# ====================
echo "## Old TODOs (> 90 days)" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# Encontrar TODOs em commits antigos
OLD_TODOS=$(git log --since="90 days ago" --all --pretty=format:"%h %s" | grep -i "TODO\|FIXME" | wc -l)

echo "Found $OLD_TODOS TODOs in commits from last 90 days" | tee -a $REPORT_FILE

# Encontrar TODOs atuais
CURRENT_BACKEND_TODOS=$(grep -r "TODO\|FIXME" $WORKSPACE/backend/app/ 2>/dev/null | wc -l | xargs)
CURRENT_FRONTEND_TODOS=$(grep -r "TODO\|FIXME" $WORKSPACE/frontend/src/ 2>/dev/null | wc -l | xargs)

echo "" >> $REPORT_FILE
echo "Current TODOs:" | tee -a $REPORT_FILE
echo "  - Backend: $CURRENT_BACKEND_TODOS" | tee -a $REPORT_FILE
echo "  - Frontend: $CURRENT_FRONTEND_TODOS" | tee -a $REPORT_FILE

echo "" >> $REPORT_FILE

# ====================
# 4. CONSOLE.LOG EM PRODUÇÃO
# ====================
echo "## Console.log in Production" >> $REPORT_FILE
echo "" >> $REPORT_FILE

CONSOLE_LOGS=$(grep -r "console\\.log" $WORKSPACE/frontend/src/ 2>/dev/null | grep -v "debug\|test\|example" | wc -l | xargs)

if [ "$CONSOLE_LOGS" -gt 0 ]; then
  echo "⚠️  Found $CONSOLE_LOGS console.log in production code" | tee -a $REPORT_FILE
  echo "" >> $REPORT_FILE
  echo "**Action:** Replace with logger" >> $REPORT_FILE
else
  echo "✅ No console.log in production code" | tee -a $REPORT_FILE
fi

echo "" >> $REPORT_FILE

# ====================
# 5. IMPORTS NÃO UTILIZADOS
# ====================
echo "## Unused Imports" >> $REPORT_FILE
echo "" >> $REPORT_FILE

cd $WORKSPACE/frontend

UNUSED_IMPORTS=$(npx eslint src/ --quiet --rule 'no-unused-vars: error' 2>/dev/null | grep "is defined but never used" | wc -l | xargs)

if [ "$UNUSED_IMPORTS" -gt 0 ]; then
  echo "⚠️  Found $UNUSED_IMPORTS unused imports" | tee -a $REPORT_FILE
  echo "" >> $REPORT_FILE
  echo "**Action:** Run 'npx eslint src/ --fix'" >> $REPORT_FILE
else
  echo "✅ No unused imports" | tee -a $REPORT_FILE
fi

cd $WORKSPACE

echo "" >> $REPORT_FILE

# ====================
# 6. ESTATÍSTICAS FINAIS
# ====================
echo "## Summary" >> $REPORT_FILE
echo "" >> $REPORT_FILE

TOTAL_ISSUES=$(($([ ! -z "$ORPHANED_PHP" ] && echo 1 || echo 0) + $([ ! -z "$ARCHIVE_DIRS" ] && echo 1 || echo 0) + $([ $CONSOLE_LOGS -gt 0 ] && echo 1 || echo 0) + $([ $UNUSED_IMPORTS -gt 0 ] && echo 1 || echo 0)))

echo "**Total Issues Found:** $TOTAL_ISSUES" | tee -a $REPORT_FILE

if [ $TOTAL_ISSUES -eq 0 ]; then
  echo "" >> $REPORT_FILE
  echo "🎉 **No legacy code issues found!**" | tee -a $REPORT_FILE
else
  echo "" >> $REPORT_FILE
  echo "⚠️  **Action required:** Review and fix issues above" | tee -a $REPORT_FILE
fi

echo ""
echo "Report saved to: $REPORT_FILE"

# Enviar report por email ou Slack (se configurado)
# ...
```

**Configurar Cron (rodar semanalmente):**
```bash
# Editar crontab
crontab -e

# Adicionar linha (toda segunda-feira às 9h)
0 9 * * 1 /Users/lucascardoso/Desktop/MUTUA/scripts/cleanup-legacy-code.sh
```

---

## 🎯 Checklist de Implementação

### Fase 1 - Git Hooks (1 dia)
- [ ] Criar `pre-commit` hook
- [ ] Criar `commit-msg` hook
- [ ] Criar `post-checkout` hook
- [ ] Criar `pre-push` hook
- [ ] Testar todos os hooks
- [ ] Documentar uso para equipe

### Fase 2 - Claude Code Hooks (1 dia)
- [ ] Criar `session-start.sh`
- [ ] Configurar PreToolUse (Edit)
- [ ] Configurar PostToolUse (Edit)
- [ ] Testar todos os hooks
- [ ] Integrar com comandos slash

### Fase 3 - CI/CD (2 dias)
- [ ] Criar workflow `ci.yml`
- [ ] Criar workflow `deploy-production.yml`
- [ ] Configurar secrets no GitHub
- [ ] Testar pipeline completo
- [ ] Configurar notificações (Slack)

### Fase 4 - Automação de Limpeza (1 dia)
- [ ] Criar `cleanup-legacy-code.sh`
- [ ] Configurar cron job
- [ ] Testar geração de relatório
- [ ] Configurar envio de relatório

### Fase 5 - Documentação (1 dia)
- [ ] Documentar todos os hooks
- [ ] Criar guia de troubleshooting
- [ ] Treinar equipe
- [ ] Criar runbook de manutenção

---

## 📚 Referências e Fontes

### Claude Code
- Hooks Guide: https://liquidmetal.ai/casesAndBlogs/claude-code-hooks-guide/
- Best Practices: https://www.anthropic.com/engineering/claude-code-best-practices

### Laravel
- Testing: https://laravel.com/docs/12.x/testing
- Pint: https://laravel.com/docs/12.x/pint
- Cashier (Stripe): https://laravel.com/docs/12.x/billing

### Next.js
- Testing with Vitest: https://nextjs.org/docs/app/guides/testing/vitest
- App Router: https://nextjs.org/docs/app

### Stripe Webhooks
- Webhook Best Practices: https://docs.stripe.com/webhooks
- Laravel Integration: https://github.com/spatie/laravel-stripe-webhooks

### CI/CD
- GitHub Actions: https://docs.github.com/en/actions
- Security Scanning: https://github.com/aquasecurity/trivy-action

---

**Última atualização:** 2025-10-07
**Próxima revisão:** Após implementação completa
