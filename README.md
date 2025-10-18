# 📦 MutuaPIX - Workspace de Sincronização

**Criado em**: 2025-10-07
**Propósito**: Sincronizar código de produção (VPS) com repositórios oficiais do Golber

---

## 🎯 O Que É Este Workspace?

Este diretório contém uma **cópia completa** do código rodando em produção nos 2 VPS do MutuaPIX, preparada para ser sincronizada nos repositórios oficiais `golberdoria/*`.

### Problema que Resolve

- ❌ **Repos oficiais do Golber estão VAZIOS** (3 arquivos vs 447 em produção)
- ❌ **Produção usa repos errados** (Lucasdoreac/* ao invés de golberdoria/*)
- ❌ **CI/CD não funciona** (GitHub Actions não consegue fazer deploy)
- ✅ **Esta workspace permite sync seguro** (código local + Git pronto)

---

## 📁 Estrutura

```
/Users/lucascardoso/Desktop/MUTUA/
│
├── 📂 backend/                          ← golberdoria/mutuapix-api
│   ├── .git/                            ← Repo clonado, pronto para commit
│   ├── app/ (447 arquivos PHP)          ← CÓDIGO COMPLETO DO VPS
│   ├── composer.json                    ← Laravel 12 dependencies
│   └── .env ❌ NÃO COMITAR              ← Secrets de produção
│
├── 📂 frontend/                         ← golberdoria/mutuapix-matrix
│   ├── .git/                            ← Repo clonado, pronto para commit
│   ├── src/ (752 arquivos TS/TSX)       ← CÓDIGO COMPLETO DO VPS
│   ├── package.json                     ← Next.js 15 dependencies
│   └── .env.production ❌ NÃO COMITAR   ← Secrets Sentry
│
├── 📂 backend-vps-sync/                 ← Backup/Referência
│   └── [Sync direto do VPS 49.13.26.142]
│
├── 📂 frontend-vps-sync/                ← Backup/Referência
│   └── [Sync direto do VPS 138.199.162.115]
│
├── 📄 START_NEW_SESSION_PROMPT.md       ← LEIA ESTE PRIMEIRO! 🔥
│   └── Prompt completo para nova sessão limpa
│
└── 📄 README.md                         ← Este arquivo
```

---

## 🚀 Como Usar (Quick Start)

### 1️⃣ Primeira Vez (Nova Sessão Claude Code)

Copie o conteúdo de `START_NEW_SESSION_PROMPT.md` e cole na nova sessão. Ele contém:
- ✅ Contexto completo do projeto
- ✅ Checklist de tarefas
- ✅ Comandos prontos para executar
- ✅ Warnings de segurança (secrets)
- ✅ Opções de push (force ou PR)

### 2️⃣ Verificar Status Atual

```bash
cd /Users/lucascardoso/Desktop/MUTUA

# Backend
cd backend && git status && cd ..

# Frontend
cd frontend && git status && cd ..
```

### 3️⃣ Executar Sync (Seguir START_NEW_SESSION_PROMPT.md)

Fase 2 do prompt tem comandos completos para:
1. Criar branch de sync
2. Configurar .gitignore (secrets)
3. Commit com mensagens detalhadas
4. Push (direto ou via PR)

---

## ⚠️ Avisos Críticos

### 🔴 NUNCA Comitar Secrets

**Arquivos proibidos**:
```bash
backend/.env              # DB_PASSWORD, STRIPE_SECRET, APP_KEY
frontend/.env.production  # NEXT_PUBLIC_SENTRY_DSN (tem token!)
frontend/.env.local       # API keys locais
```

**Verificação obrigatória**:
```bash
cd backend && git status | grep "\.env"
cd ../frontend && git status | grep "\.env"
# Se aparecer algo além de .env.example, PARE!
```

### 🔴 Force Push Apaga Histórico

Se usar `git push --force`:
- ✅ Substitui repos vazios com código funcional
- ❌ **APAGA** histórico atual (4 commits backend, centenas frontend)
- ⚠️ **IRREVERSÍVEL**

**Recomendação**: Use PR (Opção B do prompt) para Golber revisar primeiro.

---

## 📊 Estatísticas

### Backend (golberdoria/mutuapix-api)
- **Arquivos**: 3 → **447** (após sync)
- **Linhas de código**: ~200 → **~50.000+**
- **Models**: 0 → **60**
- **Services**: 0 → **37**
- **Observers**: 0 → **10**

### Frontend (golberdoria/mutuapix-matrix)
- **Arquivos**: 569 → **752** (após sync)
- **Linhas de código**: ~30.000 → **~80.000+**
- **Components**: ~50 → **~200**
- **Pages**: ~20 → **~80**
- **Hooks**: ~10 → **~50**

---

## 🔗 Documentação Relacionada

### Neste Workspace
- [START_NEW_SESSION_PROMPT.md](START_NEW_SESSION_PROMPT.md) - **COMECE AQUI** 🔥

### Em /Users/lucascardoso/claude/vps/
- `REPOSITORY_COMPARISON_GOLBER_VS_VPS.md` - Análise 447 vs 3 arquivos
- `WORKFLOW_VS_REALITY_GAP_ANALYSIS.md` - Gap analysis completo
- `GIT_INFRASTRUCTURE_AUDIT.md` - Audit Git nos VPS
- `WORKFLOW_VIOLATIONS_AUDIT.md` - Violações workflow
- `MUTUAPIX_WORKFLOW_OFICIAL.md` - Inventário Golber

---

## 🎯 Próximos Passos (Após Sync)

1. ✅ **Push código para golberdoria/** (via PR ou force push)
2. ⚙️ **Reconfigurar VPS** para usar repos oficiais
3. 🔒 **Ativar branch protection** (main + develop)
4. 🤖 **Configurar GitHub Actions** (secrets + workflows)
5. 🧪 **Criar staging** (responsabilidade Golber)
6. ✅ **Testar CI/CD** ponta-a-ponta

---

## 🆘 Troubleshooting

### Q: Git diz que tenho mudanças não commitadas
**A**: Normal! O sync copiou 447 arquivos novos. Siga Fase 2 do prompt para comitar.

### Q: Commitei .env por acidente!
**A**:
```bash
git reset HEAD .env
git checkout .env
echo ".env" >> .gitignore
git add .gitignore
git commit --amend
```

### Q: Force push falhou
**A**: Pode ser branch protection. Desative temporariamente em GitHub Settings → Branches.

### Q: PR muito grande (>300 linhas)
**A**: Normal para sync inicial. Regra de ≤300 linhas é para PRs futuros, não para esta sync massiva.

---

## 📞 Contato

**Dúvidas sobre este workspace?** Consulte `START_NEW_SESSION_PROMPT.md` ou documentos em `/Users/lucascardoso/claude/vps/`.

**Aprovação necessária**: Lucas/Golber devem aprovar antes de push para golberdoria/*.

---

**Workspace preparado por**: Claude Code
**Data**: 2025-10-07
**Status**: ✅ PRONTO PARA SYNC
