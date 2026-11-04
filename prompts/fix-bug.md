---
description: Reproduce a bug with a failing test, fix the root cause, and verify
---

Fix this bug: {{input}}

1. **Understand** - Restate the expected and actual behavior. If the report is ambiguous, ask before changing code.
2. **Reproduce** - Write the smallest automated test that fails because of this bug. Run it and confirm that it fails for the reported reason. If you cannot reproduce the bug, stop and report what you tried.
3. **Diagnose** - Find the root cause, not just the line where the symptom appears. Explain it in one or two sentences.
4. **Fix** - Make the minimal change that addresses the cause. Do not refactor surrounding code.
5. **Verify** - Run the new test (now passing) and the full test suite. Check for the same mistake elsewhere and mention any other occurrences instead of fixing them silently.
6. **Report** - Give the root cause, the fix, the test added, and what was verified.
