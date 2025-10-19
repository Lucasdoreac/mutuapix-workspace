# 🔴 PIX Payment Fixes - TODO for PR #17

**Created:** 2025-10-10
**Status:** ⏳ Aguardando merge de PR #17 (PIX Payment System)
**Priority:** P0 - CRITICAL SECURITY

---

## ✅ Fixes Already Applied (Available Now)

### 1. PaymentTransaction Model Created
**File:** `app/Models/PaymentTransaction.php`
**Migration:** `database/migrations/2025_01_20_000008_create_payment_transactions_table.php`

**What was done:**
- Created complete PaymentTransaction model with all constants
- Added methods: markAsCompleted(), markAsFailed(), markAsRefunded()
- Added scopes: pix(), completed(), pending()
- Added relationships: user(), subscription(), donation()
- Migration with all PIX fields (pix_key, pix_qr_code, pix_copy_paste)

**Impact:**
- ✅ PaymentGatewayFactory now works (no more "class not found")
- ✅ PIX payment creation won't crash
- ✅ All payment methods (PIX, credit card, boleto) can use same table

---

### 2. Webhook Signature Validation Middleware
**File:** `app/Http/Middleware/VerifyPixWebhook.php`
**Registered:** `bootstrap/app.php` (alias: `verify.pix.webhook`)

**What was done:**
- HMAC-SHA256 signature verification
- Timing-safe comparison (hash_equals)
- Comprehensive logging (security audit trail)
- Support for multiple header names (X-PIX-Signature, X-Webhook-Signature)

**Configuration:**
- Added `PIX_WEBHOOK_SECRET` to `config/services.php`
- Consolidated PIX config (removed duplication)

**Impact:**
- ✅ Prevents webhook forgery/fraud
- ✅ Validates all incoming PIX webhooks
- ✅ Logs security events

---

## ⏳ Fixes Pending (Apply When PR #17 Merges)

### 3. Remove Mock PIX Verification

**Current Issue (from audit):**
```php
// routes/api/mutuapix.php:298 (or similar)
// ❌ MOCK CODE - Always returns "paid"
if ($pixVerification === 'mock') {
    return response()->json(['status' => 'paid']);
}
```

**Action Required:**
1. Locate mock PIX verification code in PR #17
2. Remove ALL mock verification logic
3. Implement real PIX API verification via payment provider
4. Add error handling for verification failures

**Priority:** 🔴 CRITICAL - Don't deploy to production with mock code

---

### 4. Add Webhook Signature to Routes

**Action Required:**
When PR #17 routes are merged, add middleware to webhook endpoint:

```php
// routes/api/mutuapix.php (or wherever PIX webhook is)
Route::post('/webhooks/pix', [PixWebhookController::class, 'handle'])
    ->middleware(['verify.pix.webhook'])  // ← ADD THIS
    ->withoutMiddleware(['throttle:api']);
```

**Test:**
```bash
# Should REJECT (no signature)
curl -X POST https://api.mutuapix.com/webhooks/pix \
  -H "Content-Type: application/json" \
  -d '{"status":"paid"}'
# Expected: 401 Unauthorized

# Should ACCEPT (valid signature)
SIGNATURE=$(echo -n '{"status":"paid"}' | openssl dgst -sha256 -hmac "YOUR_SECRET" | awk '{print $2}')
curl -X POST https://api.mutuapix.com/webhooks/pix \
  -H "Content-Type: application/json" \
  -H "X-PIX-Signature: $SIGNATURE" \
  -d '{"status":"paid"}'
# Expected: 200 OK
```

---

### 5. Add Transaction Locks (Race Condition Fix)

**Current Issue:**
Concurrent webhook/confirmation requests can cause duplicate processing.

**Action Required:**
Find donation confirmation code and add database lock:

```php
// In DonationController or DonationService
use Illuminate\Support\Facades\DB;

public function confirmDonation($donationId)
{
    return DB::transaction(function () use ($donationId) {
        // ✅ Lock prevents race condition
        $donation = Donation::where('id', $donationId)
            ->lockForUpdate()  // ← ADD THIS
            ->firstOrFail();

        // Check if already confirmed
        if ($donation->status === 'confirmed') {
            return response()->json([
                'message' => 'Donation already confirmed'
            ], 400);
        }

        // Mark as confirmed
        $donation->update([
            'status' => 'confirmed',
            'confirmed_at' => now(),
        ]);

        // Process payment, points, notifications, etc.
        // ...

        return $donation;
    });
}
```

**Where to Apply:**
- DonationController::confirmDonation()
- Any webhook handler that updates donation status
- Any code that processes payment confirmations

**Test:**
```bash
# Send 10 concurrent confirmation requests
for i in {1..10}; do
  curl -X POST http://localhost:8000/api/donations/123/confirm &
done
wait

# Should result in:
# - 1 success (200)
# - 9 "already confirmed" (400)
# - NOT 10 successes (that would be race condition)
```

---

### 6. Implement Real PIX Provider Integration

**Current Gap:** No actual PIX provider configured.

**Action Required:**
Choose and implement a PIX provider:

**Option A: Pagar.me PIX**
```php
// PagarmeService.php
public function generatePixQrCode($amount, $orderId)
{
    $response = Http::withToken(config('services.pagarme.api_key'))
        ->post(config('services.pagarme.base_url').'/orders', [
            'amount' => $amount * 100, // cents
            'payment_method' => 'pix',
            'items' => [/* ... */],
        ]);

    return [
        'qr_code' => $response['charges'][0]['last_transaction']['qr_code'],
        'qr_code_url' => $response['charges'][0]['last_transaction']['qr_code_url'],
        'expires_at' => $response['charges'][0]['last_transaction']['expires_at'],
    ];
}
```

**Option B: Gerencianet (Efí Bank)**
```php
// GerencianetService.php
public function generatePixQrCode($amount, $orderId)
{
    $response = Http::withToken($this->getAccessToken())
        ->post('https://api-pix.gerencianet.com.br/v2/cob', [
            'calendario' => ['expiracao' => 3600],
            'valor' => ['original' => number_format($amount, 2, '.', '')],
            'chave' => config('services.gerencianet.pix_key'),
        ]);

    return [
        'qr_code' => $response['pixCopiaECola'],
        'txid' => $response['txid'],
        'location' => $response['location'],
    ];
}
```

**Configuration Needed:**
```env
# .env
PIX_PROVIDER=pagarme  # or gerencianet, mercadopago, etc
PIX_WEBHOOK_SECRET=your-random-secret-here

# If using Gerencianet:
GERENCIANET_CLIENT_ID=xxx
GERENCIANET_CLIENT_SECRET=xxx
GERENCIANET_PIX_KEY=your-pix-key@email.com
GERENCIANET_WEBHOOK_SECRET=xxx

# If using Pagar.me PIX:
# (already configured, just ensure PIX is enabled)
```

---

## 🚨 URGENT: Legal Risk Assessment

### MutuaPIX Structure Analysis

**⚠️ LEGAL WARNING:** Based on code analysis, MutuaPIX has characteristics typical of pyramid/Ponzi schemes:

1. ✅ **Entry Payment Required** - Users pay to enter
2. ✅ **Revenue from New Entrants** - User receives from next user's payment
3. ✅ **Multiple Levels** - DonationLevel model with progression
4. ✅ **Recruitment Incentive** - Progress requires bringing new users
5. ✅ **Re-entry Cycle** - Users can re-enter multiple times

**Applicable Law:**
- Lei 1.521/1951 - Crimes contra economia popular
- Regulamentação CVM (securities)
- Regulamentação Banco Central (financial pyramid)

**MANDATORY ACTION:**
🔴 **CONSULT LAWYER BEFORE DEPLOYING PR #17**

Do NOT deploy PIX payment system until:
1. Lawyer confirms MutuaPIX structure is legal
2. If illegal, restructure the business model
3. If legal, get written legal opinion for liability protection

**Potential Consequences:**
- Criminal charges (Lei 1.521/1951)
- Company shutdown by authorities
- Fines and asset seizure
- Personal liability for directors

---

## ✅ Checklist Before Deploying PR #17

### Code Quality
- [ ] PaymentTransaction model in place ✅ (already done)
- [ ] Webhook signature validation middleware ✅ (already done)
- [ ] Mock PIX verification removed
- [ ] Real PIX provider integrated
- [ ] Transaction locks added
- [ ] All tests passing (not skipped)

### Security
- [ ] Webhook signature tested (reject invalid)
- [ ] Race condition tested (concurrent confirmations)
- [ ] Amount validation (prevent negative/zero)
- [ ] PIX key validation
- [ ] Error messages sanitized (no sensitive data)

### Configuration
- [ ] `PIX_WEBHOOK_SECRET` set in production .env
- [ ] PIX provider credentials configured
- [ ] Webhook URL registered with provider
- [ ] HTTPS enforced (no HTTP webhooks)

### Legal
- [ ] 🔴 **LAWYER CONSULTED ABOUT MUTUAPIX**
- [ ] Legal structure approved OR redesigned
- [ ] Terms of service updated
- [ ] User disclosures added (if required)

### Monitoring
- [ ] Webhook logging enabled
- [ ] Failed payment alerts configured
- [ ] Suspicious activity detection
- [ ] Daily reconciliation process

---

## 📞 Responsible Parties

**Technical Implementation:**
- PaymentTransaction: ✅ Complete
- Webhook Security: ✅ Complete
- PIX Integration: ⏳ Pending (assign to: _______)
- Testing: ⏳ Pending (assign to: _______)

**Legal Review:**
- Lawyer Contact: ⏳ Pending (assign to: CEO/Legal)
- Business Model Review: ⏳ Pending
- Compliance Check: ⏳ Pending

**Deployment:**
- Staging Deploy: ⏳ Pending (after code complete)
- Production Deploy: 🔴 **BLOCKED** (legal review required)

---

## 📚 Related Documents

1. `SECURITY_AUDIT_REPORT.md` - PR #17 section (10 critical issues)
2. `CRITICAL_FIXES_REQUIRED.md` - Section 3 (PIX fixes)
3. `EXECUTIVE_SUMMARY.md` - Legal risk section
4. This file - Implementation guide

---

**Status:** 2/6 fixes complete, 4 pending PR #17 merge
**Next Action:** Await PR #17 merge, then apply items 3-6
**Blocker:** Legal review required before production deploy

---

**Last Updated:** 2025-10-10
**Created by:** Claude Code Security Review
