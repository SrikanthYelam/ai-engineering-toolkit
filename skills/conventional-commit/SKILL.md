---
name: conventional-commit
description: Write a Conventional Commits message from the staged changes. Use when asked to commit, write a commit message, or summarize staged work.
---

# conventional-commit

1. Inspect the change with `git diff --staged` (and `git log -5 --oneline` to match repo style).
2. Write the message as `type(scope): summary`.
   - Types: `feat`, `fix`, `refactor`, `perf`, `test`, `docs`, `build`, `ci`, `chore`.
   - Summary: imperative mood, lowercase, no trailing period, 72 characters or fewer.
   - `scope` is optional; use the module or project name.
3. Add a body only when the *why* is not obvious from the diff. Wrap at 72 columns.
4. Mark breaking changes with `!` after the type/scope and a `BREAKING CHANGE:` footer.
5. If the staged changes mix unrelated concerns, suggest splitting them rather than writing one vague message.
