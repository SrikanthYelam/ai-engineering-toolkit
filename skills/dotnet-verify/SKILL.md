---
name: dotnet-verify
description: Build and test a .NET solution, then diagnose and summarize failures. Use after changing C# code, or when asked to verify, build, or run tests for a .NET project.
---

# dotnet-verify

1. Locate the entry point: a `.sln`/`.slnx` at the repo root, else the nearest `.csproj` to the changed files.
2. Run `dotnet build --nologo` on it. Fix compile errors first; treat new warnings as defects.
3. Run `dotnet test --no-build --nologo`. For a focused run, add `--filter "FullyQualifiedName~<Name>"`.
4. On failure, read the first failing test's message and stack trace, find the cause in the code under test, and fix that. Do not weaken or delete the test to make it pass.
5. Re-run until green, then report: commands run, pass/fail counts, and anything not verified.

Notes:
- Run the full suite once before finishing, even if you iterated with filters.
- If `dotnet` is unavailable or restore fails offline, say so instead of guessing.
