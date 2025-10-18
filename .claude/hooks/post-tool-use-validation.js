/**
 * Post-Tool-Use Validation Hook
 *
 * Automatically validates code changes after Edit/Write/MultiEdit operations.
 * Implements the "Conscious Execution" skill framework.
 *
 * Validation steps:
 * 1. Linting (auto-fix if possible)
 * 2. Type checking (TypeScript)
 * 3. Formatting (Prettier)
 * 4. Test execution (if test file modified)
 * 5. Security checks (sensitive files)
 *
 * @param {Object} params
 * @param {string} params.toolName - Name of the tool that was called
 * @param {Object} params.toolInput - Input parameters passed to the tool
 * @param {Object} params.result - Result returned by the tool
 * @param {Object} params.env - Environment utilities (bash, read, etc.)
 */
export default async function hook({ toolName, toolInput, result, env }) {
  // Only run on code editing tools
  if (!['Edit', 'Write', 'MultiEdit'].includes(toolName)) {
    return;
  }

  const filePath = toolInput.file_path || toolInput.path;

  // Skip validation for non-code files
  if (!filePath) {
    return;
  }

  const isTypeScript = filePath.endsWith('.ts') || filePath.endsWith('.tsx');
  const isJavaScript = filePath.endsWith('.js') || filePath.endsWith('.jsx');
  const isPHP = filePath.endsWith('.php');
  const isTestFile = filePath.includes('.test.') || filePath.includes('.spec.');

  // Determine project type
  const isFrontend = filePath.includes('/frontend/');
  const isBackend = filePath.includes('/backend/');

  console.log(`🔍 Post-validation for: ${filePath}`);

  // =============================================================================
  // 1. LINTING
  // =============================================================================

  if (isTypeScript || isJavaScript) {
    console.log('  → Running ESLint...');

    const lintResult = await env.bash({
      command: `cd ${isFrontend ? 'frontend' : '.'} && npx eslint "${filePath}" --fix`,
      cwd: '/Users/lucascardoso/Desktop/MUTUA'
    });

    if (lintResult.exitCode !== 0) {
      return {
        message: `⚠️ ESLint issues in ${filePath}:\n${lintResult.stderr}\n\nRun: npx eslint "${filePath}" --fix`,
        blocking: false  // Warning, not blocking
      };
    }
    console.log('  ✅ ESLint passed');
  }

  if (isPHP && isBackend) {
    console.log('  → Running Pint (PHP formatter)...');

    const pintResult = await env.bash({
      command: `cd backend && ./vendor/bin/pint "${filePath}"`,
      cwd: '/Users/lucascardoso/Desktop/MUTUA'
    });

    if (pintResult.exitCode !== 0) {
      return {
        message: `⚠️ Pint formatting issues in ${filePath}:\n${pintResult.stderr}`,
        blocking: false
      };
    }
    console.log('  ✅ Pint passed');
  }

  // =============================================================================
  // 2. TYPE CHECKING (TypeScript only)
  // =============================================================================

  if (isTypeScript) {
    console.log('  → Running TypeScript type check...');

    const typeCheckResult = await env.bash({
      command: `cd frontend && npx tsc --noEmit --skipLibCheck`,
      cwd: '/Users/lucascardoso/Desktop/MUTUA'
    });

    if (typeCheckResult.exitCode !== 0) {
      // Extract relevant errors for the modified file
      const errors = typeCheckResult.stderr
        .split('\n')
        .filter(line => line.includes(filePath))
        .join('\n');

      if (errors) {
        return {
          message: `🔴 TypeScript errors in ${filePath}:\n${errors}\n\nFix these type errors before deployment.`,
          blocking: true  // Block deployment with type errors
        };
      }
    }
    console.log('  ✅ Type check passed');
  }

  // =============================================================================
  // 3. FORMATTING (Auto-fix)
  // =============================================================================

  if (isTypeScript || isJavaScript) {
    console.log('  → Running Prettier...');

    await env.bash({
      command: `cd frontend && npx prettier --write "${filePath}"`,
      cwd: '/Users/lucascardoso/Desktop/MUTUA'
    });

    console.log('  ✅ Prettier formatting applied');
  }

  // =============================================================================
  // 4. TEST EXECUTION (if test file modified)
  // =============================================================================

  if (isTestFile) {
    console.log('  → Running tests...');

    let testCommand;
    if (isFrontend) {
      testCommand = `cd frontend && npm test -- "${filePath}"`;
    } else if (isBackend) {
      testCommand = `cd backend && php artisan test --filter="${filePath}"`;
    }

    if (testCommand) {
      const testResult = await env.bash({
        command: testCommand,
        cwd: '/Users/lucascardoso/Desktop/MUTUA'
      });

      if (testResult.exitCode !== 0) {
        return {
          message: `❌ Tests failed for ${filePath}:\n${testResult.stderr}\n\nFix failing tests before deployment.`,
          blocking: true  // Block if tests fail
        };
      }
      console.log('  ✅ Tests passed');
    }
  }

  // =============================================================================
  // 5. SECURITY CHECKS (Sensitive files)
  // =============================================================================

  const sensitivePatterns = [
    '.env',
    'password',
    'secret',
    'key',
    'token',
    'credential',
    'api_key',
    'private'
  ];

  const isSensitive = sensitivePatterns.some(pattern =>
    filePath.toLowerCase().includes(pattern)
  );

  if (isSensitive) {
    console.log('  ⚠️  Sensitive file detected');

    return {
      message: `🔐 WARNING: Modified sensitive file: ${filePath}

Security checklist:
- [ ] Ensure no secrets are hardcoded
- [ ] Verify file is in .gitignore (if contains secrets)
- [ ] Check if secrets should be in environment variables
- [ ] Confirm no secrets will be committed to git

Run: git status | grep "${filePath}"`,
      blocking: false  // Warning, not blocking
    };
  }

  // =============================================================================
  // 6. STATIC ANALYSIS (Backend only)
  // =============================================================================

  if (isPHP && isBackend) {
    console.log('  → Running PHPStan static analysis...');

    const phpstanResult = await env.bash({
      command: `cd backend && ./vendor/bin/phpstan analyse "${filePath}" --level=5`,
      cwd: '/Users/lucascardoso/Desktop/MUTUA'
    });

    if (phpstanResult.exitCode !== 0) {
      return {
        message: `⚠️ PHPStan warnings in ${filePath}:\n${phpstanResult.stderr}\n\nConsider fixing these issues.`,
        blocking: false  // Warning, not blocking
      };
    }
    console.log('  ✅ PHPStan passed');
  }

  // =============================================================================
  // ALL CHECKS PASSED
  // =============================================================================

  console.log(`✅ All validation checks passed for ${filePath}`);

  return {
    message: `✅ Validation completed for ${filePath}

Checks performed:
${isTypeScript || isJavaScript ? '- ✅ ESLint' : ''}
${isTypeScript ? '- ✅ TypeScript type check' : ''}
${isTypeScript || isJavaScript ? '- ✅ Prettier formatting' : ''}
${isPHP && isBackend ? '- ✅ Pint formatting' : ''}
${isPHP && isBackend ? '- ✅ PHPStan static analysis' : ''}
${isTestFile ? '- ✅ Tests executed' : ''}
${isSensitive ? '- ⚠️  Sensitive file check' : ''}

File is ready for deployment.`,
    blocking: false
  };
}
