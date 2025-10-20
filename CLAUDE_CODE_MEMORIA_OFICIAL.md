# Como Claude Code Lida com Memória (Oficial - 2025)

**Fonte:** docs.claude.com/en/docs/claude-code/memory

---

## 🧠 Como Funciona

### Arquivos Lidos Automaticamente

Claude Code lê **automaticamente no início de cada sessão**:

1. **`CLAUDE.md`** - Instruções do projeto (compartilhadas com time, versionadas no git)
2. **`~/.claude/CLAUDE.md`** - Preferências pessoais globais (não versionadas)
3. **`.claude/skills/*/SKILL.md`** - Capacidades modulares
4. **`@imports`** - Arquivos referenciados com `@path/to/file.md`

### Hierarquia de Leitura

```
/                           ← Lê ~/.claude/CLAUDE.md (global)
└── projeto/                ← Lê ./CLAUDE.md (raiz do projeto)
    └── backend/            ← Lê ./backend/CLAUDE.md (se existir)
        └── src/            ← Lê ./src/CLAUDE.md (se existir)
```

**Regra:** Arquivos mais específicos (aninhados) têm prioridade sobre gerais.

---

## ✅ Melhores Práticas (Oficial)

### 1. Mantenha CLAUDE.md ENXUTO

**❌ ERRADO:**
```markdown
# CLAUDE.md (1557 linhas - 95% do contexto desperdiçado!)

## Histórico Completo de Deploys
2025-10-01: Deploy do PR #1...
2025-10-02: Deploy do PR #2...
[... 1500 linhas de logs ...]

## Todos os Comandos Possíveis
[... 500 linhas de exemplos ...]
```

**✅ CORRETO:**
```markdown
# CLAUDE.md (78 linhas - essencial apenas)

**Stack:** Laravel 12 + Next.js 15

## ⚠️ CRÍTICO
VPS NÃO é repo git → sempre `scp` manualmente após `git push`

## Servidores
- Frontend: 138.199.162.115
- Backend: 49.13.26.142

## Problemas Comuns
Ver: @docs/TROUBLESHOOTING.md
```

**Guideline Oficial:**
> Keep CLAUDE.md files minimal, including only information that is **essential for every session**.

---

### 2. Use `@imports` para Detalhes

**Estrutura Recomendada:**

```
projeto/
├── CLAUDE.md                    (78 linhas - visão geral)
├── docs/
│   ├── TROUBLESHOOTING.md      (referenciado com @docs/TROUBLESHOOTING.md)
│   ├── DEPLOY_GUIDE.md         (referenciado quando necessário)
│   └── ARCHITECTURE.md         (referenciado quando necessário)
└── .claude/
    └── skills/
        └── authentication/
            └── SKILL.md         (carregado automaticamente)
```

**Como Usar:**
```markdown
# CLAUDE.md

## Problemas Comuns
- TypeError "v is not a function" → Ver @docs/TROUBLESHOOTING.md
- Deploy falhou → Ver @docs/DEPLOY_GUIDE.md
```

Claude só carrega `@docs/TROUBLESHOOTING.md` quando você referenciar explicitamente.

---

### 3. Arquive Documentação de Sessão

**❌ NÃO FAÇA:**
```
SESSAO_2025_10_20.md              (10 KB - nunca mais será lido)
LOGOUT_BUG_INVESTIGATION.md       (8 KB - contexto da sessão passada)
CACHE_PROBLEM_SOLVED.md           (6 KB - problema já resolvido)
ROOT_CAUSE_FOUND.md               (5 KB - investigação concluída)
[... 27 arquivos de debugging ...]
```

**✅ FAÇA:**
```
docs/archive/2025-10-20/
├── SESSAO_COMPLETA.md            (arquivado - não lido automaticamente)
├── CACHE_INVESTIGATION.md        (arquivado)
└── ROOT_CAUSE.md                 (arquivado)

CLAUDE.md                          (atualizado com lição aprendida)
```

**Regra Oficial:**
> Memory files are read at the beginning of each coding session, which is why it's important to keep them lean as they take up the context window space.

---

### 4. Quando Limpar Contexto

**Comando `/clear` ou Nova Sessão:**
```bash
# Quando você NÃO precisa do contexto atual:
/clear

# Ou inicie nova sessão:
claude  # (novo contexto zerado)
```

**Salvar Antes de Limpar:**
```bash
# Se quiser manter registro da sessão:
"Claude, salve o contexto atual em docs/archive/sessao-$(date +%Y%m%d).md"
/clear
```

---

### 5. Persistência Entre Sessões

**O Que Persiste:**
- ✅ `CLAUDE.md` (lido automaticamente)
- ✅ Skills (`.claude/skills/*/SKILL.md`)
- ✅ Arquivos de código (versionados no git)

**O Que NÃO Persiste:**
- ❌ Conversa anterior (a menos que use `claude --resume abc123`)
- ❌ Arquivos `.md` criados durante debugging (exceto se referenciados)
- ❌ Memória do que aconteceu na sessão passada

**Comando para Continuar:**
```bash
# Continuar última conversa:
claude -c

# Retomar sessão específica:
claude --resume abc123

# Listar sessões recentes:
claude --resume
```

---

## 📊 Impacto na Economia de Tokens

### Antes (Nossa Sessão de 9h):

```
CLAUDE.md: 1557 linhas
+ 31 arquivos .md adicionais: 322 KB
= ~120.000 tokens carregados no início de cada sessão
= 60% do contexto desperdiçado
```

### Depois (Simplificado):

```
CLAUDE.md: 78 linhas
+ 7 arquivos essenciais: 45 KB
= ~15.000 tokens carregados
= 87% de redução no consumo de contexto
```

**Resultado:**
- ✅ Mais espaço para código
- ✅ Respostas mais rápidas
- ✅ Custo menor

---

## 🎯 Checklist Anti-Documentação Excessiva

Antes de criar um novo arquivo `.md`, pergunte:

- [ ] **É essencial para TODA sessão?** → `CLAUDE.md`
- [ ] **É específico de um domínio?** → `.claude/skills/*/SKILL.md`
- [ ] **É referência eventual?** → `docs/` + `@import`
- [ ] **É log de debugging?** → `docs/archive/` (não versionado)
- [ ] **Já foi resolvido?** → Arquivar ou deletar

**Regra de Ouro:**
> Se você não vai referenciar explicitamente com `@path`, não crie o arquivo.

---

## 📋 Estrutura Recomendada (Nossa Correção)

```
MUTUA/
├── CLAUDE.md                               (78 linhas - essencial)
├── README.md                               (overview do projeto)
├── docs/
│   ├── TROUBLESHOOTING.md                  (problemas comuns)
│   ├── DEPLOYMENT_CHECKLIST.md             (deploy manual)
│   ├── LICOES_APRENDIDAS_ANTI_CIRCULO.md   (lições de debugging)
│   └── archive/
│       ├── 2025-10-20-sessao-longa/        (31 arquivos arquivados)
│       └── 2025-10-legacy/                 (11 arquivos legados)
└── .claude/
    ├── commands/
    │   ├── deploy-conscious.md
    │   └── health.md
    └── skills/
        ├── authentication-management/
        │   └── SKILL.md
        └── pix-validation/
            └── SKILL.md
```

**Resultado:**
- 7 arquivos ativos (vs. 31 antes)
- 45 KB total (vs. 322 KB antes)
- 87% redução de contexto desperdiçado

---

## 🔍 Verificar Arquivos Carregados

**Comando:**
```bash
/memory
```

**Output:**
```
📚 Memory files loaded:
- ~/.claude/CLAUDE.md (global)
- /Users/lucascardoso/Desktop/MUTUA/CLAUDE.md (project)
- /Users/lucascardoso/Desktop/MUTUA/.claude/skills/authentication-management/SKILL.md
- /Users/lucascardoso/Desktop/MUTUA/.claude/skills/pix-validation/SKILL.md
```

---

## 💡 Resumo Final

**O Que Claude Code Faz:**
1. Lê `CLAUDE.md` **automaticamente** no início de cada sessão
2. Carrega skills de `.claude/skills/*/SKILL.md`
3. Importa arquivos referenciados com `@path`
4. **NÃO lê** todos os `.md` do projeto automaticamente

**Nossa Correção (2025-10-20):**
- ❌ Tínhamos: 31 arquivos MD (322 KB) - 95% inútil
- ✅ Agora temos: 7 arquivos MD (45 KB) - 100% útil
- 🚀 Economia: 87% menos tokens desperdiçados

**Lição Aprendida:**
> Criar documentação durante debugging é ok, mas **arquive imediatamente** após resolver. Claude só precisa do essencial em `CLAUDE.md`.

---

**Fonte Oficial:** https://docs.claude.com/en/docs/claude-code/memory
**Data:** 2025-10-20
**Economia de Tokens:** 87% (120.000 → 15.000 tokens)
