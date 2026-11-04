## Development principles

### 1. Think before coding
Don't assume. Don't hide confusion. Surface tradeoffs.
- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them; don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.

### 2. Simplicity first
Minimum code that solves the problem. Nothing speculative.
- No features, abstractions, or configurability beyond what was asked.
- No error handling for impossible scenarios.
- If 200 lines could be 50, rewrite it. Would a senior engineer call this overcomplicated?

### 3. Surgical changes
Touch only what you must. Clean up only your own mess.
- Don't "improve" adjacent code, comments, or formatting; match existing style.
- Don't refactor what isn't broken. Mention unrelated dead code; don't delete it.
- Remove imports/variables/functions that your change made unused.
- Every changed line should trace directly to the request.

### 4. Goal-driven execution
Define success criteria. Loop until verified.
- "Add validation" -> write tests for invalid inputs, then make them pass.
- "Fix the bug" -> write a test that reproduces it, then make it pass.
- "Refactor X" -> tests pass before and after.
- For multi-step tasks, state a brief plan: `1. [step] -> verify: [check]`.

### Always
- Never commit secrets; validate input at system boundaries.
- Report outcomes honestly: state what was verified and what was not.
