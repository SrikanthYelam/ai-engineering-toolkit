---
name: sync-docs
description: Update README.md, CLAUDE.md, and AGENTS.md so they match a code change, such as a new feature, endpoint, component, config setting, or command. Use after implementing a change, or when asked to update or sync the docs.
---

# sync-docs

1. Identify what changed: `git diff` (plus `git diff --staged`) or the files named by the user.
2. Find the docs that describe the changed area: `README.md`, `CLAUDE.md`/`AGENTS.md` (including nested ones), and `docs/`. Search them for the names of the changed types, routes, settings, and commands.
3. Update only what the change made inaccurate or incomplete:
   - lists and counts of features, endpoints, routes, or components
   - architecture notes, such as new types, where they live, and which existing pattern they follow
   - commands, configuration keys, environment variables, and ports
4. Match each document's existing structure, tone, and level of detail. Add entries next to similar ones instead of creating new sections.
5. Don't rewrite unrelated sections or fix unrelated wording.
6. Check that every path, command, and name you wrote exists in the code.
7. Report which files and sections changed, and anything you found outdated but left alone.
