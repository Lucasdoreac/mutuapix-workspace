# 🧪 MVP Comprehensive Test Plan - MutuaPIX
**Generated:** 2025-10-17 21:20 BRT
**Testing Tool:** MCP Chrome DevTools
**Test Coverage:** All MVP Features

---

## 📋 MVP Scope (From CLAUDE.md)

**✅ IN SCOPE (6 Feature Areas):**
1. User registration/login
2. Subscription plans (Stripe)
3. Course viewing (Bunny CDN + progress tracking)
4. PIX donations with receipt generation
5. Financial history
6. Support tickets

**❌ OUT OF SCOPE (Removed Features):**
- Gamification (points, levels, badges)
- Affiliate system
- Analytics dashboard
- VIP status
- Achievements/Leaderboards

---

## 🎯 Test Scenarios by Feature

### 1️⃣ **Authentication & Registration**

#### 1.1 User Registration
- [ ] **TC-001:** Register new user with valid data
  - Email: `novo@teste.com`
  - Password: `SenhaForte123!`
  - Expected: Account created, redirect to dashboard

- [ ] **TC-002:** Register with existing email
  - Email: `joao@example.com` (already exists)
  - Expected: Error "Email já cadastrado"

- [ ] **TC-003:** Register with weak password
  - Password: `123`
  - Expected: Validation error "Senha deve ter mínimo 8 caracteres"

- [ ] **TC-004:** Register with invalid email format
  - Email: `invalido.com`
  - Expected: Validation error "Email inválido"

#### 1.2 User Login
- [ ] **TC-005:** Login with valid credentials
  - Email: `joao@example.com`
  - Password: (correct password from DB)
  - Expected: Redirect to `/user/dashboard`, token stored

- [ ] **TC-006:** Login with invalid email
  - Email: `naoexiste@teste.com`
  - Expected: 401 "Credenciais incorretas"

- [ ] **TC-007:** Login with wrong password
  - Email: `joao@example.com`
  - Password: `senha-errada`
  - Expected: 401 "Credenciais incorretas"

- [ ] **TC-008:** Login with "Remember Me" checked
  - Expected: Token has extended expiry (24h)

- [ ] **TC-009:** Verify CSRF token on login
  - Expected: `/sanctum/csrf-cookie` called before login

#### 1.3 Password Recovery
- [ ] **TC-010:** Request password reset with valid email
  - Email: `joao@example.com`
  - Expected: Reset token generated, email sent

- [ ] **TC-011:** Request password reset with invalid email
  - Email: `naoexiste@teste.com`
  - Expected: Generic message (security best practice)

- [ ] **TC-012:** Reset password with valid token
  - Expected: Password updated, can login with new password

- [ ] **TC-013:** Reset password with expired token (>60min)
  - Expected: Error "Token expirado"

- [ ] **TC-014:** Rate limiting on password reset
  - Expected: Max 1 request per minute per email

#### 1.4 Logout
- [ ] **TC-015:** Logout successfully
  - Expected: Token revoked, redirect to `/login`

- [ ] **TC-016:** Access protected route after logout
  - Expected: Redirect to `/login?returnUrl=/user/dashboard`

---

### 2️⃣ **Subscription Management (Stripe)**

#### 2.1 View Subscription Plans
- [ ] **TC-017:** View available subscription plans
  - Endpoint: `/api/v1/subscriptions/plans`
  - Expected: List of active plans with prices

- [ ] **TC-018:** View plan details
  - Expected: Name, price, duration, features displayed

#### 2.2 Create Subscription
- [ ] **TC-019:** Subscribe to monthly plan
  - Plan: "Mensal - R$ 49,90"
  - Expected: Stripe checkout session created

- [ ] **TC-020:** Subscribe to yearly plan
  - Plan: "Anual - R$ 499,00"
  - Expected: 17% discount applied

- [ ] **TC-021:** Complete Stripe payment flow
  - Expected: Webhook received, subscription activated

- [ ] **TC-022:** Handle payment failure
  - Expected: Subscription status = 'failed', user notified

#### 2.3 Manage Active Subscription
- [ ] **TC-023:** View current subscription status
  - Expected: Plan name, status, renewal date displayed

- [ ] **TC-024:** Pause subscription
  - Expected: Status = 'paused', access maintained until period end

- [ ] **TC-025:** Resume paused subscription
  - Expected: Status = 'active', billing resumed

- [ ] **TC-026:** Cancel subscription
  - Expected: Status = 'cancelled', access until end of period

- [ ] **TC-027:** Verify cancelled subscription after expiry
  - Expected: No access to premium content

#### 2.4 Stripe Webhooks
- [ ] **TC-028:** Handle `invoice.payment_succeeded`
  - Expected: Subscription renewed, expiry date extended

- [ ] **TC-029:** Handle `customer.subscription.deleted`
  - Expected: Subscription cancelled, access removed

- [ ] **TC-030:** Webhook idempotency
  - Send duplicate webhook
  - Expected: Processed only once (no duplicate charges)

---

### 3️⃣ **Course Viewing & Progress Tracking**

#### 3.1 Browse Courses
- [ ] **TC-031:** View all available courses
  - Endpoint: `/api/v1/courses`
  - Expected: List with thumbnails, titles, descriptions

- [ ] **TC-032:** View course details
  - Expected: Modules, lessons, duration, instructor

- [ ] **TC-033:** Access course without subscription
  - Expected: Redirect to subscription page or show paywall

- [ ] **TC-034:** Access course with active subscription
  - Expected: Full access to all lessons

#### 3.2 Video Playback (Bunny CDN)
- [ ] **TC-035:** Play first lesson video
  - Expected: Bunny player loads, video streams

- [ ] **TC-036:** Verify Bunny CDN URL signed
  - Expected: URL has signature/token (security)

- [ ] **TC-037:** Video quality selection
  - Expected: 480p, 720p, 1080p options available

- [ ] **TC-038:** Video controls (play/pause/seek)
  - Expected: All controls functional

#### 3.3 Progress Tracking
- [ ] **TC-039:** Mark lesson as completed
  - Expected: Progress saved to DB, checkmark displayed

- [ ] **TC-040:** Resume video from last position
  - Expected: `current_time_seconds` restored on page load

- [ ] **TC-041:** Update `last_watched_at` timestamp
  - Expected: Updated on every video interaction

- [ ] **TC-042:** Calculate course completion percentage
  - Expected: `completed_lessons / total_lessons * 100`

- [ ] **TC-043:** Complete entire course
  - Expected: Certificate generated (if implemented)

- [ ] **TC-044:** View progress history
  - Expected: List of courses in progress, completion %

#### 3.4 Database Indexes (Performance)
- [ ] **TC-045:** Query user's completed courses
  - Use index: `idx_progress_user_completed`
  - Expected: Query time < 100ms

- [ ] **TC-046:** Query recent activity
  - Use index: `idx_progress_last_watched`
  - Expected: Fast retrieval of last 10 watched lessons

---

### 4️⃣ **PIX Donation System**

#### 4.1 Create PIX Donation
- [ ] **TC-047:** Initiate PIX donation (R$ 50,00)
  - Expected: Transaction created, status = 'pending'

- [ ] **TC-048:** Generate PIX QR Code
  - Expected: QR code image displayed, PIX copy-paste string

- [ ] **TC-049:** Verify PIX key email validation
  - User email: `joao@example.com`
  - PIX key: Must match user email if `pix_key_type = 'email'`
  - Expected: Validation passes

- [ ] **TC-050:** PIX donation with mismatched email
  - User email: `joao@example.com`
  - PIX key email: `diferente@teste.com`
  - Expected: ⚠️ **CURRENTLY ALLOWED (BUG)** - Should reject!

#### 4.2 PIX Payment Confirmation
- [ ] **TC-051:** Manual payment confirmation (admin)
  - Expected: Status = 'confirmed', receipt generated

- [ ] **TC-052:** Automatic payment webhook (if integrated)
  - Expected: Status updated automatically

- [ ] **TC-053:** Payment expiration (>24h)
  - Expected: Status = 'expired', QR code invalid

#### 4.3 Receipt Generation
- [ ] **TC-054:** Generate PDF receipt
  - Expected: PDF with transaction details, QR code, timestamp

- [ ] **TC-055:** Download receipt
  - Expected: PDF downloaded with filename `recibo-TXID.pdf`

- [ ] **TC-056:** Email receipt to user
  - Expected: Email sent with PDF attachment

---

### 5️⃣ **Financial History**

#### 5.1 View Transactions
- [ ] **TC-057:** View all user transactions
  - Endpoint: `/api/v1/transactions`
  - Expected: List with date, type, amount, status

- [ ] **TC-058:** Filter transactions by type
  - Types: `pix_donation`, `subscription_payment`
  - Expected: Filtered list

- [ ] **TC-059:** Filter transactions by date range
  - Range: Last 30 days
  - Expected: Only transactions within range

- [ ] **TC-060:** Search transactions by ID
  - Expected: Direct access to transaction details

#### 5.2 Transaction Details
- [ ] **TC-061:** View PIX donation details
  - Expected: Amount, recipient, QR code, receipt link

- [ ] **TC-062:** View subscription payment details
  - Expected: Plan name, period, Stripe invoice link

- [ ] **TC-063:** Export financial history (CSV)
  - Expected: CSV download with all transactions

---

### 6️⃣ **Support Tickets**

#### 6.1 Create Ticket
- [ ] **TC-064:** Create new support ticket
  - Subject: "Problema com login"
  - Description: "Não consigo acessar minha conta"
  - Expected: Ticket created, status = 'open'

- [ ] **TC-065:** Create ticket with attachment
  - File: screenshot.png (2MB)
  - Expected: File uploaded, accessible in ticket

- [ ] **TC-066:** Create ticket without attachment
  - Expected: Ticket created successfully

#### 6.2 View Tickets
- [ ] **TC-067:** View all user tickets
  - Endpoint: `/api/v1/support/tickets`
  - Expected: List with status, subject, created_at

- [ ] **TC-068:** View ticket details
  - Expected: Full conversation thread, attachments

- [ ] **TC-069:** Filter tickets by status
  - Status: `open`, `in_progress`, `closed`
  - Expected: Filtered list

#### 6.3 Ticket Responses
- [ ] **TC-070:** User adds response to ticket
  - Expected: Message added, status updated to 'waiting_admin'

- [ ] **TC-071:** Admin responds to ticket
  - Expected: User notified via email

- [ ] **TC-072:** Close ticket (user)
  - Expected: Status = 'closed', no further responses allowed

- [ ] **TC-073:** Reopen closed ticket
  - Expected: Status = 'open', user can add messages

---

## 🔒 **Security & Performance Tests**

### 7️⃣ Security Headers
- [ ] **TC-074:** Verify CSP header on all pages
  - Expected: `Content-Security-Policy` present

- [ ] **TC-075:** Verify CSP nonce rotation
  - Expected: Different nonce per request

- [ ] **TC-076:** Verify HSTS header
  - Expected: `Strict-Transport-Security: max-age=31536000`

- [ ] **TC-077:** Verify X-Frame-Options
  - Expected: `X-Frame-Options: DENY`

- [ ] **TC-078:** Verify X-Content-Type-Options
  - Expected: `X-Content-Type-Options: nosniff`

### 8️⃣ Rate Limiting
- [ ] **TC-079:** Test login rate limiting
  - Expected: Max 5 attempts per minute per IP

- [ ] **TC-080:** Test API rate limiting
  - Expected: Max 60 requests per minute per user

- [ ] **TC-081:** Test password reset rate limiting
  - Expected: Max 1 request per minute per email

### 9️⃣ Database Performance
- [ ] **TC-082:** Test subscription query with index
  - Index: `idx_subscriptions_status_valid`
  - Expected: < 50ms

- [ ] **TC-083:** Test progress query with index
  - Index: `idx_progress_user_completed`
  - Expected: < 100ms

---

## 🏢 **Admin Dashboard Tests**

### 10️⃣ Admin Features
- [ ] **TC-084:** Admin login with admin credentials
  - Email: `joao@example.com` (if admin)
  - Expected: Access to `/admin` routes

- [ ] **TC-085:** Non-admin access to admin routes
  - Expected: 403 Forbidden

- [ ] **TC-086:** View all users (admin)
  - Expected: Paginated list with 31 users

- [ ] **TC-087:** View user details (admin)
  - Expected: Full profile, subscription, transactions

- [ ] **TC-088:** Suspend user account (admin)
  - Expected: User locked out, cannot login

- [ ] **TC-089:** View all courses (admin)
  - Expected: Course list with edit/delete actions

- [ ] **TC-090:** Create new course (admin)
  - Expected: Course created, available to subscribers

- [ ] **TC-091:** Edit course content (admin)
  - Expected: Changes saved, reflected on frontend

- [ ] **TC-092:** Delete course (admin)
  - Expected: Course soft-deleted, not visible to users

- [ ] **TC-093:** View subscription statistics (admin)
  - Expected: Active, paused, cancelled counts

- [ ] **TC-094:** View revenue dashboard (admin)
  - Expected: Total revenue, growth chart

- [ ] **TC-095:** Process pending PIX donations (admin)
  - Expected: Bulk confirm/reject actions

- [ ] **TC-096:** Respond to support tickets (admin)
  - Expected: Message sent, user notified

---

## 🐛 **Known Issues to Test**

### Critical Business Rule Violations
- [ ] **TC-097:** PIX email mismatch (CRITICAL BUG)
  - User email: `joao@example.com`
  - PIX key: `outro@example.com`
  - Current: ❌ ALLOWED
  - Expected: ❌ SHOULD REJECT

- [ ] **TC-098:** Mock login button in production
  - Environment: `NEXT_PUBLIC_NODE_ENV=production`
  - Current: ✅ Hidden (working correctly)
  - Expected: ✅ Not rendered

- [ ] **TC-099:** Debug console.log in production
  - Current: ⚠️ Present (line 70, login-container.tsx)
  - Expected: Should be removed

---

## 📊 **Test Execution Plan**

### Phase 1: Critical Flows (Priority 1) - 30 tests
- Authentication (TC-001 to TC-016)
- Subscription (TC-017 to TC-030)

### Phase 2: Core Features (Priority 2) - 35 tests
- Courses (TC-031 to TC-046)
- PIX Donations (TC-047 to TC-056)
- Financial History (TC-057 to TC-063)

### Phase 3: Support & Admin (Priority 3) - 37 tests
- Support Tickets (TC-064 to TC-073)
- Security (TC-074 to TC-083)
- Admin Dashboard (TC-084 to TC-096)

### Phase 4: Bug Verification (Priority 4) - 3 tests
- Known Issues (TC-097 to TC-099)

**Total Test Cases:** 99

---

## 🛠️ **MCP Testing Strategy**

### Using MCP Chrome DevTools:

1. **Navigation Tests:**
   ```javascript
   mcp__chrome-devtools__navigate_page({ url: "https://matrix.mutuapix.com/login" })
   ```

2. **Form Interaction:**
   ```javascript
   mcp__chrome-devtools__fill({ uid: "email_field", value: "joao@example.com" })
   mcp__chrome-devtools__click({ uid: "submit_button" })
   ```

3. **Network Monitoring:**
   ```javascript
   mcp__chrome-devtools__list_network_requests()
   mcp__chrome-devtools__get_network_request({ url: "/api/v1/login" })
   ```

4. **Console Verification:**
   ```javascript
   mcp__chrome-devtools__list_console_messages()
   ```

5. **Screenshot Evidence:**
   ```javascript
   mcp__chrome-devtools__take_screenshot({ format: "png" })
   ```

---

## 📝 **Test Report Template**

For each test case, document:

```markdown
### TC-XXX: [Test Name]

**Status:** ✅ PASS | ❌ FAIL | ⚠️ PARTIAL

**Steps:**
1. Navigate to [URL]
2. Fill [field] with [value]
3. Click [button]

**Expected Result:**
[Description]

**Actual Result:**
[What actually happened]

**Evidence:**
- Screenshot: [filename]
- Network request: [status code, response]
- Console: [errors/warnings]

**Notes:**
[Any additional observations]
```

---

## 🎯 **Success Criteria**

**MVP is ready for production if:**
- ✅ 95%+ test cases passing (94/99)
- ✅ All Priority 1 tests passing (30/30)
- ✅ No critical security issues
- ✅ PIX email validation bug fixed (TC-097)
- ✅ All admin features functional
- ✅ Performance within SLA (queries < 100ms)

---

**Test Plan Created:** 2025-10-17 21:20 BRT
**Ready for Execution:** ✅ YES
**Estimated Time:** 6-8 hours (full suite)
**Can be Automated:** ✅ YES (via MCP)

