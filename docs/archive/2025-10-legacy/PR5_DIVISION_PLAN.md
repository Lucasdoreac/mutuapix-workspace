# Plano de Divisão do PR #5 - Production Sync

**Data:** 2025-10-09
**PR Original:** #5 - 89,167 adições / 2,988 deleções / 702 arquivos
**Estratégia:** Dividir em 10 PRs temáticos para revisão adequada

---

## 📊 Análise de Módulos

| Módulo | Arquivos | Prioridade | Risco |
|--------|----------|------------|-------|
| Core & Config | 45 | 🔴 Alta | Médio |
| Autenticação | 22 | 🔴 Alta | Alto |
| Pagamentos (PIX/Stripe/Pagarme) | 144 | 🔴 Alta | Alto |
| Cursos & Aulas | 61 | 🟡 Média | Baixo |
| Gamificação | 88 | ⚪ Baixa | Baixo (não é MVP) |
| Comunidade | 33 | 🟡 Média | Baixo |
| Afiliados | 65 | ⚪ Baixa | Baixo (não é MVP) |
| Admin & Analytics | 67 | 🟡 Média | Médio |
| Notificações & Eventos | 66 | 🟡 Média | Baixo |
| Infraestrutura | 70 | 🔴 Alta | Médio |

---

## 🎯 PRs Propostos (Ordem de Implementação)

### PR A: Core & Infrastructure (~115 arquivos)
**Prioridade:** 🔴 Crítica
**Arquivos:**
- `config/*` - Configurações do Laravel
- `bootstrap/*` - Bootstrap da aplicação
- `app/Providers/*` - Service Providers
- `app/Console/Kernel.php` - Task scheduling
- `app/Exceptions/*` - Exception handlers
- `app/Helpers/*` - Helper functions

**Descrição:**
```
feat(core): sync Laravel core structure from production

Sincroniza estrutura core do Laravel incluindo:
- Configurações de ambiente
- Service providers
- Exception handling
- Console kernel
- Helpers e utilities

Risco: 🟡 MÉDIO - Base da aplicação
```

---

### PR B: Authentication System (~22 arquivos)
**Prioridade:** 🔴 Crítica
**Arquivos:**
- `app/Http/Controllers/Auth/*`
- `app/Models/User.php`
- `app/Http/Middleware/Authenticate.php`
- `app/Http/Requests/Auth/*`
- `routes/api/auth.php`

**Descrição:**
```
feat(auth): sync authentication system from production

Sistema completo de autenticação incluindo:
- Login/Register/Logout
- Password reset
- Email verification
- Sanctum token management

Risco: 🔴 ALTO - Sistema crítico de segurança
```

---

### PR C: Payment System - PIX (~60 arquivos)
**Prioridade:** 🔴 Crítica (MVP)
**Arquivos:**
- `app/Http/Controllers/*Pix*`
- `app/Services/PixPaymentService.php`
- `app/Models/Donation.php`
- `app/Models/PixLevel.php`
- `app/Jobs/*Pix*`
- `routes/api/pix.php`

**Descrição:**
```
feat(payments): sync PIX payment system from production

Sistema PIX incluindo:
- QR Code generation
- Payment verification
- Donation tracking
- PIX levels/gamification
- Webhook handling

Risco: 🔴 ALTO - Processamento de pagamentos
```

---

### PR D: Payment System - Stripe & Pagarme (~50 arquivos)
**Prioridade:** 🔴 Crítica (MVP)
**Arquivos:**
- `app/Http/Controllers/*Stripe*`
- `app/Http/Controllers/*Pagarme*`
- `app/Services/StripeService.php`
- `app/Services/PaymentGatewayFactory.php`
- `app/Models/Subscription.php`
- `routes/api/payments.php`

**Descrição:**
```
feat(payments): sync Stripe and Pagarme integrations from production

Integrações de pagamento incluindo:
- Stripe checkout & subscriptions
- Pagarme integration
- Payment gateway abstraction
- Subscription management
- Webhooks

Risco: 🔴 ALTO - Processamento de pagamentos
```

---

### PR E: Course Management System (~61 arquivos)
**Prioridade:** 🟡 Alta (MVP)
**Arquivos:**
- `app/Http/Controllers/*Course*`
- `app/Http/Controllers/*Lesson*`
- `app/Http/Controllers/*Module*`
- `app/Models/Course.php`
- `app/Models/Lesson.php`
- `app/Models/Module.php`
- `app/Models/StudentProgress.php`
- `app/Services/CourseProgressCacheService.php`

**Descrição:**
```
feat(courses): sync course management system from production

Sistema de cursos incluindo:
- Course/Module/Lesson CRUD
- Student progress tracking
- Video streaming (Bunny CDN)
- Course completion
- Progress caching

Risco: 🟡 MÉDIO - Funcionalidade core
```

---

### PR F: Admin & Analytics (~67 arquivos)
**Prioridade:** 🟡 Média (MVP - suporte)
**Arquivos:**
- `app/Http/Controllers/Admin/*`
- `app/Services/AnalyticsService.php`
- `app/Services/ReportService.php`
- `app/Models/Ticket.php`
- `app/Models/UserActivity.php`

**Descrição:**
```
feat(admin): sync admin panel and analytics from production

Painel administrativo incluindo:
- User management
- Analytics dashboard
- Report generation
- Support ticket system
- Activity logging

Risco: 🟡 MÉDIO - Acesso administrativo
```

---

### PR G: Notifications & Events (~66 arquivos)
**Prioridade:** 🟢 Média
**Arquivos:**
- `app/Events/*`
- `app/Notifications/*`
- `app/Listeners/*`
- `app/Mail/*`

**Descrição:**
```
feat(notifications): sync notification system from production

Sistema de notificações incluindo:
- Event-driven architecture
- Email notifications
- Database notifications
- WebSocket broadcasting
- Mailable classes

Risco: 🟢 BAIXO - Não crítico
```

---

### PR H: Community Features (~33 arquivos)
**Prioridade:** 🟢 Baixa
**Arquivos:**
- `app/Http/Controllers/*Community*`
- `app/Http/Controllers/*Forum*`
- `app/Models/Post.php`
- `app/Models/Comment.php`
- `routes/api/community.php`

**Descrição:**
```
feat(community): sync community features from production

Funcionalidades de comunidade:
- Forum system
- Posts & comments
- User interactions
- Moderation tools

Risco: 🟢 BAIXO - Feature não crítica
```

---

### PR I: Affiliate System (~65 arquivos)
**Prioridade:** ⚪ Baixa (Não MVP)
**Arquivos:**
- `app/Http/Controllers/*Affiliate*`
- `app/Models/Affiliate.php`
- `app/Models/Commission.php`
- `app/Services/AffiliateService.php`

**Descrição:**
```
feat(affiliates): sync affiliate system from production

Sistema de afiliados incluindo:
- Affiliate registration
- Commission tracking
- Conversion tracking
- Payment processing

Risco: 🟢 BAIXO - Não é MVP, pode ser adiado
```

---

### PR J: Gamification System (~88 arquivos)
**Prioridade:** ⚪ Não implementar (Não MVP)
**Status:** ❌ **SKIP - Será removido pelo PR #6**

**Arquivos:**
- `app/Http/Controllers/Gamification/*`
- `app/Models/*Point*`
- `app/Models/*Achievement*`
- `app/Services/GamificationService.php`

**Motivo:** Segundo MUTUAPIX_WORKFLOW_OFICIAL.md, gamificação não faz parte do MVP e será removida pelo PR #6.

---

## 📋 Ordem de Execução Recomendada

### Fase 1: Crítico (Semana 1)
1. ✅ **PR A** - Core & Infrastructure (base)
2. ✅ **PR B** - Authentication (segurança)
3. ✅ **PR C** - PIX Payment (MVP)
4. ✅ **PR D** - Stripe/Pagarme (MVP)

### Fase 2: Importante (Semana 2)
5. ✅ **PR E** - Course Management (MVP)
6. ✅ **PR F** - Admin & Analytics (MVP - suporte)

### Fase 3: Complementar (Semana 3)
7. ✅ **PR G** - Notifications & Events
8. ✅ **PR H** - Community Features

### Fase 4: Opcional (Quando necessário)
9. ⚪ **PR I** - Affiliate System (não MVP, pode aguardar)
10. ❌ **PR J** - Gamification (SKIP - não MVP)

---

## 🔧 Script de Execução

Para cada PR, seguir este template:

```bash
# 1. Checkout main
git checkout main
git pull origin main

# 2. Criar nova branch
git checkout -b sync/module-name

# 3. Copiar arquivos específicos do módulo
git checkout feature/sync-production-code-2025-10-07 -- <arquivos>

# 4. Commit
git add .
git commit -m "feat(module): sync module from production"

# 5. Push e criar PR
git push -u origin sync/module-name
gh pr create --base main --head sync/module-name \
  --title "feat(module): sync from production" \
  --body "<descrição do PR>"
```

---

## ⚠️ Considerações Importantes

### Segurança
- [ ] Verificar cada PR com `trufflehog` antes de mergear
- [ ] Confirmar que `.env` files não foram incluídos
- [ ] Revisar credenciais e secrets

### Testes
- [ ] Cada PR deve passar em `php artisan test`
- [ ] Verificar que migrations funcionam
- [ ] Testar funcionalidade básica do módulo

### Dependências
- Alguns PRs dependem de outros (ex: Payments depende de Core)
- Seguir ordem de execução recomendada
- Não mergear PRs que dependem de outros não mergeados

### Rollback
- Cada PR é independente, facilitando rollback
- Marcar commits com tags (ex: `sync-core-v1`)
- Documentar estado antes/depois de cada merge

---

## 📝 Próximos Passos

1. **Agora:** Criar PR A (Core & Infrastructure)
2. **Após review:** Mergear e criar PR B (Authentication)
3. **Iterativo:** Continuar com PRs C, D, E, F conforme revisão
4. **Paralelo:** PRs G e H podem ser criados em paralelo após E/F
5. **Opcional:** Decidir se PR I é necessário antes de implementar

---

**Status:** ✅ Plano aprovado, pronto para execução
**Estimativa de tempo total:** 3 semanas
**Benefícios:** Revisão adequada, rollback granular, histórico limpo
