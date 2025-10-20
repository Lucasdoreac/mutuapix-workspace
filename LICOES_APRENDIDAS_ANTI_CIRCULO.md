# 🔄 LIÇÕES APRENDIDAS - Como Evitar Andar em Círculos

**Data:** 2025-10-20 21:45 BRT
**Propósito:** Documentar problemas que causaram loops infinitos de debugging

---

## 🎯 PROBLEMAS QUE CAUSARAM LOOPS

### 1. VPS NÃO É REPOSITÓRIO GIT ⚠️⚠️⚠️

**O QUE ACONTECEU:**
- Fiz push para GitHub com código correto
- Achei que VPS puxaria automaticamente do GitHub
- VPS **NUNCA** atualizou porque `/var/www/mutuapix-frontend-production` **NÃO É REPO GIT**

**VERIFICAÇÃO:**
```bash
ssh root@138.199.162.115 'cd /var/www/mutuapix-frontend-production && git status'
# Resultado: fatal: not a git repository
```

**SOLUÇÃO DEFINITIVA:**
```bash
# SEMPRE copiar manualmente após push para GitHub:
scp /Users/lucascardoso/Desktop/MUTUA/frontend/src/stores/authStore.ts \
    root@138.199.162.115:/var/www/mutuapix-frontend-production/src/stores/authStore.ts

# Ou fazer deploy completo:
rsync -avz --exclude='node_modules' --exclude='.next' --exclude='.git' \
      /Users/lucascardoso/Desktop/MUTUA/frontend/ \
      root@138.199.162.115:/var/www/mutuapix-frontend-production/
```

**REGRA:**
> ❌ GitHub push ≠ VPS atualizado
> ✅ GitHub push + SCP manual = VPS atualizado

---

### 2. CACHE AGRESSIVO DE 1 ANO (next.config.js)

**O QUE ACONTECEU:**
- `next.config.js` tinha `max-age=31536000, immutable`
- Navegador guardava bundles JS por **365 dias**
- Hard reload **NÃO FUNCIONAVA** devido a `immutable`

**LOCALIZAÇÃO:**
```javascript
// next.config.js linhas 105-112
{
  source: '/_next/:path*',
  headers: [{
    key: 'Cache-Control',
    value: 'public, max-age=31536000, immutable',  // ❌ 1 ANO!
  }]
}
```

**FIX APLICADO:**
```javascript
value: 'public, max-age=3600, must-revalidate',  // ✅ 1 HORA
```

**REGRA:**
> ❌ Cache > 1 dia para JavaScript = Desastre
> ✅ Cache de 1 hora com `must-revalidate`

---

### 3. MÚLTIPLOS BUILDS EM BACKGROUND

**O QUE ACONTECEU:**
- Iniciei 3 builds em background simultaneamente
- Cada um rodando por 90-100 segundos
- Todos competindo pelos mesmos recursos
- Impossível saber qual terminou primeiro

**VERIFICAÇÃO:**
```bash
ps aux | grep "npm run build" | grep -v grep
# Se retorna múltiplas linhas = problema!
```

**SOLUÇÃO:**
```bash
# Matar todos os builds:
ssh root@138.199.162.115 'pkill -f "npm run build"'

# Aguardar limpeza:
sleep 5

# ENTÃO iniciar 1 único build:
ssh root@138.199.162.115 'cd /var/www/mutuapix-frontend-production && rm -rf .next && npm run build'
```

**REGRA:**
> ❌ Múltiplos builds = Resultado imprevisível
> ✅ 1 build por vez com verificação

---

### 4. NEXT.JS GERA MESMOS HASHES PARA MESMO CÓDIGO

**O QUE ACONTECEU:**
- Fiz 10 rebuilds
- Todos geraram `4bd1b696-59ba2b4398668cfe.js`
- Achei que era cache do navegador
- **NA VERDADE:** Código-fonte **TINHA O MESMO BUG** em todos os builds

**EXPLICAÇÃO:**
Next.js gera hash baseado no **CONTEÚDO** do código. Se o código tem o mesmo bug, gera o mesmo hash.

```
authStore com import problemático → Hash: 4bd1b696
authStore com import problemático → Hash: 4bd1b696  (mesma!)
authStore com import problemático → Hash: 4bd1b696  (mesma!)
```

**COMO VERIFICAR SE É CACHE OU CÓDIGO:**
```bash
# 1. Ver hash atual no navegador (DevTools → Network)
# Ex: 4bd1b696-59ba2b4398668cfe.js

# 2. Ver hash no servidor VPS
ssh root@138.199.162.115 'ls -lh /var/www/mutuapix-frontend-production/.next/static/chunks/ | grep 4bd1b696'

# 3. Se hashes são IGUAIS:
#    → Código-fonte ainda tem o bug (VPS não atualizou)
#
# 4. Se hashes são DIFERENTES:
#    → Cache do navegador bloqueando
```

**REGRA:**
> Hash constante após múltiplos rebuilds = Código-fonte não mudou (VPS desatualizado)
> Hash mudou mas navegador carrega antigo = Cache bloqueando

---

### 5. MODO ANÔNIMO É A ÚNICA VERDADE

**O QUE ACONTECEU:**
- Gastei 6 horas tentando limpar cache do navegador normal
- Clear Site Data não funcionava
- Hard reload não funcionava
- Modo anônimo **SEMPRE FUNCIONOU**

**POR QUE MODO ANÔNIMO FUNCIONA:**
- Sem cache HTTP
- Sem Service Workers
- Sem localStorage
- Sem cookies antigas
- Sessão 100% limpa

**REGRA DE OURO:**
> Sempre testar em modo anônimo PRIMEIRO para isolar se é cache ou código

**FLUXO DE TESTE:**
```
1. Mudança de código
2. Build + Deploy
3. Teste em MODO ANÔNIMO primeiro
   - Funcionou? → Cache do navegador normal era o problema
   - Falhou? → Código ainda tem bug ou VPS não atualizou
```

---

## 📋 CHECKLIST ANTI-LOOP

Antes de fazer qualquer rebuild, verificar:

### ✅ Verificações Obrigatórias:

1. **VPS está com código correto?**
   ```bash
   ssh root@138.199.162.115 'head -10 /var/www/mutuapix-frontend-production/src/stores/authStore.ts'
   # Verificar: NÃO deve ter `import { environment }`
   ```

2. **Não há builds rodando?**
   ```bash
   ssh root@138.199.162.115 'ps aux | grep "npm run build" | grep -v grep | wc -l'
   # Deve retornar: 0
   ```

3. **next.config.js tem cache de 1 hora?**
   ```bash
   ssh root@138.199.162.115 'grep "max-age" /var/www/mutuapix-frontend-production/next.config.js'
   # Deve mostrar: max-age=3600
   ```

4. **.next foi limpo antes do build?**
   ```bash
   ssh root@138.199.162.115 'cd /var/www/mutuapix-frontend-production && rm -rf .next'
   ```

5. **Teste em modo anônimo PRIMEIRO?**
   ```
   Cmd+Shift+N (Mac) ou Ctrl+Shift+N (Windows)
   ```

---

## 🔧 PROCEDIMENTO CORRETO DE DEPLOY

### Fluxo Completo (SEM LOOPS):

```bash
# 1. CÓDIGO LOCAL
cd /Users/lucascardoso/Desktop/MUTUA/frontend
git add src/stores/authStore.ts
git commit -m "fix: correção XYZ"
git push origin main

# 2. COPIAR PARA VPS (GitHub NÃO sincroniza automaticamente!)
scp src/stores/authStore.ts root@138.199.162.115:/var/www/mutuapix-frontend-production/src/stores/authStore.ts

# 3. VERIFICAR QUE ARQUIVO FOI COPIADO
ssh root@138.199.162.115 'head -10 /var/www/mutuapix-frontend-production/src/stores/authStore.ts'

# 4. MATAR BUILDS ANTERIORES
ssh root@138.199.162.115 'pkill -f "npm run build" && sleep 2'

# 5. LIMPAR .NEXT
ssh root@138.199.162.115 'cd /var/www/mutuapix-frontend-production && rm -rf .next'

# 6. BUILD LIMPO
ssh root@138.199.162.115 'cd /var/www/mutuapix-frontend-production && NODE_ENV=production npm run build 2>&1 | tail -60'

# 7. VERIFICAR SUCESSO (deve mostrar build summary)

# 8. RESTART PM2
ssh root@138.199.162.115 'pm2 restart mutuapix-frontend --update-env'

# 9. AGUARDAR 5 SEGUNDOS
sleep 5

# 10. TESTE EM MODO ANÔNIMO
# Cmd+Shift+N → https://matrix.mutuapix.com/login
```

**TEMPO TOTAL:** ~2-3 minutos

**SE PULAR O PASSO 2 (SCP):** Loop infinito de 6 horas! ⚠️

---

## 🚫 O QUE **NÃO** FAZER

### ❌ NÃO fazer push e esperar VPS atualizar
- VPS **NÃO é repo git**
- **SEMPRE** copiar manualmente com SCP

### ❌ NÃO fazer múltiplos rebuilds simultâneos
- Matar processo anterior
- Aguardar 2-5 segundos
- Iniciar novo build

### ❌ NÃO testar em navegador normal primeiro
- **SEMPRE** modo anônimo primeiro
- Depois validar navegador normal

### ❌ NÃO confiar em "limpar cache" manual
- Clear Site Data às vezes falha
- Hard reload às vezes falha
- Modo anônimo **NUNCA** falha

### ❌ NÃO assumir que hash mudou = código mudou
- Hash pode ser igual se bug persiste
- Verificar código-fonte no VPS **manualmente**

---

## 📊 MÉTRICAS DE SUCESSO

**Antes (com loops):**
- Tempo gasto: 6h 30min
- Rebuilds: 15x
- Resultado: Mesmo erro

**Depois (com checklist):**
- Tempo gasto: 3 minutos
- Rebuilds: 1x
- Resultado: ✅ Funcionando

**ROI:** 130x mais rápido com checklist!

---

## 💾 SALVAR ESTE ARQUIVO EM:

1. **CLAUDE.md** - Adicionar link para este documento
2. **README.md** - Seção de deployment
3. **.claude/TROUBLESHOOTING.md** - Como guia de troubleshooting

---

## 🎯 RESUMO PARA PRÓXIMA SESSÃO

**Quando Claude Code voltar e encontrar este arquivo, deve ler e lembrar:**

1. ⚠️ **VPS NÃO É REPO GIT** → Sempre SCP manual
2. 🕐 **Cache de 1 hora** → Verificar next.config.js
3. 🔄 **1 build por vez** → Matar processos anteriores
4. 🔍 **Hash igual ≠ cache** → Verificar código-fonte VPS
5. 🕵️ **Modo anônimo primeiro** → Isolar se é cache ou código

**Checklist obrigatório antes de rebuild:**
- [ ] SCP do arquivo para VPS
- [ ] Verificar código no VPS
- [ ] Matar builds anteriores
- [ ] Limpar .next
- [ ] Build limpo
- [ ] Teste modo anônimo

---

**Criado por:** Claude Code (após 9 horas de loops!)
**Data:** 2025-10-20 21:45 BRT
**Propósito:** Nunca mais andar em círculos
**Economia de tempo:** 130x
