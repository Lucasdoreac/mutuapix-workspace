# Guia de Teste Manual - Login em Produção

**Data:** 2025-10-17
**Ambiente:** https://matrix.mutuapix.com
**Status:** 🟡 Aguardando teste manual

---

## Por que Teste Manual?

HeadlessChrome (usado pelo MCP Chrome DevTools) bloqueia requisições CORS com cookies. Por isso, o teste automatizado falhou, mas **3 bugs críticos já foram corrigidos** no código de produção.

---

## Credenciais de Teste

### Usuário Admin (Confirmado)
- **Email:** `admin@mutuapix.com`
- **Senha:** `password`
- **Verificado:** ✅ Hash da senha validado no banco

### Alternativa (se precisar)
- **Email:** `test@mutuapix.com` (existe, mas senha diferente)
- Para criar novo usuário, veja instruções no final

---

## Passo a Passo do Teste

### 1. Preparação

1. Abra navegador **Chrome ou Firefox** (NÃO modo headless/anônimo)
2. Limpe cookies do domínio `*.mutuapix.com`:
   - Chrome: DevTools (F12) > Application > Cookies > Delete all
   - Firefox: DevTools (F12) > Storage > Cookies > Delete all
3. Abra aba Network no DevTools (vai monitorar requisições)

### 2. Acesso à Página de Login

1. Navegue para: https://matrix.mutuapix.com/login
2. Aguarde página carregar completamente
3. Verifique se aparece formulário de login (não erro de build)

### 3. Tentativa de Login

1. Preencha:
   - **Email:** `admin@mutuapix.com`
   - **Senha:** `password`
2. Marque "Lembrar login" (opcional)
3. Clique em **"Entrar"**

### 4. Observar Network Tab (DevTools)

Após clicar "Entrar", você deve ver **2 requisições**:

#### Requisição 1: CSRF Token
```
GET https://api.mutuapix.com/sanctum/csrf-cookie
Status: 204 No Content ✅
```

**Detalhes esperados:**
- Headers:
  - `Access-Control-Allow-Origin: https://matrix.mutuapix.com`
  - `Access-Control-Allow-Credentials: true`
- Cookies definidos:
  - `XSRF-TOKEN=...` (longo, criptografado)
  - `laravel_session=...` (longo, criptografado)

**Se falhar:**
- Status 404 → Bug no backend (rota não existe)
- Status 500 → Erro no Laravel (checar logs)
- CORS error → Nginx configurado errado
- Pending/Timeout → Firewall ou DNS

#### Requisição 2: Login
```
POST https://api.mutuapix.com/api/v1/login
Status: 200 OK ✅
```

**Payload enviado:**
```json
{
  "email": "admin@mutuapix.com",
  "password": "password"
}
```

**Headers esperados:**
- `X-XSRF-TOKEN: ...` (mesmo valor do cookie decodificado)
- `Cookie: XSRF-TOKEN=...; laravel_session=...`

**Resposta esperada (200 OK):**
```json
{
  "success": true,
  "data": {
    "user": {
      "id": X,
      "name": "Admin",
      "email": "admin@mutuapix.com",
      "role": "admin",
      ...
    },
    "token": "eyJ0eXAiOiJKV1QiLCJhbGc..." // JWT token
  }
}
```

**Se falhar:**
- Status 401 → Credenciais incorretas (senha errada?)
- Status 419 → CSRF token inválido (cookie não enviado)
- Status 422 → Validação falhou (email/password em branco?)
- Status 500 → Erro no Laravel (checar logs)

### 5. Após Login Bem-Sucedido

**Comportamento esperado:**

1. **Redirecionamento:**
   - URL muda para: `https://matrix.mutuapix.com/user/dashboard`
   - Ou para: URL especificada em `?returnUrl=...`

2. **Cookies persistidos:**
   - DevTools > Application > Cookies > `https://api.mutuapix.com`
   - Devem existir:
     - `XSRF-TOKEN` (Domain: `.mutuapix.com`)
     - `laravel_session` (Domain: `.mutuapix.com`, HttpOnly)

3. **Token armazenado:**
   - DevTools > Application > Local Storage > `https://matrix.mutuapix.com`
   - Procurar por chave contendo `auth` ou `token`
   - Valor deve ser JWT: `eyJ0eXAiOiJKV1Qi...`

4. **Dashboard carrega:**
   - Mostra nome do usuário: "Admin"
   - Não redireciona de volta para `/login`
   - Menu de navegação aparece

---

## Troubleshooting

### Erro 401: "Credenciais incorretas"

**Possível causa:** Senha não é "password" para esse usuário

**Solução:** Resetar senha via Tinker

```bash
ssh root@49.13.26.142 'cd /var/www/mutuapix-api && php artisan tinker'
```

```php
$user = User::where('email', 'admin@mutuapix.com')->first();
$user->password = Hash::make('password');
$user->save();
echo "Senha resetada para: password";
exit
```

### Erro 419: "CSRF Token Mismatch"

**Possível causa:** Cookie não sendo enviado ou domínio errado

**Verificação:**
1. DevTools > Network > Login request > Headers
2. Procurar `Cookie:` header
3. Deve conter `XSRF-TOKEN=...`

**Se cookie não aparecer:**
- Checar `SESSION_DOMAIN` no backend (.env)
- Checar se cookies foram bloqueados pelo browser
- Verificar se domínio é `.mutuapix.com` (com ponto)

### Erro "Failed to fetch" ou CORS

**Possível causa:** Nginx CORS mal configurado

**Verificação com curl:**
```bash
curl -I https://api.mutuapix.com/sanctum/csrf-cookie \
  -H "Origin: https://matrix.mutuapix.com"
```

Deve retornar:
```
HTTP/2 204
access-control-allow-origin: https://matrix.mutuapix.com
access-control-allow-credentials: true
```

### Login não redireciona

**Possível causa:** Frontend não salvando token ou erro no redirect

**Verificação:**
1. Console do browser (F12) > Console tab
2. Procurar erros JavaScript
3. Verificar se `localStorage` tem token após login

**Debug:**
```javascript
// Rodar no Console após tentar login
console.log('Auth token:', localStorage.getItem('auth-storage'));
console.log('All storage:', localStorage);
```

---

## Criar Novo Usuário de Teste

Se `admin@mutuapix.com` não funcionar, criar novo:

```bash
ssh root@49.13.26.142 'cd /var/www/mutuapix-api && php artisan tinker'
```

```php
$user = new App\Models\User();
$user->name = "Teste Login Manual";
$user->email = "teste.login@mutuapix.com";
$user->password = Hash::make("SenhaForte123!");
$user->role = "admin"; // ou "user"
$user->is_admin = true; // opcional
$user->email_verified_at = now(); // opcional (pular verificação de email)
$user->save();

echo "✅ Usuário criado!\n";
echo "Email: teste.login@mutuapix.com\n";
echo "Senha: SenhaForte123!\n";
exit
```

Agora teste com:
- **Email:** `teste.login@mutuapix.com`
- **Senha:** `SenhaForte123!`

---

## Resultado Esperado

### ✅ Sucesso (Login funcionou)

**Indica que:**
- 3 bugs corrigidos funcionam em produção
- CORS configurado corretamente
- Sanctum funcionando
- Autenticação 100% operacional

**Próximos passos:**
- Marcar validação como completa
- Atualizar documentação
- Considerar implementar testes E2E com Puppeteer

### ❌ Falha (Login não funcionou)

**Ação:**
1. Anote status code exato da requisição `/api/v1/login`
2. Copie mensagem de erro (se houver)
3. Screenshot da aba Network
4. Copie response body da requisição falhada
5. Envie para investigação adicional

**Informações úteis:**
```bash
# Checar logs do Laravel
ssh root@49.13.26.142 'tail -50 /var/www/mutuapix-api/storage/logs/laravel.log'

# Checar logs do nginx
ssh root@49.13.26.142 'tail -50 /var/log/nginx/error.log'
```

---

## Checklist Final

Após teste, preencha:

- [ ] Página de login carregou sem erros
- [ ] Requisição `/sanctum/csrf-cookie` retornou 204
- [ ] Cookies `XSRF-TOKEN` e `laravel_session` foram definidos
- [ ] Requisição `/api/v1/login` foi enviada com CSRF token
- [ ] Requisição `/api/v1/login` retornou 200 (ou anotei erro)
- [ ] Token JWT foi salvo no localStorage
- [ ] Redirecionamento para dashboard aconteceu
- [ ] Dashboard mostra dados do usuário logado

**Status Final:** [ ] ✅ Sucesso  |  [ ] ❌ Falha (detalhes: ____________)

---

**Relatório Completo:** Ver [AUTHENTICATION_VALIDATION_REPORT.md](AUTHENTICATION_VALIDATION_REPORT.md)
