# 🔦 Lighthouse CI Setup - MutuaPIX

**Created:** 2025-10-18 00:15 BRT
**Status:** ✅ CONFIGURED - Ready for GitHub Actions
**Purpose:** Automated performance regression testing

---

## 📋 Overview

Lighthouse CI automatically runs performance audits on every pull request and deployment, ensuring we catch performance regressions before they reach production.

**Benefits:**
- ✅ Automated performance testing
- ✅ Prevent performance regressions
- ✅ Track metrics over time
- ✅ Enforce performance budgets
- ✅ PR comments with results

---

## 🚀 Quick Start

### Local Testing

```bash
# Install Lighthouse CI globally
npm install -g @lhci/cli

# Run Lighthouse CI (uses lighthouserc.js config)
lhci autorun

# View results
open .lighthouseci/
```

### CI/CD Integration

**Already configured!** Lighthouse CI will run automatically on:
- Pull requests to `main` or `develop`
- Pushes to `main` or `develop`
- Manual workflow dispatch

---

## 📊 Performance Budgets

Our current budgets (defined in `lighthouserc.js`):

### Categories
| Category | Minimum Score | Status |
|----------|--------------|--------|
| Performance | 80% | ✅ Enforced |
| Accessibility | 90% | ✅ Enforced |
| Best Practices | 85% | ✅ Enforced |
| SEO | 90% | ✅ Enforced |

### Core Web Vitals
| Metric | Budget | Current Baseline |
|--------|--------|------------------|
| **LCP** (Largest Contentful Paint) | < 2.5s | TBD |
| **FCP** (First Contentful Paint) | < 2.0s | TBD |
| **CLS** (Cumulative Layout Shift) | < 0.1 | 0.00 ✅ |
| **TBT** (Total Blocking Time) | < 300ms | TBD |
| **Speed Index** | < 4.0s | TBD |

### Resource Budgets
| Resource | Budget |
|----------|--------|
| Total JavaScript | < 500 KB |
| Total CSS | < 100 KB |
| Total Images | < 500 KB |
| Total Fonts | < 200 KB |
| Script Requests | < 30 |
| CSS Requests | < 10 |

---

## 🗂️ Files Created

### 1. `lighthouserc.js`
**Location:** `frontend/lighthouserc.js`

**Purpose:** Lighthouse CI configuration file

**Key Settings:**
```javascript
{
  urls: ['https://matrix.mutuapix.com/login'],
  numberOfRuns: 3,  // Run 3 times, use median
  assertions: {
    'categories:performance': ['error', {minScore: 0.8}],
    'cumulative-layout-shift': ['error', {maxNumericValue: 0.1}],
    // ... more assertions
  }
}
```

### 2. `.github/workflows/lighthouse-ci.yml`
**Location:** `frontend/.github/workflows/lighthouse-ci.yml`

**Purpose:** GitHub Actions workflow for automated testing

**Triggers:**
- Pull requests (targeting main/develop)
- Push to main/develop
- Manual dispatch

**Steps:**
1. Checkout code
2. Setup Node.js
3. Install dependencies
4. Build application
5. Run Lighthouse CI
6. Upload results
7. Comment on PR with scores

---

## 🔧 Configuration Details

### URLs Tested

**Currently:**
- https://matrix.mutuapix.com/login (login page)
- https://matrix.mutuapix.com (home page)

**To add more URLs:**
```javascript
// lighthouserc.js
collect: {
  url: [
    'https://matrix.mutuapix.com/login',
    'https://matrix.mutuapix.com',
    'https://matrix.mutuapix.com/user/dashboard',  // Add new URL
  ],
}
```

### Test Conditions

**Device Emulation:**
- Form Factor: Mobile (most restrictive)
- Screen: 360x640 (typical mobile)

**Network Throttling:**
- RTT: 150ms
- Throughput: 1.6 Mbps (4G)
- CPU: 4x slowdown

**Why Mobile First?**
- Most users on mobile
- Stricter performance requirements
- If passes on mobile, will excel on desktop

---

## 📈 Reading Results

### Lighthouse CI Output

After running `lhci autorun`, you'll see:

```
✅ Checking assertions against 3 URL(s), 3 total run(s)

https://matrix.mutuapix.com/login
  Performance: 87 ✅
  Accessibility: 94 ✅
  Best Practices: 92 ✅
  SEO: 100 ✅

  largest-contentful-paint: 2.3s ✅
  cumulative-layout-shift: 0.00 ✅
  total-blocking-time: 250ms ✅

✅ Assertions passed!
```

### Understanding Scores

**Performance Score Breakdown:**
```
0-49:   🔴 Poor (immediate action needed)
50-89:  🟡 Needs Improvement
90-100: 🟢 Good
```

**Our Targets:**
- Performance: ≥ 80 (good for production app)
- Accessibility: ≥ 90 (WCAG compliance)
- Best Practices: ≥ 85 (industry standard)
- SEO: ≥ 90 (search visibility)

---

## 🚨 What Happens When Budget Fails

### CI/CD Failure

If any assertion fails, the GitHub Actions workflow will fail with:

```
❌ Assertion failed!

categories:performance expected: ≥ 0.8, actual: 0.75

largest-contentful-paint expected: ≤ 2500ms, actual: 3200ms
```

**This will:**
- ❌ Block PR merge (if branch protection enabled)
- 📧 Notify PR author
- 💬 Comment on PR with detailed results

### How to Fix

**Step 1: Identify the Issue**
```bash
# Run Lighthouse CI locally
lhci autorun

# Open detailed report
open .lighthouseci/*/lhr-*.html
```

**Step 2: Analyze Opportunities**
Look at Lighthouse recommendations:
- Eliminate render-blocking resources
- Reduce unused JavaScript
- Serve images in modern formats
- Minimize main-thread work
- etc.

**Step 3: Implement Fixes**
Common fixes:
- Code splitting (`dynamic import()`)
- Image optimization (Next.js Image component)
- Font optimization (font-display: swap)
- Remove unused dependencies

**Step 4: Re-test**
```bash
npm run build
lhci autorun
```

**Step 5: Commit and Push**
CI will re-run automatically on push.

---

## 🎯 Best Practices

### 1. Run Locally Before Push

```bash
# Always test locally first
npm run build
lhci autorun

# Fix issues before creating PR
```

### 2. Monitor Trends

**Track scores over time:**
- Baseline: Current performance
- Target: Maintain or improve
- Alert: If score drops > 5 points

### 3. Adjust Budgets Carefully

**Don't lower budgets to pass tests!**

❌ Bad:
```javascript
// Lowering budget because we can't meet it
'categories:performance': ['error', {minScore: 0.6}]  // Was 0.8
```

✅ Good:
```javascript
// Keep strict budget, fix performance issue
'categories:performance': ['error', {minScore: 0.8}]
// Then optimize code to meet budget
```

### 4. Use Warnings for Soft Limits

```javascript
// Error: Hard requirement (blocks PR)
'categories:performance': ['error', {minScore: 0.8}],

// Warning: Soft requirement (allows PR but notifies)
'total-blocking-time': ['warn', {maxNumericValue: 300}],
```

---

## 🔗 GitHub Actions Integration

### Required Secrets

**Optional (for PR comments):**
```
LHCI_GITHUB_APP_TOKEN
```

**To create:**
1. Go to: https://github.com/settings/tokens
2. Generate new token (classic)
3. Permissions: `repo`, `write:discussion`
4. Add to repository secrets: Settings → Secrets → Actions

**Without token:**
- CI still runs
- No PR comments
- Results in Actions logs only

### Viewing Results

**In GitHub Actions:**
1. Go to: Actions tab
2. Click on workflow run
3. Download `lighthouse-results` artifact
4. Extract and open HTML reports

**In PR comments (if token configured):**
- Automatic comment with score table
- Link to full report
- Comparison with previous results

---

## 📊 Advanced: LHCI Server (Optional)

**For tracking historical data:**

### Setup LHCI Server

```bash
# Install LHCI server
npm install -g @lhci/server

# Initialize database
lhci server --storage.storageMethod=sql --storage.sqlDatabasePath=./lhci-data.sql

# Start server
lhci server --port=9001
```

### Configure Upload

```javascript
// lighthouserc.js
upload: {
  target: 'lhci-server',
  serverBaseUrl: 'https://your-lhci-server.com',
  token: process.env.LHCI_TOKEN,
}
```

**Benefits:**
- Historical trend graphs
- Compare across branches
- Share reports with team
- API for custom dashboards

**Cost:** Self-hosted (free) or managed service

---

## 🛠️ Troubleshooting

### Build Fails in CI

**Error:** `npm run build` fails

**Fix:**
```yaml
# Ensure all env vars are set
env:
  NODE_ENV: production
  NEXT_PUBLIC_NODE_ENV: production
  NEXT_PUBLIC_API_URL: https://api.mutuapix.com
```

### Lighthouse Can't Access URL

**Error:** `ENOTFOUND matrix.mutuapix.com`

**Cause:** Testing staging/local URLs in CI

**Fix:** Only test production URLs in CI, or use temporary public URL

### Inconsistent Scores

**Scores vary ±5 points between runs**

**Cause:** Network variability, server load

**Fix:**
```javascript
// Increase number of runs
numberOfRuns: 5,  // Instead of 3

// Use stricter budgets
minScore: 0.85  // Instead of 0.8
```

---

## 📅 Maintenance

### Weekly
- [ ] Review Lighthouse scores in PRs
- [ ] Address any new warnings
- [ ] Update budgets if performance improves

### Monthly
- [ ] Review trend data (if using LHCI server)
- [ ] Adjust budgets based on improvements
- [ ] Update assertions for new metrics

### Quarterly
- [ ] Audit all resource budgets
- [ ] Review accessibility compliance
- [ ] Update to latest Lighthouse version

---

## ✅ Next Steps

### Immediate
1. ✅ Configuration files created
2. ✅ GitHub workflow ready
3. ⏳ Test locally: `lhci autorun`
4. ⏳ Create PR to test automation
5. ⏳ Optional: Setup LHCI server

### This Week
- [ ] Run baseline audit on all pages
- [ ] Document current scores
- [ ] Create performance optimization backlog
- [ ] Set up monitoring dashboard

### This Month
- [ ] Optimize LCP (if > 2.5s)
- [ ] Optimize TBT (if > 300ms)
- [ ] Fix accessibility issues (if any)
- [ ] Implement image optimization

---

## 📚 Resources

**Official Docs:**
- Lighthouse CI: https://github.com/GoogleChrome/lighthouse-ci
- Lighthouse Docs: https://developers.google.com/web/tools/lighthouse
- Core Web Vitals: https://web.dev/vitals/

**Tutorials:**
- Performance Budgets: https://web.dev/performance-budgets-101/
- Lighthouse CI Setup: https://web.dev/lighthouse-ci/
- GitHub Actions: https://docs.github.com/en/actions

**Tools:**
- WebPageTest: https://webpagetest.org/
- PageSpeed Insights: https://pagespeed.web.dev/
- Chrome DevTools: Built-in browser tools

---

**Configuration Status:** ✅ COMPLETE
**Files Created:** 3 (lighthouserc.js, workflow, this doc)
**Next Action:** Test locally with `lhci autorun`
**Estimated Setup Time:** 20 minutes ✅ DONE

🎯 **Lighthouse CI is now ready to prevent performance regressions!**
