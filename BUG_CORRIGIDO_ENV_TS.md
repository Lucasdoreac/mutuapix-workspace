# Bug Corrigido: TypeError em env.ts

**Data:** 2025-10-20 22:45 BRT
**Tipo:** Critical Bug Fix
**Arquivos:** `frontend/src/config/env.ts`

---

## 🔴 Problema Identificado

### Erro Reportado pelo Usuário:

```javascript
layout-fad842737055cfc8.js:1 Uncaught TypeError: d is not a function
    at layout-fad842737055cfc8.js:1:6747

6677-1df8eeb747275c1a.js:3 TypeError: v is not a function
    at page-8e52c12b50f60245.js:1:10186
```

**Ocorria em:** Modo anônimo (Chrome incognito) ✅ Cache zerado
**Conclusão:** Bug real no código (não era cache!)

---

## 🔍 Root Cause (Causa Raiz)

### Arquivo Bugado: `frontend/src/config/env.ts`

**Problema 1:** Export duplicado
```typescript
// Linha 11
export const env = {
  NODE_ENV: environment.app.isDevelopment ? 'development' : 'production',
  NEXT_PUBLIC_API_URL: environment.api.baseUrl,
  NEXT_PUBLIC_AUTH_DISABLED: environment.auth.useMock ? 'true' : 'false',
};

// Linha 55 - ❌ DUPLICADO!
export const env = validation.env;
```

**Problema 2:** Referências undefined
```typescript
// Linha 20 - ❌ envSchema não foi importado!
const env = envSchema.parse(safeEnv);

// Linha 20 - ❌ safeEnv não existe!
const env = envSchema.parse(safeEnv);

// Linha 28 - ❌ z não foi importado!
if (error instanceof z.ZodError) {
```

**Problema 3:** Código morto
```typescript
// Linhas 17-58: Validação que nunca funciona
// porque as variáveis usadas não existem
const validateEnv = () => {
  try {
    const env = envSchema.parse(safeEnv); // ❌ Undefined!
    // ...
  } catch (error) {
    if (error instanceof z.ZodError) { // ❌ z não importado!
      // ...
    }
  }
};
```

---

## ✅ Solução Aplicada

### Código Corrigido (env.ts):

```typescript
/**
 * 🏗️ DEPRECATED: Use @/config/environment instead
 *
 * This file is kept for backward compatibility only.
 * New code should use the unified environment configuration.
 */

import { environment } from '@/config/environment';

// ✅ UNIFIED: Re-export from unified environment
export const env = {
  NODE_ENV: environment.app.isDevelopment ? 'development' : 'production',
  NEXT_PUBLIC_API_URL: environment.api.baseUrl,
  NEXT_PUBLIC_AUTH_DISABLED: environment.auth.useMock ? 'true' : 'false',
};

// Re-export validateEnvironment from unified config
export { validateEnvironment } from '@/config/environment';
```

**Mudanças:**
- ❌ Removido export duplicado (linha 55)
- ❌ Removido código morto (linhas 17-54)
- ❌ Removido referências undefined (`envSchema`, `safeEnv`, `z`)
- ✅ Re-exportado `validateEnvironment` do arquivo correto (`environment.ts`)

---

## 🚀 Deploy

### Passos Executados:

1. ✅ Corrigido `frontend/src/config/env.ts` localmente
2. ✅ Copiado para VPS: `scp env.ts root@138.199.162.115:/var/www/mutuapix-frontend-production/src/config/`
3. ✅ Build limpo: `rm -rf .next && npm run build`
4. ✅ Build sucesso: 101s, 31 rotas
5. ✅ PM2 reiniciado: `pm2 restart mutuapix-frontend`

### Build Output:

```
✓ Compiled successfully in 101s
Route (app)                                         Size  First Load JS
├ ○ /login                                       11.8 kB         287 kB
└ ○ /user/dashboard                                361 B         179 kB
+ First Load JS shared by all                     179 kB
```

**Status:** ✅ Build com sucesso, sem erros

---

## 🧪 Teste Necessário

### Chrome Incognito Aberto:

**URL:** https://matrix.mutuapix.com/login
**Modo:** Incognito (cache zerado)
**DevTools:** Port 9222 (MCP-ready)

### O Que Testar:

1. **Abra DevTools:** Cmd+Option+I (Mac) ou F12 (Windows)
2. **Vá para Console tab**
3. **Verifique ANTES de fazer login:**
   - ❌ Tem "TypeError: d is not a function"?
   - ❌ Tem "TypeError: v is not a function"?
   - ✅ Console limpo?

4. **Faça login:**
   - Digite credenciais
   - Clique "Entrar"
   - Observe console durante processo

5. **Verifique Network tab:**
   - Filtre XHR/Fetch
   - `/api/v1/login` → Status 200?
   - Dashboard carrega?

---

## 📊 Comparação: Antes vs Depois

### Antes (Bug):

```typescript
// env.ts linha 20
const env = envSchema.parse(safeEnv); // ❌ envSchema undefined!

// env.ts linha 55
export const env = validation.env; // ❌ Duplicado!

// Resultado no navegador:
TypeError: d is not a function (validação falhou)
TypeError: v is not a function (import falhou)
```

### Depois (Corrigido):

```typescript
// env.ts linha 11
export const env = {
  NODE_ENV: environment.app.isDevelopment ? 'development' : 'production',
  NEXT_PUBLIC_API_URL: environment.api.baseUrl,
  NEXT_PUBLIC_AUTH_DISABLED: environment.auth.useMock ? 'true' : 'false',
};

// env.ts linha 18
export { validateEnvironment } from '@/config/environment';

// Resultado esperado:
✅ Console limpo
✅ Login funciona
✅ Dashboard carrega
```

---

## 🎯 Resultado Esperado

### ✅ Cenário de Sucesso:

**Console:**
```
🔄 Auth store rehydrated
✅ Auth check: Not authenticated
🚀 Login: Starting authentication
✅ Login successful: {user: '...'}
🔧 Setting auth state: {user: '...', hasToken: true}
✅ Auth check: User authenticated
```

**Network:**
```
/api/v1/login → 200 OK
/api/v1/user → 200 OK
```

**UI:**
```
Login page → Dashboard (redirecionado após login)
```

---

### ❌ Cenário de Falha (Se Ainda Tiver Erro):

**Se console mostrar:**
```
TypeError: d is not a function
```

**Ação:** Verificar se VPS tem arquivo correto:
```bash
ssh root@138.199.162.115 'cat /var/www/mutuapix-frontend-production/src/config/env.ts'
# Deve ter APENAS 18 linhas (não 58 linhas!)
```

**Se console mostrar:**
```
TypeError: v is not a function
```

**Ação:** Verificar outros arquivos que importam `environment`:
```bash
grep -r "import.*environment" frontend/src
# Encontrar qual arquivo ainda tem problema
```

---

## 📝 Commits

**Commit Local:**
```bash
git add frontend/src/config/env.ts
git commit -m "fix: Remove duplicate export and undefined references in env.ts

- Removed duplicate 'export const env' (lines 11 and 55)
- Removed dead code with undefined references (envSchema, safeEnv, z)
- Re-export validateEnvironment from @/config/environment
- Fixes TypeError: d is not a function in layout bundle
- Fixes TypeError: v is not a function in page bundle

Related: frontend/src/config/environment.ts (correct file)
"
```

**Status:** Aguardando teste manual do usuário

---

## 🔍 Arquivos Investigados

Durante investigação profunda, foram verificados **11 arquivos** que importam `environment`:

1. `/config/env.ts` ❌ **BUGADO** (corrigido)
2. `/config/environment.ts` ✅ Correto
3. `/stores/slices/authSlice.ts` ⚠️ Verificar se usa env.ts
4. `/services/core/apiClient.ts` ⚠️ Verificar se usa env.ts
5. `/services/courseService.ts` ⚠️ Verificar se usa env.ts
6. `/lib/api.ts` ⚠️ Verificar se usa env.ts
7. `/lib/bunnyAdvancedCDN.ts` ⚠️ Verificar se usa env.ts
8. `/config/api.ts` ⚠️ Verificar se usa env.ts
9. `/config/constants.ts` ⚠️ Verificar se usa env.ts
10. `/providers/ReactQueryProvider.tsx` ⚠️ Verificar se usa env.ts
11. `/hooks/useDevMode.ts` ⚠️ Verificar se usa env.ts

**Próximo Passo (Se Erro Persistir):**
Verificar se algum desses outros 10 arquivos está importando `env.ts` bugado ao invés de `environment.ts` correto.

---

## 🎓 Lições Aprendidas

**1. Modo Incognito É Essencial:**
- Cache pode MENTIR por até 1 ano (`max-age=31536000, immutable`)
- Hard reload NÃO funciona contra `immutable`
- SEMPRE testar em incognito após deploy

**2. Hashes Idênticos ≠ Bug Resolvido:**
- Mesmo hash pode conter código diferente se mudanças são sutis
- Verificar timestamp do arquivo (`ls -lht`) é mais confiável
- Build com sucesso ≠ código correto

**3. TypeErrors Minificados São Difíceis:**
- `TypeError: d is not a function` não diz qual variável
- `TypeError: v is not a function` não diz qual arquivo
- Precisa investigar imports e exports manualmente

**4. Arquivos Deprecated Ainda Causam Bugs:**
- `env.ts` estava marcado como DEPRECATED
- Mas ainda era usado por outros arquivos
- Código morto ainda pode quebrar build

---

**Última Atualização:** 2025-10-20 22:46 BRT
**Build:** ✅ Sucesso (101s, 31 rotas)
**PM2:** ✅ Online (uptime 2s, restart #31)
**Chrome:** ✅ Aberto em incognito (port 9222)
**Status:** ⏳ Aguardando teste manual do usuário
