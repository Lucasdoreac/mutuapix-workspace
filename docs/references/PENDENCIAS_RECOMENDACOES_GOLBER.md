# Pendências das Recomendações do Golber

**Data**: 2025-10-07
**Referência**: Inventário MutuaPIX + Workflow Oficial

---

## ✅ O Que JÁ Foi Feito (Hoje)

1. ✅ **Segurança crítica**: Removido `.envsecure/` com master keys
2. ✅ **Limpeza**: Removido arquivos temporários (.bak, .backup, .disabled)
3. ✅ **Versões**: Atualizado React 19, PHP 8.3, Node 20
4. ✅ **PRs criados**: Backend #5 e Frontend #3 com comentários

---

## ❌ O Que AINDA Falta Fazer

### 🚨 CRÍTICO (Bloqueadores de MVP)

#### 1. Webhooks Stripe (Responsabilidade Lucas)

**Recomendado**:
```
✅ checkout.session.completed (JÁ TEM)
❌ customer.subscription.updated (FALTA)
❌ invoice.payment_failed (FALTA)
```

**Onde implementar**:
- Backend: `app/Jobs/ProcessStripeWebhook.php`
- Adicionar cases para os 2 eventos faltantes

**Impacto**: **CRÍTICO** - Sem isso, assinaturas não atualizam e pagamentos falhos não são tratados

**Estimativa**: 2-3 horas

---

#### 2. Testes Automatizados (ZERO cobertura)

**Recomendado (Workflow)**:
```
✅ Feature tests
✅ CI verde antes de merge
```

**Atual**:
- Backend: ❌ 0% de cobertura (sem testes)
- Frontend: ❌ <1% de cobertura (apenas 1 teste)

**Mínimo para MVP**:
```php
// Backend (tests/Feature/)
- AuthTest.php (login, register, logout)
- CourseEnrollmentTest.php (assinar curso, assistir aula)
- StripeWebhookTest.php (3 webhooks)
- PixHelpTest.php (doar, confirmar)
- SupportTicketTest.php (abrir ticket)
```

```typescript
// Frontend (src/__tests__/)
- LoginPage.test.tsx
- CourseList.test.tsx
- PixHelpPage.test.tsx
- Checkout.test.tsx
```

**Impacto**: **CRÍTICO** - Workflow exige CI verde

**Estimativa**: 1-2 dias

---

#### 3. CI/CD Workflows (GitHub Actions)

**Recomendado (Inventário)**:
```yaml
.github/workflows/
├── tests.yml (lint, typecheck, build, testes)
├── deploy-staging.yml (merge em develop)
└── deploy-production.yml (merge em main)
```

**Atual**: ❌ Nenhum workflow existe

**O que precisa**:
```yaml
# tests.yml (Backend)
- composer install
- php artisan test
- phpstan analyse

# tests.yml (Frontend)
- npm install
- npm run lint
- npm run typecheck
- npm run test
- npm run build

# deploy-staging.yml
- rsync para /var/www/staging-api.mutuapix.com/
- composer install / npm build
- php artisan migrate --force
- restart php-fpm/pm2

# deploy-production.yml (mesma coisa para produção)
```

**Impacto**: **CRÍTICO** - Workflow core ausente

**Estimativa**: 1 dia (Golber responsável)

---

#### 4. Staging Environment

**Recomendado (Inventário)**:
```
Backend:
- staging-api.mutuapix.com → 49.13.26.142
- /var/www/staging-api.mutuapix.com/current

Frontend:
- staging-matrix.mutuapix.com → 138.199.162.115
- /var/www/staging-matrix.mutuapix.com/current
```

**Atual**: ❌ Não existe (apenas produção)

**O que precisa**:
1. Criar vhosts Nginx para staging
2. Criar diretórios `/var/www/staging-*`
3. Configurar DNS no Cloudflare
4. Emitir SSL (Certbot) para staging
5. Criar `.env` de staging
6. Criar DB `mutuapix_staging`

**Impacto**: **CRÍTICO** - Workflow exige staging antes de produção

**Estimativa**: 2-3 horas (Golber responsável)

---

### ⚠️ IMPORTANTE (MVP Incompleto)

#### 5. Stripe UI (Frontend)

**Recomendado (Divisão de Tarefas - Golber)**:
```
✅ Stripe-UI/Checkout/Portal (responsabilidade Golber)
```

**Atual**: ❌ Não encontrado no código

**O que precisa**:
```
Frontend:
- /checkout/page.tsx (Stripe Checkout)
- /portal/page.tsx (Customer Portal)
- Componente de seleção de plano
```

**Backend**: ✅ Já tem webhook e StripeService.php

**Impacto**: **ALTO** - MVP item #2 ("Assinar (Stripe)") incompleto

**Estimativa**: 1 dia (Golber)

---

#### 6. Suporte UI (Frontend)

**Recomendado (Divisão de Tarefas - Lucas)**:
```
✅ Tickets de Suporte (responsabilidade Lucas)
```

**Atual**:
- Backend: ✅ `SupportTicketController.php` existe
- Frontend: ❌ UI não encontrada

**O que precisa**:
```
Frontend:
- /suporte/page.tsx (listar tickets)
- /suporte/novo/page.tsx (criar ticket)
- /suporte/[id]/page.tsx (ver ticket)
```

**Impacto**: **ALTO** - MVP item #6 ("Abrir ticket de suporte") incompleto

**Estimativa**: 4-6 horas (Lucas)

---

### 📋 RECOMENDADO (Qualidade e Processo)

#### 7. Branch Protection (GitHub)

**Recomendado (Workflow)**:
```
✅ Proibido commit direto em main
✅ PR obrigatório com 1 review
✅ CI deve passar antes de merge
```

**Atual**: ❌ Não configurado

**Como ativar**:
1. GitHub → Settings → Branches → Branch protection rules
2. Adicionar rules para `main` e `develop`:
   - ✅ Require pull request reviews (1 approval)
   - ✅ Require status checks to pass (tests workflow)
   - ✅ Require branches to be up to date
   - ✅ Do not allow bypassing

**Impacto**: **MÉDIO** - Processo de qualidade

**Estimativa**: 15 minutos (Golber)

---

#### 8. Secrets do GitHub Actions

**Recomendado (Inventário)**:
```
API (staging/prod):
- SSH_HOST, SSH_USER=deploy, SSH_KEY
- APP_DIR, PHP_VERSION, COMPOSER_NO_INTERACTION

MATRIX (staging/prod):
- SSH_HOST, SSH_USER=deploy, SSH_KEY
- APP_DIR, NODE_VERSION=20, PM2_APP_NAME
```

**Atual**: ❌ Não configurado

**Como adicionar**:
1. GitHub → Settings → Secrets and variables → Actions
2. Criar environments: `staging`, `production`
3. Adicionar secrets por environment

**Impacto**: **MÉDIO** - CI/CD dependency

**Estimativa**: 30 minutos (Golber)

---

#### 9. Usuário de Deploy nos VPS

**Recomendado (Inventário)**:
```
Usuário: deploy (SSH)
Grupo: www-data
Chaves SSH: cadastradas para GitHub Actions
```

**Atual**: ❌ Provavelmente usando `root`

**O que precisa**:
```bash
# Backend VPS
adduser deploy
usermod -aG www-data deploy
mkdir /home/deploy/.ssh
# Adicionar chave pública do GitHub Actions

# Frontend VPS (mesma coisa)
```

**Impacto**: **MÉDIO** - Segurança e separação de responsabilidades

**Estimativa**: 30 minutos

---

#### 10. Documentação de Endpoints (OpenAPI)

**Recomendado (Divisão de Tarefas - Lucas)**:
```
✅ Documentação dos endpoints (responsabilidade Lucas)
```

**Atual**: ⚠️ `OpenApiSchemas.php` existe mas incompleto

**O que precisa**:
- Completar documentação de TODOS os endpoints MVP
- Gerar Swagger UI (`php artisan l5-swagger:generate`)
- Publicar em `/api/v1/documentation`

**Impacto**: **BAIXO** - Facilita desenvolvimento

**Estimativa**: 2-3 horas (Lucas)

---

#### 11. Estrutura de Diretórios VPS (Padronizar)

**Recomendado (Inventário)**:
```
Backend:
/var/www/api.mutuapix.com/current
/var/www/staging-api.mutuapix.com/current

Frontend:
/var/www/matrix.mutuapix.com/current
/var/www/staging-matrix.mutuapix.com/current
```

**Atual**:
```
Backend: /var/www/mutuapix-api/
Frontend: /var/www/mutuapix-frontend-production/
```

**O que precisa**:
- Reconfigurar Nginx vhosts
- Mover diretórios
- Ajustar PM2 configs

**Impacto**: **BAIXO** - Organização

**Estimativa**: 1 hora

---

### 🔍 INVESTIGAÇÃO NECESSÁRIA

#### 12. Laravel Version (11 vs 12)

**Recomendado**: Laravel 11
**Atual**: Laravel 12

**Investigar**:
- Por que está em Laravel 12? (foi upgrade intencional?)
- Laravel 12 existe? (última versão estável é 11.x)
- Precisa downgrade?

**Ação**: Verificar `composer.json` e decidir se precisa ajustar

---

#### 13. Pagarme Integration

**Recomendado**: Apenas Stripe
**Atual**: Tem `PagarmeService.php`, DTOs, webhooks

**Investigar**:
- Por que Pagarme está implementado?
- É usado em produção?
- Deve ser removido ou mantido?

**Ação**: Verificar com Golber se é legado ou se deve ficar

---

## 📊 Priorização por Score

### Score de Urgência

| Item | Urgência | Impacto | Responsável | Estimativa |
|------|----------|---------|-------------|------------|
| 1. Webhooks Stripe | 🔴 10/10 | CRÍTICO | Lucas | 2-3h |
| 2. Testes | 🔴 10/10 | CRÍTICO | Lucas | 1-2 dias |
| 3. CI/CD Workflows | 🔴 10/10 | CRÍTICO | Golber | 1 dia |
| 4. Staging Environment | 🔴 9/10 | CRÍTICO | Golber | 2-3h |
| 5. Stripe UI | 🟡 8/10 | ALTO | Golber | 1 dia |
| 6. Suporte UI | 🟡 8/10 | ALTO | Lucas | 4-6h |
| 7. Branch Protection | 🟢 6/10 | MÉDIO | Golber | 15min |
| 8. Secrets GitHub | 🟢 6/10 | MÉDIO | Golber | 30min |
| 9. Usuário Deploy | 🟢 5/10 | MÉDIO | Ambos | 30min |
| 10. Docs OpenAPI | 🟢 4/10 | BAIXO | Lucas | 2-3h |
| 11. Estrutura Dirs | 🟢 3/10 | BAIXO | Ambos | 1h |
| 12. Laravel Version | 🔵 2/10 | INVESTIGAR | - | 30min |
| 13. Pagarme | 🔵 2/10 | INVESTIGAR | - | 30min |

---

## 🎯 Plano de Ação Recomendado

### Fase 1: Bloqueadores Críticos (ANTES de merge)

**Lucas**:
1. ✅ Implementar 2 webhooks Stripe faltantes (2-3h)
2. ✅ Adicionar testes básicos MVP (1-2 dias)

**Golber**:
1. ✅ Criar staging environment (2-3h)
2. ✅ Criar workflows CI/CD básicos (1 dia)
3. ✅ Configurar branch protection (15min)
4. ✅ Adicionar secrets GitHub Actions (30min)

**Bloqueio**: Não fazer merge dos PRs até fase 1 completa.

---

### Fase 2: MVP Completo (DEPOIS de merge)

**Golber**:
1. ✅ Implementar Stripe UI (Checkout + Portal) - 1 dia

**Lucas**:
1. ✅ Implementar Suporte UI - 4-6h
2. ✅ Completar docs OpenAPI - 2-3h

---

### Fase 3: Refinamentos (Opcional)

**Ambos**:
1. ✅ Criar usuário `deploy` nos VPS - 30min
2. ✅ Padronizar estrutura de diretórios - 1h
3. ✅ Investigar Laravel 12 vs 11 - 30min
4. ✅ Decidir sobre Pagarme - 30min

---

## 📝 Notas Importantes

### Sobre os PRs Atuais

Os PRs #5 (backend) e #3 (frontend) estão **90% alinhados** após os fixes de hoje:
- ✅ Segurança resolvida
- ✅ Versões atualizadas
- ✅ Código limpo

**Mas ainda faltam**:
- ❌ Webhooks Stripe (2/3)
- ❌ Testes (0%)
- ❌ CI/CD (workflows)
- ❌ Staging environment

**Recomendação**: Fechar PRs atuais e criar novos PRs menores **após** fase 1.

---

### Sobre Divisão de Responsabilidades

**Golber é responsável por**:
- ✅ Help PIX (COMPLETO no código)
- ✅ Dashboard (COMPLETO no código)
- ❌ Stripe UI (FALTA)
- ✅ Perfil UI (COMPLETO)
- ❌ CI/CD (FALTA)

**Lucas é responsável por**:
- ✅ Cursos (COMPLETO no código)
- ⚠️ Webhooks Stripe (1/3 completo)
- ⚠️ Suporte (API completa, UI falta)
- ❌ Testes (FALTA)
- ⚠️ Docs endpoints (incompleto)

**Ambos estão ~60% completos** nas suas responsabilidades.

---

## 🚀 Timeline Estimado

**Fase 1 (Bloqueadores)**: 3-4 dias
- Lucas: 1.5-2 dias (webhooks + testes)
- Golber: 1.5-2 dias (staging + CI/CD + configs)

**Fase 2 (MVP)**: 1.5-2 dias
- Golber: 1 dia (Stripe UI)
- Lucas: 0.5-1 dia (Suporte UI + docs)

**Fase 3 (Refinamentos)**: 0.5-1 dia
- Ambos: ajustes finais

**Total**: ~5-7 dias úteis

---

**Criado por**: Claude Code
**Última atualização**: 2025-10-07
