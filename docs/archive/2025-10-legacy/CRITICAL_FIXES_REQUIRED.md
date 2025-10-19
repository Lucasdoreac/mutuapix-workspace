# 🔴 CORREÇÕES CRÍTICAS OBRIGATÓRIAS - MutuaPIX Backend

**Data:** 2025-10-10
**Status:** 🚨 **BLOQUEADORES - APLICAÇÃO NÃO FUNCIONA SEM ESTAS CORREÇÕES**
**Prioridade:** P0 (Máxima)

---

## 📋 ÍNDICE

1. [Schema Mismatch - Tabelas vs Models](#1-schema-mismatch)
2. [Migrations Faltando](#2-migrations-faltando)
3. [Subscription Model - Correções](#3-subscription-model)
4. [User Model - Correções](#4-user-model)
5. [Ordem de Execução](#5-ordem-de-execução)
6. [Checklist de Validação](#6-checklist-de-validação)

---

## 1. SCHEMA MISMATCH - Tabelas vs Models

### Problema

Migrations criam tabelas com nomes diferentes dos que Models referenciam.

| Model | Model Espera | Migration Cria | Status |
|-------|-------------|----------------|--------|
| Course | `courses_v2` | `courses` | ❌ CONFLITO |
| Module | `course_modules` | `modules` | ❌ CONFLITO |
| Lesson | `course_lessons` | `lessons` | ❌ CONFLITO |

### Impacto

```bash
# Ao rodar migrations
php artisan migrate
# ✅ Cria: courses, modules, lessons

# Ao usar Models
Course::all()
# ❌ QueryException: Table 'courses_v2' doesn't exist
```

### Correção RECOMENDADA - Opção A (Atualizar Models)

**MAIS SIMPLES E SEGURO**: Remover `protected $table` dos models.

#### 1.1 Course Model

**Arquivo:** `backend/app/Models/Course.php`

```diff
  class Course extends Model
  {
      use HasFactory, SoftDeletes;

-     protected $table = 'courses_v2';
+     // Usar convenção Laravel: courses

      protected $fillable = [
```

#### 1.2 Module Model

**Arquivo:** `backend/app/Models/Module.php`

```diff
  class Module extends Model
  {
      use HasFactory, SoftDeletes;

-     protected $table = 'course_modules';
+     // Usar convenção Laravel: modules

      protected $fillable = [
```

#### 1.3 Lesson Model

**Arquivo:** `backend/app/Models/Lesson.php`

```diff
  class Lesson extends Model
  {
      use HasFactory, SoftDeletes;

-     protected $table = 'course_lessons';
+     // Usar convenção Laravel: lessons

      protected $fillable = [
```

### Correção ALTERNATIVA - Opção B (Atualizar Migrations)

**MAIS TRABALHOSA**: Renomear tabelas nas migrations.

```diff
  // 2024_04_12_000001_create_courses_table.php
  public function up(): void
  {
-     Schema::create('courses', function (Blueprint $table) {
+     Schema::create('courses_v2', function (Blueprint $table) {
```

```diff
  // 2024_04_12_000002_create_modules_table.php
  public function up(): void
  {
-     Schema::create('modules', function (Blueprint $table) {
+     Schema::create('course_modules', function (Blueprint $table) {
```

```diff
  // 2024_04_12_000003_create_lessons_table.php
  public function up(): void
  {
-     Schema::create('lessons', function (Blueprint $table) {
+     Schema::create('course_lessons', function (Blueprint $table) {
```

**⚠️ ATENÇÃO:** Se escolher Opção B, também precisa atualizar foreign keys em TODAS as migrations que referenciam estas tabelas!

---

## 2. MIGRATIONS FALTANDO

### Problema

2 models existem mas suas migrations não foram criadas:
- `CourseEnrollment` (usado em Course, User)
- `UserCourseProgress` (usado em Lesson, StudentProgressController)

### Impacto

```bash
php artisan migrate
# ✅ Migrations rodam

# Ao usar controllers
POST /api/v1/progress/update
# ❌ QueryException: Table 'user_course_progress' doesn't exist
```

### Correção 2.1 - Migration de CourseEnrollment

**Criar arquivo:** `backend/database/migrations/2025_01_20_000006_create_course_enrollments_table.php`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('course_enrollments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');

            // ⚠️ ATENÇÃO: Se escolheu Opção A acima, usar 'courses'
            // Se escolheu Opção B acima, usar 'courses_v2'
            $table->foreignId('course_id')->constrained('courses')->onDelete('cascade');

            $table->timestamp('enrolled_at')->useCurrent();
            $table->timestamp('completed_at')->nullable();
            $table->integer('progress_percentage')->default(0);
            $table->timestamps();

            $table->unique(['user_id', 'course_id']);
            $table->index('enrolled_at');
            $table->index('completed_at');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('course_enrollments');
    }
};
```

### Correção 2.2 - Migration de UserCourseProgress

**Criar arquivo:** `backend/database/migrations/2025_01_20_000007_create_user_course_progress_table.php`

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_course_progress', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');

            // ⚠️ ATENÇÃO: Ajustar nomes conforme escolha na Seção 1
            $table->foreignId('course_id')->constrained('courses')->onDelete('cascade');
            $table->foreignId('lesson_id')->constrained('lessons')->onDelete('cascade');

            $table->boolean('completed')->default(false);
            $table->integer('progress_percentage')->default(0);
            $table->integer('time_spent')->default(0)->comment('Tempo em segundos');
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();

            $table->unique(['user_id', 'lesson_id']);
            $table->index(['user_id', 'course_id']);
            $table->index('completed');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_course_progress');
    }
};
```

---

## 3. SUBSCRIPTION MODEL - Correções

### Problema 3.1 - Método markAsActive() Faltando

**Onde é chamado:**
- `RegisterController.php:41`
- `StripeWebhookController.php` (PR #18)
- `PagarmeWebhookController.php` (PR #18)
- `ProcessStripeWebhook.php` (Job)

**Erro ao executar:**
```
Fatal error: Call to undefined method App\Models\Subscription::markAsActive()
```

### Problema 3.2 - Coluna expires_at vs valid_until

**Migration cria:** `valid_until` (linha 26)
**Código usa:** `expires_at` ([User.php:60](backend/app/Models/User.php#L60))

```php
// User.php - NÃO VAI FUNCIONAR
public function activeSubscription()
{
    return $this->hasOne(Subscription::class)
        ->where('status', 'active')
        ->where('expires_at', '>', now()); // ❌ Coluna não existe!
}
```

### Problema 3.3 - Fillable Incompleto

`expires_at` (ou `valid_until`) não está em `$fillable` nem `$casts`.

### Correção 3 - Subscription Model Completo

**Arquivo:** `backend/app/Models/Subscription.php`

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Subscription extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'user_id',
        'plan_id',
        'plan',
        'status',
        'stripe_session_id',
        'stripe_subscription_id',
        'stripe_customer_id',
        'started_at',
        'next_billing_at',
        'trial_ends_at',
        'valid_until',        // ✅ ADICIONADO
        'canceled_at',
    ];

    protected $casts = [
        'started_at' => 'datetime',
        'next_billing_at' => 'datetime',
        'trial_ends_at' => 'datetime',
        'valid_until' => 'datetime',     // ✅ ADICIONADO
        'canceled_at' => 'datetime',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function plan()
    {
        return $this->belongsTo(Plan::class);
    }

    public function isActive(): bool
    {
        return $this->status === 'active' && !$this->canceled_at;
    }

    /**
     * Marca a assinatura como ativa
     *
     * ✅ MÉTODO NOVO - OBRIGATÓRIO
     */
    public function markAsActive(): void
    {
        $this->update([
            'status' => 'active',
            'started_at' => $this->started_at ?? now(),
            'next_billing_at' => $this->next_billing_at ?? now()->addMonth(),
            'valid_until' => $this->valid_until ?? now()->addMonth(),
            'canceled_at' => null,
        ]);
    }
}
```

### Correção 3.4 - Atualizar User.php para usar valid_until

**Arquivo:** `backend/app/Models/User.php`

**OPÇÃO A - Renomear no User.php (RECOMENDADO):**

```diff
  public function activeSubscription()
  {
      return $this->hasOne(Subscription::class)
          ->where('status', 'active')
-         ->where('expires_at', '>', now());
+         ->where('valid_until', '>', now());
  }
```

**OPÇÃO B - Adicionar migration para renomear coluna:**

```php
// 2025_01_20_000008_rename_valid_until_to_expires_at.php
public function up(): void
{
    Schema::table('subscriptions', function (Blueprint $table) {
        $table->renameColumn('valid_until', 'expires_at');
    });
}
```

---

## 4. USER MODEL - Correções

### Problema 4.1 - Relacionamento com Payment inexistente

**Arquivo:** `backend/app/Models/User.php:65`

```php
public function payments()
{
    return $this->hasMany(Payment::class)  // ❌ Class não existe
        ->orderBy('created_at', 'desc');
}
```

**Verificação:**
```bash
$ find backend/app/Models -name "Payment.php"
(sem resultados)
```

### Problema 4.2 - Relacionamento courseEnrollments() faltando

Usado em controllers mas não existe no model.

### Correção 4.1 - Trocar Payment por Transaction

**Arquivo:** `backend/app/Models/User.php`

```diff
  public function payments()
  {
-     return $this->hasMany(Payment::class)
+     return $this->hasMany(Transaction::class)
          ->orderBy('created_at', 'desc');
  }
```

### Correção 4.2 - Adicionar courseEnrollments()

**Arquivo:** `backend/app/Models/User.php`

Adicionar após linha 100:

```php
public function courseEnrollments()
{
    return $this->hasMany(CourseEnrollment::class);
}

public function courseProgress()
{
    return $this->hasMany(UserCourseProgress::class);
}
```

---

## 5. ORDEM DE EXECUÇÃO

### 5.1 Decisão Estratégica

```
┌─────────────────────────────────────────┐
│ ESCOLHER UMA OPÇÃO:                     │
├─────────────────────────────────────────┤
│ A) Atualizar Models (RECOMENDADO)      │
│    - Remover protected $table           │
│    - Mais simples e rápido              │
│    - Menos risco de quebrar VPS         │
│                                          │
│ B) Atualizar Migrations                 │
│    - Renomear tabelas nas migrations    │
│    - Mais trabalhoso                     │
│    - Requer ajuste de todas as FKs      │
└─────────────────────────────────────────┘
```

### 5.2 Passos (Se Opção A)

```bash
# 1. Atualizar Models
✅ Course.php - remover protected $table
✅ Module.php - remover protected $table
✅ Lesson.php - remover protected $table

# 2. Criar Migrations
✅ create_course_enrollments_table.php
✅ create_user_course_progress_table.php

# 3. Corrigir Subscription.php
✅ Adicionar valid_until ao $fillable e $casts
✅ Adicionar método markAsActive()

# 4. Corrigir User.php
✅ Trocar Payment::class por Transaction::class
✅ Trocar expires_at por valid_until em activeSubscription()
✅ Adicionar courseEnrollments() e courseProgress()

# 5. Testar
php artisan migrate:fresh
php artisan test
```

### 5.3 Passos (Se Opção B)

```bash
# 1. Atualizar Migrations de Courses
✅ create_courses_table.php - courses → courses_v2
✅ create_modules_table.php - modules → course_modules
✅ create_lessons_table.php - lessons → course_lessons

# 2. Atualizar TODAS as migrations com foreign keys
✅ Buscar por: constrained('modules') → constrained('course_modules')
✅ Buscar por: constrained('lessons') → constrained('course_lessons')

# 3. Criar Migrations (com nomes corretos)
✅ create_course_enrollments_table.php → course_id constrained('courses_v2')
✅ create_user_course_progress_table.php → idem acima

# 4. Corrigir Subscription.php (igual Opção A)
✅ Adicionar valid_until ao $fillable e $casts
✅ Adicionar método markAsActive()

# 5. Corrigir User.php (igual Opção A)
✅ Trocar Payment::class por Transaction::class
✅ Trocar expires_at por valid_until em activeSubscription()
✅ Adicionar courseEnrollments() e courseProgress()

# 6. Testar
php artisan migrate:fresh
php artisan test
```

---

## 6. CHECKLIST DE VALIDAÇÃO

### 6.1 Pré-Correção

```bash
# Fazer backup do banco de dados
mysqldump -u root mutuapix > backup_pre_fix.sql

# Criar branch para correções
git checkout -b fix/critical-schema-issues
```

### 6.2 Após Correções

#### Validação de Migrations

```bash
# Rodar migrations em ambiente limpo
php artisan migrate:fresh

# Verificar tabelas criadas
php artisan db:show

# Verificar foreign keys
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE REFERENCED_TABLE_NAME IS NOT NULL
AND TABLE_SCHEMA = 'mutuapix';
```

#### Validação de Models

```bash
# Testar relacionamentos via Tinker
php artisan tinker

>>> $user = User::first();
>>> $user->payments; // ✅ Deve retornar Collection de Transaction
>>> $user->courseEnrollments; // ✅ Deve retornar Collection
>>> $user->activeSubscription; // ✅ Deve retornar Subscription ou null

>>> $course = Course::first();
>>> $course->modules; // ✅ Deve retornar Collection
>>> $course->enrollments; // ✅ Deve retornar Collection

>>> $subscription = Subscription::first();
>>> $subscription->markAsActive(); // ✅ Não deve dar erro
>>> $subscription->fresh()->status; // ✅ Deve ser 'active'
```

#### Validação de Controllers

```bash
# Testar endpoints críticos

# 1. Register com plano free
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test User",
    "email": "test@example.com",
    "password": "password123",
    "plan": "FREE"
  }'
# ✅ Deve retornar token sem erro

# 2. Progress update
curl -X POST http://localhost:8000/api/v1/progress/update \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "lesson_id": 1,
    "course_id": 1,
    "progress_percentage": 50
  }'
# ✅ Não deve retornar "Table doesn't exist"

# 3. Course enrollment
curl http://localhost:8000/api/v1/courses/1/enroll \
  -H "Authorization: Bearer {token}"
# ✅ Não deve dar erro de relacionamento
```

#### Validação de Testes

```bash
# Rodar suíte completa de testes
php artisan test

# Se testes estavam skipados, descomentar e rodar
# Exemplo: CourseTest, SubscriptionTest, etc
php artisan test --filter=CourseTest
php artisan test --filter=SubscriptionTest
```

### 6.3 Checklist Final

```
✅ Migrations rodam sem erro
✅ Tabelas criadas com nomes corretos
✅ Foreign keys funcionam
✅ Course::all() retorna registros
✅ $user->payments funciona
✅ $user->courseEnrollments funciona
✅ $subscription->markAsActive() funciona
✅ Register endpoint funciona
✅ Progress update endpoint funciona
✅ Testes passam (ou pelo menos rodam sem Table doesn't exist)
```

---

## 7. IMPACTO SE NÃO CORRIGIR

### Cenário Atual de Produção

```
VPS Produção (138.199.162.115 + 49.13.26.142)
├── Tabelas já existem com nomes: courses_v2, course_modules, course_lessons ✅
├── Aplicação funciona porque models apontam para essas tabelas ✅
└── MAS: impossível rodar migrations em ambiente novo ❌
```

### Cenário ao Tentar Deploy em Novo Servidor

```bash
# Servidor novo
git clone ...
composer install
php artisan migrate

# ❌ QUEBRA TUDO:
# 1. Migrations criam: courses, modules, lessons
# 2. Models esperam: courses_v2, course_modules, course_lessons
# 3. Aplicação não funciona
```

### Cenário ao Usar Controllers

```bash
# POST /api/auth/register (plano FREE)
RegisterController::__invoke()
  → $subscription->markAsActive()
  → ❌ Fatal error: Call to undefined method

# GET /api/v1/user/payments
UserController::getPayments()
  → $user->payments
  → ❌ Class 'App\Models\Payment' not found

# POST /api/v1/progress/update
StudentProgressController::updateProgress()
  → UserCourseProgress::updateOrCreate()
  → ❌ QueryException: Table 'user_course_progress' doesn't exist
```

---

## 8. ESTIMATIVA DE TEMPO

| Tarefa | Tempo | Complexidade |
|--------|-------|--------------|
| 1. Schema Fix (Opção A) | 15 min | Baixa |
| 1. Schema Fix (Opção B) | 2h | Média |
| 2. Criar Migrations | 30 min | Baixa |
| 3. Corrigir Subscription | 20 min | Baixa |
| 4. Corrigir User | 10 min | Baixa |
| 5. Testes Manuais | 1h | Média |
| 6. Rodar Test Suite | 30 min | Baixa |
| **TOTAL (Opção A)** | **~3h** | |
| **TOTAL (Opção B)** | **~5h** | |

---

## 9. RECOMENDAÇÃO FINAL

### Escolher Opção A

**Motivos:**
1. ✅ Mais rápido (3h vs 5h)
2. ✅ Menos risco de erro
3. ✅ Convenção Laravel padrão
4. ✅ Mais fácil para novos desenvolvedores
5. ✅ VPS pode conviver com ambos os schemas temporariamente

**Único contraponto:**
- ⚠️ VPS produção tem tabelas `courses_v2`, etc. Precisará de migration para renomear.

### Plano de Migração Seguro (Produção)

```bash
# 1. Em desenvolvimento - aplicar Opção A
git checkout -b fix/schema-alignment
# ... fazer todas as correções ...
git commit -m "fix: align schema and models (critical)"

# 2. Em produção - criar migration para renomear tabelas
php artisan make:migration rename_course_tables_to_laravel_convention

// Migration:
Schema::rename('courses_v2', 'courses');
Schema::rename('course_modules', 'modules');
Schema::rename('course_lessons', 'lessons');

# 3. Deploy
# - Rodar migration de rename
# - Deploy código com models corrigidos
# - Testar endpoints
```

---

## 10. CONTATOS

**Responsável Técnico:** [A definir]
**Prazo:** 🔴 URGENTE (aplicação não funciona sem isso)
**Próxima Revisão:** Após aplicar correções

---

**ATENÇÃO:** Este documento lista APENAS os bloqueadores de schema/models.
Há outros 27 issues críticos documentados em `SECURITY_AUDIT_REPORT.md` que também precisam ser corrigidos.

---

**FIM DO DOCUMENTO**
