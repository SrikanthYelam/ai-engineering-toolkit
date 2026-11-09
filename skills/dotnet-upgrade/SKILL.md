---
name: dotnet-upgrade
description: Migrate a .NET solution to a newer .NET version (for example net8.0 to net10.0), covering target frameworks, framework-versioned packages, Docker images, CI, deprecation warnings, and docs, then verify that it builds, tests, and runs. Use when asked to upgrade, migrate, or retarget a .NET or ASP.NET Core project or solution to a new .NET version.
---

# dotnet-upgrade

1. **Check the toolchain.** Run `dotnet --list-sdks` and `dotnet --list-runtimes`. If the target SDK is not installed, stop and say so. Do not retarget to an SDK that cannot build the result.
2. **Inventory every version pin.** Look in `*.csproj`, `Directory.Build.props`, `Directory.Packages.props`, `global.json`, Dockerfiles (`mcr.microsoft.com/dotnet/<image>:X.Y`), CI files (`setup-dotnet`, `dotnet-version`), `.devcontainer/`, and docs (`README.md`, `CLAUDE.md`, `AGENTS.md`). Search for `netX.0`, `.NET X`, and `X.0.` patch versions.
3. **Record a baseline.** Run `dotnet build --nologo` and `dotnet test --nologo` on the current version, and write down the warning count and test totals. If the tests cannot run because the old runtime is missing (runtimes do not roll forward across major versions by default), say so. The first post-upgrade run then becomes the baseline.
4. **Retarget.**
   - Change `TargetFramework` everywhere. For `TargetFrameworks` (multi-targeting), ask whether to add the new version or replace the old one.
   - Bump only packages whose major version follows the framework, to the latest patch of the new major. Examples: `Microsoft.AspNetCore.*`, `Microsoft.EntityFrameworkCore.*`, `Microsoft.Extensions.*` pinned to the old major, and the `dotnet-ef` tool. Look up versions with `dotnet package search <id> --exact-match`. Leave independently versioned packages alone (xunit, Swashbuckle, OpenAI, `Microsoft.Extensions.AI`, and so on) unless they break. Report which of them could be bumped later.
   - Update Docker base images, the `global.json` `sdk.version`, and CI SDK versions.
5. **Build, and treat new warnings as part of the migration.** Fix obsoletions (`ASPDEPR*`, `SYSLIB*`, `CS0618`) by moving to the replacement API, not with `NoWarn`. If a call only exists to feed a package that is now unused, remove both the call and the package reference.
6. **Test.** Run the full suite and compare it with the baseline. Fix causes, not tests (see `dotnet-verify`).
7. **Run the app.** Some failures only appear at runtime, such as `TypeLoadException`/`MissingMethodException` between transitive package versions. Start it (stop any stale instance first, because Windows locks the exe) and request a health route, `swagger/v1/swagger.json` or `/openapi/v1.json`, and one representative endpoint. Exercise anything that compiles or loads code at runtime (Roslyn scripting, plugins, reflection).
8. **Build the container**, if Docker is available, and confirm the runtime version inside it with `docker run --rm --entrypoint dotnet <image> --list-runtimes`.
9. **Update the docs** that state the version: prerequisites, tech stack lists, notes about the old version, and to-do items the upgrade completes.
10. **Report** the files changed, the packages bumped and why, the deprecations fixed, verification results (build warnings, test counts, runtime checks, Docker), and anything left for later.

## Known issues by target version

### .NET 10
- `WithOpenApi()` on minimal-API endpoints is obsolete (ASPDEPR002). Remove it. Endpoint metadata still reaches Swashbuckle through ApiExplorer, and it reaches the built-in `AddOpenApi()` without it.
- `ForwardedHeadersOptions.KnownNetworks` is obsolete (ASPDEPR005). Use `KnownIPNetworks`.
- `Microsoft.AspNetCore.OpenApi` 10.x brings in Microsoft.OpenApi 2.x, and Swashbuckle versions before 10 are built on Microsoft.OpenApi 1.x. Pick one fix:
  - drop `Microsoft.AspNetCore.OpenApi` if only Swashbuckle uses it (often its only use is `WithOpenApi()`)
  - upgrade Swashbuckle to 10.x (custom filters move from `Microsoft.OpenApi.Models` to `Microsoft.OpenApi`)
  - switch to the built-in `AddOpenApi()`/`MapOpenApi()`

  Whichever you choose, confirm that `swagger.json` loads at runtime.

Add a section here whenever a migration turns up something new.
