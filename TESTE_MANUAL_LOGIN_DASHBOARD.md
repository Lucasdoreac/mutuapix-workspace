# Teste Manual - Login e Dashboard

**Data:** 2025-10-20
**Hora:** 11:30 BRT
**Objetivo:** Validar correção do bug de logout automático

---

## 🎯 O Que Testar

### Bug Original
- ✅ Login API funcionava (200 OK)
- ❌ Dashboard não era acessível
- ❌ Logout automático ocorria (5× POST /logout → 401)
- ❌ Usuário redirecionado de volta para /login

### Correção Implementada
- Token agora é salvo em **cookie** (além de localStorage)
- Middleware pode validar token server-side
- Dashboard deve ser acessível sem logout automático

---

## 📋 Checklist de Testes

### Teste 1: Login Básico ✅ CRÍTICO

**Passos:**
1. Abrir navegador **em modo anônimo/privado** (Cmd+Shift+N)
2. Acessar: https://matrix.mutuapix.com/login
3. Preencher:
   - Email: `teste@mutuapix.com`
   - Senha: `teste123`
4. Clicar no botão **"Entrar"**

**Resultado Esperado:**
- ✅ Formulário é submetido
- ✅ **Redirecionamento para `/user/dashboard`**
- ✅ **Dashboard carrega e permanece visível**
- ❌ **NÃO deve redirecionar para `/login`**

**Como Verificar:**
- Olhar a barra de endereços do navegador
- URL deve ser: `https://matrix.mutuapix.com/user/dashboard`
- Página deve mostrar conteúdo do dashboard (não o formulário de login)

---

### Teste 2: Verificar Cookie Criado ✅ CRÍTICO

**Passos (após fazer login no Teste 1):**
1. Abrir **DevTools** (F12 ou Cmd+Option+I)
2. Ir para aba **"Application"** (ou "Aplicativo")
3. No menu lateral, expandir **"Cookies"**
4. Clicar em `https://matrix.mutuapix.com`

**Resultado Esperado:**
- ✅ Cookie chamado **`token`** existe
- ✅ Valor começa com número seguido de pipe: `116|vbf...`
- ✅ Domínio: `matrix.mutuapix.com`
- ✅ Path: `/`
- ✅ Max-Age: `86400` (24 horas)
- ✅ SameSite: `Lax`

**Screenshot Esperado:**
```
Name       | Value              | Domain              | Path | Max-Age
-----------|--------------------|--------------------|------|----------
token      | 116|vbf1fBCsZy... | matrix.mutuapix.com | /    | 86400
```

---

### Teste 3: Verificar localStorage ✅ INFORMATIVO

**Passos (após fazer login):**
1. Com DevTools abertos (F12)
2. Ir para aba **"Application"** → **"Local Storage"**
3. Clicar em `https://matrix.mutuapix.com`
4. Procurar chave **`auth-storage`**

**Resultado Esperado:**
- ✅ Chave `auth-storage` existe
- ✅ Valor é um JSON com `user` e `token`
- ✅ Token é o mesmo do cookie

**Exemplo:**
```json
{
  "state": {
    "user": {
      "id": 32,
      "name": "Usuário Teste MCP",
      "email": "teste@mutuapix.com"
    },
    "token": "116|vbf1fBCsZyCbke1VUTkpif8ceJ..."
  }
}
```

---

### Teste 4: Persistência após Reload ✅ CRÍTICO

**Passos:**
1. Fazer login (Teste 1)
2. Verificar que está no dashboard (`/user/dashboard`)
3. **Recarregar a página** (F5 ou Cmd+R)

**Resultado Esperado:**
- ✅ Página recarrega
- ✅ **Dashboard continua visível**
- ✅ **NÃO redireciona para `/login`**
- ✅ Usuário continua autenticado
- ✅ Cookie `token` ainda existe

**Como Verificar:**
- URL permanece: `https://matrix.mutuapix.com/user/dashboard`
- Conteúdo do dashboard é exibido
- Não há tela de login

---

### Teste 5: Navegação Entre Páginas ✅ IMPORTANTE

**Passos:**
1. Fazer login e acessar dashboard
2. Clicar em links do menu:
   - "Cursos" → `/user/courses`
   - "PIX Help" → `/user/pix-help`
   - "Configurações" → `/user/settings`
   - "Dashboard" → `/user/dashboard`

**Resultado Esperado:**
- ✅ Todas as páginas carregam normalmente
- ✅ **NÃO há logout automático**
- ✅ **NÃO redireciona para `/login`**
- ✅ Cookie persiste em todas as navegações

---

### Teste 6: Logout Manual ✅ CRÍTICO

**Passos:**
1. Fazer login e acessar dashboard
2. Verificar cookie `token` existe (DevTools → Cookies)
3. Clicar no botão **"Sair"** ou **"Logout"**

**Resultado Esperado:**
- ✅ **Redirecionamento para `/login`**
- ✅ Cookie `token` **removido** (não aparece mais em Cookies)
- ✅ localStorage `auth-storage` **limpo** ou com `user: null`
- ✅ Ao tentar acessar `/user/dashboard` → redireciona para `/login`

**Como Verificar:**
1. Após logout, abrir DevTools → Application → Cookies
2. Cookie `token` NÃO deve existir
3. Tentar acessar manualmente: `https://matrix.mutuapix.com/user/dashboard`
4. Deve redirecionar para `/login` (porque não está autenticado)

---

### Teste 7: Login com Credenciais Inválidas ✅ IMPORTANTE

**Passos:**
1. Abrir `/login` (modo anônimo)
2. Preencher:
   - Email: `teste@mutuapix.com`
   - Senha: `senhaerrada123`
3. Clicar "Entrar"

**Resultado Esperado:**
- ❌ Login **NÃO** deve ter sucesso
- ✅ Mensagem de erro exibida: "Credenciais inválidas" ou similar
- ✅ Permanece na página `/login`
- ✅ Cookie `token` **NÃO** foi criado

---

### Teste 8: Acesso Direto a Rota Protegida (Sem Login) ✅ IMPORTANTE

**Passos:**
1. Abrir navegador **em modo anônimo** (nova janela)
2. Acessar diretamente: `https://matrix.mutuapix.com/user/dashboard`
3. **NÃO fazer login**

**Resultado Esperado:**
- ✅ **Redirecionamento automático para `/login`**
- ✅ URL deve mudar para: `https://matrix.mutuapix.com/login?redirect=/user/dashboard`
- ✅ Formulário de login é exibido
- ✅ Cookie `token` não existe

**Motivo:** Middleware protege rotas `/user/*` e `/admin/*`

---

## 🐛 Problemas a Reportar

### Se o Bug AINDA Ocorrer

**Sintomas:**
- ❌ Dashboard carrega por 1-2 segundos e depois redireciona para `/login`
- ❌ Múltiplas requisições `POST /logout` aparecem no Network tab
- ❌ Cookie `token` é criado mas depois desaparece

**Como Capturar Evidências:**
1. Abrir DevTools → **Network** tab (antes de fazer login)
2. Marcar checkbox **"Preserve log"**
3. Fazer login
4. Capturar screenshot do Network tab mostrando:
   - POST `/api/v1/login` → 200 OK
   - GET `/user/dashboard` → 200 OK (ou 302 redirect)
   - POST `/api/v1/logout` (se aparecer múltiplas vezes)

5. Abrir DevTools → **Console** tab
6. Capturar screenshot de erros em vermelho

7. Enviar screenshots para análise

---

## ✅ Sucesso: Como Saber Que Funcionou

### Indicadores de Sucesso

**✅ Login Funcional:**
- Usuário consegue fazer login
- Dashboard carrega
- **Dashboard PERMANECE visível** (não redireciona)
- URL permanece: `/user/dashboard`

**✅ Cookie Criado:**
- Cookie `token` existe
- Valor começa com número: `116|...`
- Max-Age: 86400 (24 horas)

**✅ Persistência:**
- Reload (F5) mantém usuário autenticado
- Navegação entre páginas funciona
- Cookie persiste

**✅ Logout:**
- Botão logout funciona
- Cookie é removido
- Redirect para `/login`

**✅ Middleware:**
- Acesso direto a `/user/*` sem login → redirect para `/login`
- Acesso após login → página carrega normalmente

---

## 📊 Resultados Esperados vs Reais

### Template de Reporte

Copie e preencha após os testes:

```
TESTE MANUAL - RESULTADOS

Data: 2025-10-20
Hora: ___:___ BRT
Navegador: [Chrome / Firefox / Safari]

Teste 1 - Login Básico:
[ ] ✅ Passou  [ ] ❌ Falhou
Observações: _______________________________

Teste 2 - Cookie Criado:
[ ] ✅ Passou  [ ] ❌ Falhou
Valor do cookie: _______________________________

Teste 3 - localStorage:
[ ] ✅ Passou  [ ] ❌ Falhou
Token presente: [ ] Sim  [ ] Não

Teste 4 - Reload:
[ ] ✅ Passou  [ ] ❌ Falhou
Dashboard permaneceu visível: [ ] Sim  [ ] Não

Teste 5 - Navegação:
[ ] ✅ Passou  [ ] ❌ Falhou
Páginas acessadas sem erro: _______________________________

Teste 6 - Logout:
[ ] ✅ Passou  [ ] ❌ Falhou
Cookie removido: [ ] Sim  [ ] Não

Teste 7 - Credenciais Inválidas:
[ ] ✅ Passou  [ ] ❌ Falhou
Mensagem de erro: _______________________________

Teste 8 - Acesso Direto (Sem Login):
[ ] ✅ Passou  [ ] ❌ Falhou
Redirecionou para /login: [ ] Sim  [ ] Não

RESUMO:
Total de testes: 8
Testes aprovados: ___
Testes falhados: ___
Taxa de sucesso: ___%

STATUS FINAL: [ ] ✅ MVP 100% FUNCIONAL  [ ] ❌ REQUER CORREÇÕES
```

---

## 🚀 Próximos Passos Após Validação

### Se Todos os Testes Passarem (100%)

1. ✅ Marcar MVP como **100% FUNCIONAL**
2. ✅ Criar relatório final de implementação
3. ✅ Atualizar documentação de autenticação
4. ✅ Notificar stakeholders
5. ✅ Fechar issues relacionadas

### Se Algum Teste Falhar

1. 🔍 Capturar evidências (screenshots, logs)
2. 🐛 Analisar root cause do novo problema
3. 🔧 Implementar correção adicional
4. 🔄 Re-testar
5. 📝 Documentar descobertas

---

## 📞 Suporte

**Se precisar de ajuda:**
- Capturar screenshots dos problemas
- Copiar mensagens de erro do Console
- Verificar Network tab para requisições falhadas
- Enviar evidências para análise

---

## 🎉 Expectativa de Resultado

**Confiança:** 95% de sucesso

**Motivos:**
- ✅ Root cause identificado corretamente
- ✅ Solução implementada (dual storage)
- ✅ Deploy executado sem erros
- ✅ API continua funcionando (teste curl passou)
- ✅ Código testado localmente (mesma lógica)

**Risco:** 5% de haver outro problema não detectado

**Se funcionar:** MVP estará 100% operacional! 🚀

---

*Guia criado por: Claude Code*
*Data: 2025-10-20*
*Hora: 11:30 BRT*
*Versão: 1.0 - Teste de Correção de Logout Automático*
