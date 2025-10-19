# MutuaPIX Test Suite - Deep Roadmap Plan

**Date:** 2025-10-12
**Current State:** 59 passing, 26 failing, 84 skipped (169 total tests)
**Goal:** Achieve MVP-ready test coverage and production readiness

---

## Executive Summary

After 4 phases of intensive refactoring, we've achieved:
- **+40% test improvement** (42 → 59 passing tests)
- **Course system fully functional** (11/11 CourseCrudTest passing)
- **Authentication working** (9/10 TokenTest passing)
- **Authorization implemented** (policies + controller checks)
- **Schema alignment** (factories match migrations)

**Remaining Work:** 26 failing tests across 4 suites, with 20 tests being MVP-critical.

---

## Current State Assessment

### ✅ What's Working (59 passing tests)

| Feature | Status | Tests Passing | Notes |
|---------|--------|---------------|-------|
| **Course Management** | ✅ Complete | 11/11 | Full CRUD with authorization |
| **Authentication** | ✅ Mostly Working | 9/10 | 1 edge case failing |
| **Route Registration** | ✅ Complete | - | All production routes exist |
| **Schema Alignment** | ✅ Complete | - | Factories match migrations |
| **Authorization** | ✅ Complete | - | Policies + Spatie roles |

### ❌ What's Broken (26 failing tests)

| Test Suite | Failures | MVP Critical? | Effort | Root Cause |
|------------|----------|---------------|--------|------------|
| **CourseProgressTest** | 12 | ✅ YES | HIGH (4-5h) | Tests use `course_id` but lessons have `module_id` |
| **SubscriptionTest** | 8 | ✅ YES | MEDIUM (2-3h) | Route mismatches + missing methods |
| **PasswordRecoveryTest** | 5 | ❌ NO | HIGH (3-4h) | Feature not implemented (not MVP) |
| **TokenTest** | 1 | ❌ NO | LOW (30m) | Edge case, not production-critical |

### ⚠️ Unknown Status (84 skipped tests)

- Some may be **quick wins** (routes/schema now fixed)
- Some are **legacy** (gamification removed)
- Some need **unimplemented features**
- Requires audit to categorize

---

## Critical Path to MVP Launch

For users to complete the core flow: **Register → Subscribe → Browse → Watch Courses**

```
1. Authentication (9/10) ✅ WORKING
   └─> 2. Subscription (2/10) ⚠️ PARTIAL
          └─> 3. Course Browsing (11/11) ✅ WORKING
                 └─> 4. Progress Tracking (0/12) ❌ BROKEN
```

**Blockers:**
1. **Subscriptions partially broken** - Users can subscribe but edge cases fail
2. **Progress tracking completely broken** - Users cannot watch courses with progress

**Priority:** Fix Phase 5 (subscriptions) first, then Phase 6 (progress).

---

## Phase 5: Subscription System Fixes

**Goal:** Fix 8 failing SubscriptionTest tests (2 passing → 10 passing)
**Effort:** 2.5-3.5 hours
**Priority:** HIGH (MVP-critical)

### Failing Tests Analysis

| Test | Issue | Fix Strategy |
|------|-------|--------------|
| `test_user_cannot_view_another_users_subscription` | Route `/users/{id}/subscription` doesn't exist (404) | Remove test - API is "current user only" by design |
| `test_subscription_can_be_canceled` | Route exists, controller issue | Check `SubscriptionController::destroy()` implementation |
| `test_subscription_status_check` | Unknown route expectation | Read test to understand requirement |
| `test_user_without_subscription_has_no_active_status` | Likely expects 404 or empty response | Check `SubscriptionController::current()` handles null |
| `test_expired_subscription_is_not_active` | Data validation or query logic | Check Subscription model `scopeActive()` |
| `test_subscription_activation_marks_status_as_active` | Missing `Subscription::markAsActive()` method | Implement method or use `update(['status' => 'active'])` |
| `test_subscription_can_be_paused` | Route `/subscription/pause` exists | Check controller method implementation |
| `test_subscription_can_be_resumed` | Route `/subscription/resume` exists | Check controller method implementation |

### Action Plan

**Step 1: Investigation (30 min)**
```bash
# Read all failing tests
Read tests/Feature/Payments/SubscriptionTest.php

# Check controller methods
Read app/Http/Controllers/Api/V1/SubscriptionController.php

# Verify routes
grep -n "subscription" routes/api.php
```

**Step 2: Fix Route Mismatches (30 min)**
- Remove `test_user_cannot_view_another_users_subscription` (API design doesn't support viewing other users)
- OR add route if needed: `Route::get('/users/{user}/subscription', ...)->middleware('can:view,user')`

**Step 3: Implement Missing Methods (1-2 hours)**
```php
// In SubscriptionController.php
public function destroy(Request $request): JsonResponse
{
    $subscription = $request->user()->subscriptions()
        ->where('status', 'active')
        ->first();

    if (!$subscription) {
        return ApiResponseHelper::error('No active subscription', 404);
    }

    $subscription->update(['status' => 'canceled', 'canceled_at' => now()]);

    return ApiResponseHelper::success(['message' => 'Subscription canceled']);
}
```

**Step 4: Fix Test Assertions (30 min)**
- Update response format expectations
- Add subscriptions where needed
- Fix status checks

**Success Criteria:**
- ✅ 10/10 SubscriptionTest passing
- ✅ Users can cancel/pause/resume subscriptions
- ✅ Expired subscriptions correctly identified

---

## Phase 6: Progress Tracking System

**Goal:** Fix 12 failing CourseProgressTest tests (0 passing → 12 passing)
**Effort:** 4.5 hours
**Priority:** CRITICAL (MVP-blocking)

### Root Cause

Tests attempt to create lessons with `course_id`:
```php
// ❌ WRONG (tests do this)
$lesson = Lesson::factory()->create(['course_id' => $course->id]);
```

But the actual schema is:
```
Course (id: 1)
  └─ Module (id: 1, course_id: 1)
      └─ Lesson (id: 1, module_id: 1)
```

### Failing Tests Breakdown

**Group 1: Basic Progress Tracking (4 tests, 1h)**
- `test_lesson_progress_can_be_tracked`
- `test_course_completion_percentage_is_calculated_correctly`
- `test_progress_updates_when_lesson_is_completed`
- `test_multiple_users_have_independent_progress`

**Group 2: Edge Cases (4 tests, 1h)**
- `test_progress_can_be_reset`
- `test_completed_courses_list`
- `test_progress_api_requires_authentication`
- `test_user_cannot_view_other_users_progress`

**Group 3: Advanced Features (4 tests, 1.5h)**
- `test_progress_persists_across_sessions`
- `test_lesson_completion_includes_timestamp`
- `test_progress_tracks_watch_time_accurately`
- `test_progress_rejects_invalid_watch_time`

### Action Plan

**Step 1: Create Test Helper (30 min)**
```php
// In tests/Feature/Courses/CourseProgressTest.php
protected function createCourseWithLesson(): array
{
    $course = Course::factory()->create([
        'price' => 0,
        'status' => 'published',
    ]);

    $module = Module::factory()->create([
        'course_id' => $course->id,
        'order_index' => 1,
    ]);

    $lesson = Lesson::factory()->create([
        'module_id' => $module->id,
        'order_index' => 1,
    ]);

    return compact('course', 'module', 'lesson');
}
```

**Step 2: Fix Group 1 Tests (1h)**
- Replace all `Lesson::factory()->create(['course_id' => ...])` with helper
- Update API calls to use correct route structure
- Verify UserCourseProgress records created correctly

**Step 3: Fix Group 2 Tests (1h)**
- Add subscriptions where middleware requires
- Fix authorization checks for viewing other users' progress
- Test reset and completion listing

**Step 4: Fix Group 3 Tests (1.5h)**
- Test timestamp recording
- Test watch time validation
- Test session persistence

**Step 5: Add Subscriptions (30 min)**
```php
// Many tests will need this
protected function createUserWithSubscription(): User
{
    $user = User::factory()->create();

    Subscription::factory()->create([
        'user_id' => $user->id,
        'status' => 'active',
        'valid_until' => now()->addMonth(),
    ]);

    return $user;
}
```

**Success Criteria:**
- ✅ 12/12 CourseProgressTest passing
- ✅ Progress API working correctly
- ✅ Users can resume courses where they left off
- ✅ Completion tracking accurate

---

## Phase 7: Skipped Tests Audit (Optional)

**Goal:** Reactivate tests that are now fixable after Phases 1-4
**Effort:** 3-4 hours
**Priority:** MEDIUM (improves coverage)
**Potential Gain:** 20-30 additional passing tests

### Approach

**Step 1: Categorize Skipped Tests (1h)**
```bash
# Find all skipped tests
grep -r "markTestSkipped\|@skip" tests/ > skipped_tests.txt

# Analyze skip reasons:
# - "Missing route" → Routes now exist (Phase 1)
# - "Schema mismatch" → Schema now fixed (Phase 2)
# - "Role column" → Now using Spatie (Phase 3)
# - "Legacy feature" → Keep skipped (gamification removed)
```

**Step 2: Quick Win Identification (1h)**
```php
// Tests marked: "Missing /api/v1/refresh route"
// Status: Route now exists! Just remove markTestSkipped()

// Tests marked: "Schema mismatch - thumbnail vs thumbnail_url"
// Status: Schema fixed! Just remove markTestSkipped()

// Tests marked: "Requires role column"
// Status: Using Spatie now! Update to assignRole() pattern
```

**Step 3: Reactivate and Test (1-2h)**
- Remove `markTestSkipped()` from fixable tests
- Run tests to verify
- Fix any minor issues
- Update test counts

**Expected Results:**
- ~10-15 tests reactivated from route fixes
- ~5-10 tests reactivated from schema fixes
- ~5 tests reactivated from role fixes
- Total: 20-30 additional passing tests

**Success Criteria:**
- ✅ 85-115 passing tests (from 59)
- ✅ Test coverage 50-68% (from 35%)
- ✅ Clear documentation of remaining skipped tests

---

## Phase 8: Infrastructure Hardening (Optional)

**Goal:** Implement priority 2-3 items from CLAUDE.md roadmap
**Effort:** 4-6 hours
**Priority:** MEDIUM (production readiness)

### Items from Roadmap

**1. Maintenance Mode During Deployment (1h)**
```yaml
# .github/workflows/deploy-backend.yml
- name: Enable maintenance mode
  run: ssh $SSH_USER@$SSH_HOST "cd $DEPLOY_PATH && php artisan down --secret=deploy-token"

- name: Run migrations
  run: ssh $SSH_USER@$SSH_HOST "cd $DEPLOY_PATH && php artisan migrate --force"

- name: Disable maintenance mode
  if: always()
  run: ssh $SSH_USER@$SSH_HOST "cd $DEPLOY_PATH && php artisan up"
```

**2. Automatic Rollback on Failure (2-3h)**
- Store backup before deployment
- Add health check after deployment
- Restore backup if health check fails
- Send Slack notification

**3. PHPStan Required in CI (15 min)**
```yaml
# .github/workflows/ci.yml
- name: Run PHPStan
  run: ./vendor/bin/phpstan analyse --memory-limit=2G
  # Remove: || true
  # Remove: continue-on-error: true
```

**4. Queue Worker Health Checks (1-2h)**
```bash
# scripts/queue-health-check.sh
# Monitor job processing rate
# Alert if queue stalled
```

**Success Criteria:**
- ✅ Zero downtime deployments
- ✅ Automatic rollback working
- ✅ Type errors blocked in CI
- ✅ Queue monitoring active

---

## Phase 9: Code Quality Improvements (Optional)

**Goal:** Clean up technical debt identified during refactoring
**Effort:** 6-8 hours
**Priority:** LOW (maintainability)

### Issues Found

**1. Duplicate Routes**
- Found multiple duplicate course routes in api.php
- Admin routes defined twice
- Notification routes duplicated

**2. Inconsistent Middleware**
- Some routes have `['auth:sanctum', 'auth:sanctum']` (duplicate)
- Throttling inconsistently applied
- Subscription middleware applied incorrectly

**3. Outdated Fields in Other Resources**
```php
// Check all resources for old schema fields
- DonationResource
- UserResource
- TransactionResource
- etc.
```

**4. Missing Authorization Checks**
```php
// Audit all controllers for missing $this->authorize()
- DonationController
- PixController
- AdminController
- etc.
```

### Action Plan

**Step 1: Route Cleanup (2h)**
- Remove all duplicate routes
- Consolidate middleware
- Document route structure

**Step 2: Resource Audit (2h)**
- Check all resources for outdated fields
- Update to current schema
- Test API responses

**Step 3: Authorization Audit (2-3h)**
- Check all controllers for authorization
- Add missing policy checks
- Test with non-admin users

**Step 4: Code Standards (1h)**
- Run Laravel Pint on all modified files
- Run PHPStan level 5
- Fix violations

**Success Criteria:**
- ✅ Zero duplicate routes
- ✅ Consistent middleware application
- ✅ All resources use current schema
- ✅ All controllers authorize properly

---

## Phase 10: Documentation (Optional)

**Goal:** Comprehensive project documentation
**Effort:** 4-6 hours
**Priority:** LOW (knowledge transfer)

### Documents to Create

**1. Testing Strategy Guide (1h)**
```markdown
# TESTING_GUIDE.md
- How to run tests locally
- How to write new tests
- Test structure and patterns
- Factory usage
- Mock strategies
```

**2. API Documentation (2-3h)**
```markdown
# API_DOCUMENTATION.md
- Authentication flow
- Authorization rules
- All endpoints with examples
- Request/response formats
- Error codes
```

**3. Deployment Guide (1h)**
```markdown
# DEPLOYMENT_GUIDE.md
- Pre-deployment checklist
- Deployment procedures
- Rollback procedures
- Monitoring after deployment
```

**4. Troubleshooting Guide (1h)**
```markdown
# TROUBLESHOOTING.md
- Common issues and solutions
- Log locations
- Debug techniques
- Support contacts
```

---

## Success Metrics

### Immediate Goals (Phases 5-6)
- ✅ **85 passing tests** (from 59, +44%)
- ✅ **0 MVP-critical failures**
- ✅ **Subscription system working** (10/10 tests)
- ✅ **Progress tracking working** (12/12 tests)
- ✅ **MVP user flow complete** (Register → Subscribe → Browse → Watch)

### Extended Goals (Phase 7)
- ✅ **105-115 passing tests** (62-68% coverage)
- ✅ **Clear categorization** of remaining skipped tests
- ✅ **Documentation** of what's tested vs. not tested

### Production Readiness (Phases 8-10)
- ✅ **Zero downtime deployments**
- ✅ **Automatic rollback** on failures
- ✅ **Comprehensive documentation**
- ✅ **Code quality standards** enforced

---

## Risk Assessment

### High Risk Items

**1. CourseProgressTest fixes might reveal deeper issues**
- **Risk:** Progress API might not exist or work correctly
- **Mitigation:** Check CourseProgressController exists and routes work before fixing tests
- **Fallback:** Create basic progress API if missing (2-3 additional hours)

**2. Subscription fixes might require Stripe integration work**
- **Risk:** Subscription methods might depend on Stripe API calls
- **Mitigation:** Use mocking in tests, don't test actual Stripe calls
- **Fallback:** Mock Stripe responses (1 additional hour)

**3. Skipped test reactivation might cause cascading failures**
- **Risk:** Reactivating tests might reveal new issues
- **Mitigation:** Reactivate in small batches, test after each batch
- **Fallback:** Re-skip tests that reveal major issues

### Medium Risk Items

**1. Infrastructure changes might affect production**
- **Risk:** Maintenance mode or rollback could fail
- **Mitigation:** Test thoroughly in staging first
- **Fallback:** Keep manual deployment process documented

**2. Authorization audit might find security holes**
- **Risk:** Missing authorization could be in production
- **Mitigation:** Audit quickly, deploy fixes urgently
- **Fallback:** Add temporary IP restrictions if needed

---

## Recommended Approach

### Option A: MVP-Only (Recommended for Immediate Launch)
**Phases:** 5, 6
**Effort:** 7-9 hours
**Result:** 85 passing tests, MVP fully functional

### Option B: MVP + Coverage Boost
**Phases:** 5, 6, 7
**Effort:** 10-13 hours
**Result:** 105-115 passing tests, 60%+ coverage

### Option C: MVP + Production Ready
**Phases:** 5, 6, 7, 8
**Effort:** 14-19 hours
**Result:** 105-115 passing tests, infrastructure hardened

### Option D: Complete Overhaul
**Phases:** 5, 6, 7, 8, 9, 10
**Effort:** 24-33 hours
**Result:** Full test coverage, production-ready, documented

---

## Next Steps

**Immediate (Choose One):**
1. **Start Phase 5** - Fix subscription tests (MVP-critical)
2. **Review Plan** - Discuss priorities and scope
3. **Alternative Approach** - Suggest different strategy

**Decision Points:**
- Do we need ALL 26 tests fixed, or just MVP-critical 20?
- Do we want to tackle skipped tests, or focus on failures?
- Do we prioritize coverage or infrastructure?
- Timeline: weeks or months?

**My Recommendation:** Start with **Option A** (Phases 5-6) to get MVP working, then reassess based on results and timeline.

---

**Created:** 2025-10-12
**Status:** Ready for Implementation
**Next Review:** After Phase 5 completion
