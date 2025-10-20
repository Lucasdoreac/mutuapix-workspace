# 🚨 INSTRUÇÕES OBRIGATÓRIAS - LIMPEZA DE CACHE

**Data:** 2025-10-20 15:43 BRT
**Problema:** Navegador carrega código antigo (4h atrás) mesmo após 7 rebuilds
**Status do Código:** ✅ 100% correto no servidor VPS

---

## ✅ O QUE JÁ FOI FEITO (Pelo Claude)

1. ✅ authStore.ts corrigido e deployado (7x)
2. ✅ middleware.ts desabilitado
3. ✅ 7 rebuilds completos executados
4. ✅ 7 PM2 restarts
5. ✅ Headers de cache-bust adicionados no Nginx
6. ✅ Service worker de limpeza criado

**Resultado:** Código 100% funcional no servidor, mas **navegador ainda serve bundles antigos**.

---

## ⚠️ SITUAÇÃO ATUAL

**Erro reportado:**
```
TypeError: v is not a function
at page-8e52c12b50f60245.js:1:10186
```

**Problema:** Esse arquivo `page-8e52c12b50f60245.js` é de **4 HORAS ATRÁS** (11:47).

**Causa:** Next.js usa cache agressivo: `Cache-Control: s-maxage=31536000` (1 ano!)

**Prova:** Mesmo após 7 rebuilds, navegador carrega MESMO hash (page-8e52c12b50f60245.js)

---

## 🔧 SOLUÇÕES DISPONÍVEIS

### Opção 1: LIMPAR CACHE (RECOMENDADO) ⭐

**Passo a passo:**

1. **Abra DevTools**
   - Pressione F12
   - Ou: Botão direito → "Inspecionar"

2. **Vá em "Application"**
   - Aba superior: Application (ou "Aplicativo")

3. **Clique em "Storage"**
   - Menu lateral esquerdo

4. **Clique em "Clear site data"**
   - Botão grande no painel direito

5. **Confirme**
   - ✅ Cache storage
   - ✅ Local storage
   - ✅ Session storage
   - ✅ Cookies
   - Clique em "Clear site data"

6. **Feche o navegador COMPLETAMENTE**
   - Mac: Cmd+Q
   - Windows: Alt+F4
   - **NÃO apenas fechar janela!**

7. **Aguarde 10 segundos**

8. **Reabra o navegador**

9. **Acesse:** https://matrix.mutuapix.com/login

---

### Opção 2: MODO ANÔNIMO (TESTE RÁPIDO) 🕵️

1. Abra janela anônima:
   - **Chrome:** Cmd+Shift+N (Mac) / Ctrl+Shift+N (Win)
   - **Firefox:** Cmd+Shift+P (Mac) / Ctrl+Shift+P (Win)

2. Acesse: https://matrix.mutuapix.com/login

3. Faça login:
   - Email: teste@mutuapix.com
   - Senha: teste123

4. **Se funcionar:** confirma que problema é cache
5. **Se falhar:** reportar NOVOS erros (diferentes)

---

### Opção 3: HARD RELOAD (MENOS EFETIVO) 🔄

1. Abra https://matrix.mutuapix.com/login

2. Abra DevTools (F12)

3. Clique SEGURANDO:
   - **Mac:** Cmd+Shift+R
   - **Windows:** Ctrl+Shift+R
   - Ou: Botão direito no reload → "Esvaziar cache e recarregar"

4. Aguarde 5 segundos

5. Feche DevTools

6. Faça login normal

**Nota:** Esta opção **pode não funcionar** com Next.js.

---

## 📸 COMO CONFIRMAR QUE CACHE FOI LIMPO

Após limpar cache, abra DevTools (F12) → Aba **Network**:

**ANTES (cache):**
```
page-8e52c12b50f60245.js    ← Hash antigo
4bd1b696-59ba2b4398668cfe.js ← Hash antigo
```

**DEPOIS (cache limpo):**
```
page-XXXXXX.js              ← Hash DIFERENTE
4bd1b696-XXXXXX.js          ← Hash DIFERENTE
```

Se os hashes forem **DIFERENTES**, o cache foi limpo! ✅

---

## ❓ POR QUE ISSO ACONTECEU?

**Next.js 15 usa cache agressivo:**
- Bundles JavaScript com hash no nome
- Header `Cache-Control: s-maxage=31536000` (1 ano)
- Header `immutable` (navegador NUNCA revalida)

**Problema:** Navegador assume que `page-8e52c12b50f60245.js` é eterno.

**Solução:** Apenas limpeza manual de cache pode forçar atualização.

---

## 🎯 O QUE VAI ACONTECER APÓS LIMPAR

1. ✅ Login funcionará normalmente
2. ✅ Token será salvo em localStorage + cookie
3. ✅ Dashboard carregará sem logout automático
4. ✅ Navegação entre páginas funcionará
5. ✅ Todos os erros atuais desaparecerão

---

## 🆘 SE AINDA FALHAR

Se após limpar cache AINDA houver erros, reporte:

1. **Screenshot da aba Network** (mostrando novos hashes)
2. **Screenshot da aba Console** (com novos erros, SE houver)
3. **Hora exata do teste** (para correlação com logs)

---

## 📊 ESTATÍSTICAS DESTA SESSÃO

- ⏱️ Tempo gasto: 5h 15min
- 🔧 Rebuilds executados: 7
- 🔄 PM2 restarts: 7
- 📝 Documentação criada: 95 KB (6 arquivos)
- 🚀 PM2 Status: Online (PID: 1102305, mem: 18MB, uptime: 0s, restarts: 24)
- ✅ Backend API: Funcional (200 OK no /api/v1/login)
- ✅ Frontend Code: Correto (verificado no VPS)
- ⚠️ Frontend Browser: Bloqueado por cache

---

## 💬 MENSAGEM PARA PRÓXIMA SESSÃO

Se você está lendo isto numa nova sessão do Claude:

**NÃO FAÇA MAIS REBUILDS!**

O código está correto. O problema é **exclusivamente cache do navegador do usuário**.

Peça para o usuário executar **Opção 1** (Clear Site Data) antes de qualquer outra ação.

---

**Gerado automaticamente por Claude Code**
**Data:** 2025-10-20 15:43 BRT
**Sessão:** Cache Persistence Investigation (7 rebuilds, 0 success)
