# 🔔 Monitoramento Completo - MutuaPIX

**Data:** 2025-10-17
**Status:** ✅ Sentry Configurado | ⏳ UptimeRobot Pendente
**Objetivo:** Monitoramento proativo de erros, performance e disponibilidade

---

## 📊 Status Atual

### ✅ Configurado

**1. Sentry (Error & Performance Monitoring)**
- Status: ✅ Instalado e configurado
- Documentação: `frontend/SENTRY.md`
- DSN: Configurado
- Org: golber-doria
- Project: mutuapix-matrix

**Validação:**
```bash
cd frontend
npm run validate-sentry
```

### ⏳ Pendente

**2. UptimeRobot (Uptime Monitoring)**
- Status: ⏳ Não configurado
- Setup time: ~10 minutos
- Custo: Gratuito (até 50 monitores)

**3. Lighthouse CI (Performance Regression)**
- Status: ⏳ Não configurado
- Setup time: ~20 minutos
- Custo: Gratuito

**4. Slack/Discord Notifications**
- Status: ⏳ Não configurado
- Setup time: ~15 minutos
- Custo: Gratuito

---

## 🎯 Monitoramento em Camadas

### Camada 1: Error Tracking (✅ ATIVO)

**Ferramenta:** Sentry
**O que monitora:**
- JavaScript errors (frontend)
- Unhandled exceptions
- API call failures
- User session replays (se configurado)

**Como usar:**
```typescript
import * as Sentry from '@sentry/nextjs';

// Manual error capture
try {
  // código
} catch (error) {
  Sentry.captureException(error);
}

// User context
Sentry.setUser({ id: user.id, email: user.email });

// Custom breadcrumbs
Sentry.addBreadcrumb({
  message: 'User clicked login button',
  level: 'info'
});
```

**Dashboard:** https://sentry.io/organizations/golber-doria/projects/mutuapix-matrix/

---

### Camada 2: Performance Monitoring (✅ ATIVO via MCP)

**Ferramenta:** Chrome DevTools Performance Trace (MCP)
**O que monitora:**
- Core Web Vitals (CLS, LCP, FID)
- Forced reflows
- Long tasks
- Network waterfall

**Como usar:**
```javascript
// Via MCP
mcp__chrome-devtools__performance_start_trace({
  reload: true,
  autoStop: true
})

// Análise de insights
mcp__chrome-devtools__performance_analyze_insight({
  insightName: "ForcedReflow"
})
```

**Baseline estabelecido:** `PERFORMANCE_BASELINE_2025_10_17.md`

**Métricas atuais:**
- CLS: 0.00 ✅
- Forced Reflow: 222ms ⚠️

---

### Camada 3: Uptime Monitoring (⏳ PENDENTE)

**Ferramenta:** UptimeRobot
**O que monitora:**
- Disponibilidade (HTTP 200)
- Response time
- SSL certificate expiry
- Downtime alerts

**Setup Recomendado:**

1. **Criar conta:** https://uptimerobot.com/

2. **Adicionar monitores:**

**Monitor 1: Frontend**
```
Type: HTTP(s)
URL: https://matrix.mutuapix.com/login
Name: MutuaPIX Frontend - Login Page
Interval: 5 minutes
HTTP Method: GET
Expected Status: 200
Alert Contacts: seu-email@domain.com
```

**Monitor 2: Backend API Health**
```
Type: HTTP(s)
URL: https://api.mutuapix.com/api/v1/health
Name: MutuaPIX API - Health Endpoint
Interval: 5 minutes
HTTP Method: GET
Expected Status: 200
Keyword: "ok"
Alert Contacts: seu-email@domain.com
```

**Monitor 3: SSL Certificate**
```
Type: HTTP(s)
URL: https://matrix.mutuapix.com
Name: MutuaPIX - SSL Certificate
Interval: 1 day
Alert if: SSL expires in < 30 days
```

3. **Configurar alertas:**
- Email notifications: Immediate
- SMS (opcional): Critical only
- Webhook: Slack/Discord (ver Camada 5)

**Dashboards:**
- Public Status Page: Opcional (pode compartilhar com usuários)
- Private Dashboard: Para equipe

---

### Camada 4: Lighthouse CI (⏳ PENDENTE)

**Ferramenta:** Lighthouse CI
**O que monitora:**
- Performance score (0-100)
- Accessibility score
- Best practices
- SEO score
- Progressive Web App readiness

**Setup:**

1. **Instalar Lighthouse CI:**
```bash
npm install -g @lhci/cli
```

2. **Criar configuração:**
```javascript
// lighthouserc.js
module.exports = {
  ci: {
    collect: {
      url: ['https://matrix.mutuapix.com/login'],
      numberOfRuns: 3,
    },
    upload: {
      target: 'temporary-public-storage',
    },
    assert: {
      assertions: {
        'categories:performance': ['error', {minScore: 0.8}],
        'categories:accessibility': ['error', {minScore: 0.9}],
        'first-contentful-paint': ['error', {maxNumericValue: 2000}],
        'largest-contentful-paint': ['error', {maxNumericValue: 2500}],
        'cumulative-layout-shift': ['error', {maxNumericValue: 0.1}],
      },
    },
  },
};
```

3. **Integrar com CI/CD:**
```yaml
# .github/workflows/lighthouse.yml
name: Lighthouse CI
on: [push, pull_request]
jobs:
  lighthouse:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-node@v2
      - run: npm install
      - run: npm run build
      - run: npm install -g @lhci/cli
      - run: lhci autorun
```

**Budget Warnings:**
```json
{
  "performance": 80,
  "accessibility": 90,
  "best-practices": 85,
  "seo": 90,
  "pwa": 50
}
```

---

### Camada 5: Slack/Discord Notifications (⏳ PENDENTE)

**Ferramenta:** Webhooks
**O que notifica:**
- Deployment success/failure
- Sentry errors (threshold-based)
- UptimeRobot downtime alerts
- Lighthouse CI regressions

**Setup - Slack:**

1. **Criar Incoming Webhook:**
   - https://api.slack.com/messaging/webhooks
   - Channel: #mutuapix-alerts
   - Copy webhook URL

2. **Adicionar ao GitHub Secrets:**
```bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

3. **Integrar no deployment:**
```yaml
# .github/workflows/deploy-backend.yml
- name: Notify Slack - Success
  if: success()
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
    -H 'Content-Type: application/json' \
    -d '{
      "text": "✅ Backend deployment successful",
      "blocks": [
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": "*Backend Deployment Complete*\n✅ Status: Success\n🚀 Environment: Production\n📝 Commit: ${{ github.sha }}"
          }
        }
      ]
    }'

- name: Notify Slack - Failure
  if: failure()
  run: |
    curl -X POST ${{ secrets.SLACK_WEBHOOK_URL }} \
    -H 'Content-Type: application/json' \
    -d '{
      "text": "❌ Backend deployment failed",
      "blocks": [
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": "*Backend Deployment Failed*\n❌ Status: Failure\n🚨 Environment: Production\n📝 Commit: ${{ github.sha }}\n🔗 Logs: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
          }
        }
      ]
    }'
```

4. **Sentry → Slack:**
   - Sentry Dashboard → Settings → Integrations → Slack
   - Authorize Slack workspace
   - Configure alert rules

**Setup - Discord:**

Similar ao Slack, mas usando Discord webhook URL.

---

## 🎯 Prioridades de Implementação

### Crítico (Fazer Agora - 30 min)
1. ✅ **Sentry** - Já configurado
2. ⏳ **UptimeRobot** - 10 minutos
   - Frontend health check
   - Backend API health check
   - SSL monitoring

### Alto (Esta Semana - 1-2h)
3. ⏳ **Slack Notifications** - 15 minutos
   - Webhook setup
   - Deployment notifications
   - Sentry integration

4. ⏳ **Lighthouse CI** - 30 minutos
   - Local configuration
   - GitHub Actions integration
   - Performance budgets

### Médio (Próximo Mês)
5. **Advanced Sentry Features**
   - Session replays
   - User feedback widget
   - Performance profiling

6. **Custom Dashboards**
   - Grafana ou similar
   - Métricas customizadas
   - Business metrics

---

## 📋 Checklist de Monitoramento

### Diário (Automatizado)
- [ ] Sentry errors < 10/day
- [ ] UptimeRobot uptime > 99.9%
- [ ] API response time < 500ms
- [ ] No critical alerts

### Semanal (Manual - 5 min)
- [ ] Review Sentry error trends
- [ ] Check performance baseline (MCP trace)
- [ ] Verify backup integrity
- [ ] Review deployment logs

### Mensal (Manual - 30 min)
- [ ] Lighthouse audit comparison
- [ ] Performance optimization review
- [ ] Alert threshold adjustment
- [ ] Documentation updates
- [ ] Security patches review

---

## 🚨 Alert Thresholds

### Critical (Immediate Response)
- Frontend downtime > 1 minute
- Backend API downtime > 1 minute
- Error rate > 50 errors/hour
- P95 response time > 5 seconds

### Warning (Review Within 1 Hour)
- Error rate > 10 errors/hour
- Uptime < 99.5% (last 24h)
- Performance score < 80
- CLS > 0.1

### Info (Review Daily)
- New error types
- Performance degradation > 10%
- High memory usage
- Slow queries

---

## 📊 Dashboards

### Sentry Dashboard
**URL:** https://sentry.io/organizations/golber-doria/projects/mutuapix-matrix/

**Views:**
- Issues (errors)
- Performance (transactions)
- Releases (deployments)
- User Feedback

### UptimeRobot Dashboard (Quando Configurado)
**URL:** https://uptimerobot.com/dashboard

**Views:**
- Uptime percentage
- Response times
- Incident history
- Status page (público)

### MCP Performance (Local)
**Command:**
```javascript
mcp__chrome-devtools__performance_start_trace({
  reload: true,
  autoStop: true
})
```

**Reports:** `PERFORMANCE_BASELINE_*.md`

---

## 🔧 Troubleshooting

### Sentry não está capturando errors

**1. Verificar configuração:**
```bash
npm run validate-sentry
```

**2. Testar captura manual:**
```typescript
import * as Sentry from '@sentry/nextjs';
Sentry.captureMessage('Test error from dev');
```

**3. Verificar DSN:**
```bash
echo $NEXT_PUBLIC_SENTRY_DSN
# Deve retornar: https://8f53a971e6b56268413dc114fb541ed1@...
```

**4. Verificar network:**
- Abrir DevTools → Network
- Procurar requests para `sentry.io`
- Status deve ser 200

### UptimeRobot mostrando false positives

**Causas comuns:**
- Timeout muito curto (aumentar para 30s)
- Keyword check muito restritivo
- Firewall bloqueando UptimeRobot IPs

**Solução:**
```nginx
# Whitelist UptimeRobot IPs
# /etc/nginx/conf.d/uptimerobot.conf
allow 46.137.190.132;
allow 63.143.42.242;
# ... (ver lista completa em uptimerobot.com)
```

### Performance baseline inconsistente

**Causas:**
- Network throttling
- Server load variation
- Browser cache

**Solução:**
- Rodar 3-5 traces e calcular média
- Usar MCP com `reload: true` para cache limpo
- Rodar em horários consistentes

---

## 📞 Suporte e Recursos

### Sentry
- Docs: https://docs.sentry.io/platforms/javascript/guides/nextjs/
- Status: https://status.sentry.io/
- Support: support@sentry.io

### UptimeRobot
- Docs: https://uptimerobot.com/api/
- Support: https://uptimerobot.com/contact/

### Lighthouse CI
- Docs: https://github.com/GoogleChrome/lighthouse-ci
- Community: https://github.com/GoogleChrome/lighthouse-ci/discussions

---

## 📝 Próximos Passos

### Implementar Agora (30 min)
1. **Criar conta UptimeRobot**
   - Sign up: https://uptimerobot.com/
   - Add 3 monitors (frontend, backend, SSL)
   - Configure email alerts

2. **Testar Sentry em produção**
   - Navegar para https://matrix.mutuapix.com
   - Verificar se sessões aparecem no Sentry
   - Revisar performance transactions

### Esta Semana (2h)
3. **Configurar Slack Notifications**
   - Create webhook
   - Add to GitHub secrets
   - Test deployment notification

4. **Setup Lighthouse CI**
   - Install locally
   - Configure budgets
   - Integrate with GitHub Actions

### Próximo Mês
5. **Advanced Monitoring**
   - Session replays no Sentry
   - Custom dashboards (Grafana)
   - Business metrics tracking

---

**Status:** ✅ Sentry Ativo | ⏳ UptimeRobot Pendente (10 min)
**Próxima Ação:** Criar conta no UptimeRobot e configurar 3 monitores
**Tempo Estimado:** 10-15 minutos

🎯 **Monitoramento é crucial para manter 99.9% uptime e detectar issues antes dos usuários!**
