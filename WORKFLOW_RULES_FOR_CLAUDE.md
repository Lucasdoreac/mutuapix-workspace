# 🤖 Regras de Workflow para Claude Code

**Data**: 2025-10-07
**Fonte**: MUTUAPIX_WORKFLOW_OFICIAL.md (Linhas 46, 211-217)

---

## 🚨 REGRAS ABSOLUTAS - NUNCA VIOLE

### ❌ PROIBIDO

1. **Force Push**
   ```bash
   git push --force          # ❌ NUNCA
   git push --force-with-lease  # ❌ NUNCA
   git push -f               # ❌ NUNCA
   ```

2. **Commit Direto em Main/Develop**
   ```bash
   git checkout main
   git commit -m "..."       # ❌ NUNCA
   git push origin main      # ❌ NUNCA
   ```

3. **Merge Sem Pull Request**
   ```bash
   git merge feature-branch  # ❌ NUNCA (sem PR)
   ```

4. **Bypass de Review**
   - Não sugerir "merge sem review"
   - Não sugerir "urgente, mergeie direto"
   - Não sugerir "você é admin, pode mergear"

---

## ✅ OBRIGATÓRIO

### 1. SEMPRE Via Pull Request

```bash
# ✅ CORRETO
git checkout -b feature/my-feature
git commit -m "feat: implement feature"
git push origin feature/my-feature
gh pr create --base develop  # OU main, dependendo do caso
```

### 2. SEMPRE Requer Review

- **Mínimo**: 1 review (Golber ou Lucas)
- **Ideal**: Review cruzado entre dupla
- **CI/CD**: Deve passar ANTES de merge

### 3. SEMPRE Diffs Pequenos

- **Ideal**: ≤ 300 linhas
- **Máximo aceitável**: ~500 linhas
- **Se maior**: Quebrar em múltiplos PRs

**Exceção**: Sync inicial de produção (esta sessão) é permitido ser grande porque é migração única.

---

## 📋 Workflow Correto (Passo a Passo)

### Para Features Normais

```bash
# 1. Criar branch
git checkout develop
git pull origin develop
git checkout -b feature/nome-descritivo

# 2. Desenvolver
# ... fazer mudanças ...
git add .
git commit -m "feat: description"

# 3. Push para branch
git push origin feature/nome-descritivo

# 4. Criar PR
gh pr create \
  --title "feat: Title" \
  --body "Description" \
  --base develop  # staging primeiro!

# 5. Aguardar review
# Golber/Lucas aprovam

# 6. CI passa
# lint, typecheck, build, tests

# 7. Merge via GitHub UI
# Após aprovação + CI verde

# 8. Deploy automático via GitHub Actions
# develop → staging (automático)
```

### Para Esta Sessão (Sync Produção)

```bash
# 1. Criar branch de sync
git checkout -b sync/production-to-golber

# 2. Commit código do VPS
git add .
git commit -m "feat: sync production codebase from VPS"

# 3. Push branch
git push origin sync/production-to-golber

# 4. Criar PR para main (não develop, pois já está em produção)
gh pr create --base main --title "Sync production codebase"

# 5. Golber revisa e aprova
# Ele verifica:
# - Secrets não commitados
# - Código bate com produção
# - .gitignore correto

# 6. Merge via GitHub UI
# Após aprovação do Golber

# 7. Reconfigurar VPS (após merge)
# Mudar remote origin nos VPS
```

---

## 🎯 Quando Sugerir O Quê

### ✅ Pode Sugerir

- "Vou criar um PR para esta feature"
- "Precisamos de review do Golber/Lucas"
- "Vou quebrar isto em 3 PRs menores (cada <300 linhas)"
- "CI precisa passar antes do merge"
- "Vou testar em staging primeiro"

### ❌ NUNCA Sugerir

- "Vou fazer force push"
- "Como você é admin, pode mergear direto"
- "Vou commitar direto em main"
- "Staging é opcional, vamos direto pra produção"
- "300 linhas é muito restritivo, vou fazer 2000"

---

## 📊 Checklist de Auto-Verificação

Antes de sugerir QUALQUER operação Git, pergunte:

- [ ] Estou criando um PR? (se não, **PARE**)
- [ ] Mencionei que precisa review? (se não, **ADICIONE**)
- [ ] Estou sugerindo force push? (se sim, **REMOVA**)
- [ ] Estou sugerindo commit direto em main/develop? (se sim, **REMOVA**)
- [ ] Mencionei que CI deve passar? (se não, **ADICIONE**)
- [ ] PR tem ≤ 500 linhas? (se não, **QUEBRE**)

---

## 🔴 Violações Desta Sessão (Aprendizado)

### O Que Foi Feito ERRADO Antes

1. ❌ Sugerimos "Opção A: Force push direto em main"
2. ❌ Sugerimos "SE APROVADO" (implicando que aprovação tornaria force push OK)
3. ❌ Não destacamos workflow como OBRIGATÓRIO no início

### O Que Está CORRETO Agora

1. ✅ Prompt atualizado com regras no topo
2. ✅ Force push removido completamente
3. ✅ APENAS PR como opção válida
4. ✅ Review do Golber destacado como obrigatório
5. ✅ Este arquivo criado para referência futura

---

## 💬 Frases Para Usar

### Quando Usuário Pedir Force Push

> "O workflow oficial proíbe force push (MUTUAPIX_WORKFLOW_OFICIAL.md linha 216: 'Sem commits diretos'). Vou criar um Pull Request para que o Golber possa revisar. Isso garante que seguimos o processo acordado pela equipe."

### Quando Usuário Pedir Commit Direto

> "O workflow exige PR obrigatório com review (linha 211: 'PR obrigatório'). Vou preparar um PR com descrição completa para facilitar a revisão do Golber/Lucas."

### Quando Usuário Disser "Urgente"

> "Entendo a urgência. O workflow permite aprovar PRs rapidamente, mas o processo de review é obrigatório mesmo em urgências. Vou criar o PR agora e notificar o Golber para revisão express."

---

## 🎓 Princípios Do Projeto (Memorizar)

1. **PR obrigatório**: Nada vai direto para main
2. **Review cruzado**: Sempre 1 review antes de merge
3. **CI deve passar**: Lint, typecheck, build, testes
4. **Diffs pequenos**: ≤ 300 linhas por PR
5. **Infra separada**: Setup manual uma vez, depois automatizado
6. **Sem commits diretos**: Nem do Claude Code, nem do Lovable
7. **Staging primeiro**: Validar em develop antes de produção

---

**Referência**: MUTUAPIX_WORKFLOW_OFICIAL.md
**Para Claude Code**: Leia este arquivo ANTES de sugerir qualquer operação Git
**Para Humanos**: Use este arquivo para corrigir Claude se ele violar workflow
