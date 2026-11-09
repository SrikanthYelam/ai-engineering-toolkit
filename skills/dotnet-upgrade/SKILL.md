---
name: dotnet-upgrade
description: Migrate a .NET solution to a newer .NET version (for example net8.0 to net10.0), covering target frameworks, framework-versioned packages, Docker images, CI, deprecation warnings, and docs, then verify that it builds, tests, and runs. Use when asked to upgrade, migrate, or retarget a .NET or ASP.NET Core project or solution to a new .NET version.
---

# dotnet-upgrade

1. **Check the toolchain.** Run `dotnet --list-sdks` and `dotnet --list-runtimes`. If the target SDK is not installed, stop and say so. Do not retarget to an SDK that cannot build the result.
2. **Inventory every version pin.** Look in `*.csproj`, `Directory.Build.props`, `Directory.Packages.props`, `global.json`, Dockerfiles (`mcr.microsoft.com/dotnet/<image>:X.Y`), CI files (`setup-dotnet`, `dotnet-version`), `.devcontainer/`, and docs (`README.md`, `CLAUDE.md`, `AGENTS.md`). Search for `netX.0`, `.NET X`, and `X.0.` patch versions, including wildcards such as `Version="9.0.*"`.
3. **Record a baseline.** Run `dotnet build --nologo` and `dotnet test --nologo` on the current version, and write down the warning count and test totals. If the tests cannot run because the old runtime is missing (runtimes do not roll forward across major versions by default), say so. The first post-upgrade run then becomes the baseline. A `global.json` that pins the old SDK (`rollForward` does not cross major versions) also stops `dotnet build` with "SDK not found" when only the new SDK is installed. Treat that as the same situation.
4. **Retarget.**
   - Change `TargetFramework` everywhere. For `TargetFrameworks` (multi-targeting), ask whether to add the new version or replace the old one.
   - Bump only packages whose major version follows the framework, to the latest patch of the new major. Examples: `Microsoft.AspNetCore.*`, `Microsoft.EntityFrameworkCore.*`, `Microsoft.Extensions.*` pinned to the old major, and the `dotnet-ef` tool. Look up versions with `dotnet package search <id> --exact-match`. Leave independently versioned packages alone (xunit, Swashbuckle, OpenAI, `Microsoft.Extensions.AI`, and so on) unless they break. Report which of them could be bumped later.
   - Remove explicit `PackageReference`s that the new framework now includes (build warning NU1510, for example `Microsoft.Extensions.Options` in a web project). Do this after the bump, since the bump is what makes them redundant.
   - Update Docker base images, the `global.json` `sdk.version`, and CI SDK versions.
5. **Build, and treat new warnings as part of the migration.** Fix obsoletions (`ASPDEPR*`, `SYSLIB*`, `CS0618`) by moving to the replacement API, not with `NoWarn`. If a call only exists to feed a package that is now unused, remove both the call and the package reference.
   Also expect new NuGet audit warnings (NU1903 and similar) on transitive packages of independently versioned dependencies. Find the source with `dotnet nuget why <project> <package>`, then add a direct reference to a patched version in the project that owns the dependency, and report it.
6. **Test.** Run the full suite and compare it with the baseline. Fix causes, not tests (see `dotnet-verify`).
7. **Run the app.** Some failures only appear at runtime, such as `TypeLoadException`/`MissingMethodException` between transitive package versions. Start it (stop any stale instance first, because Windows locks the exe) and request a health route, `swagger/v1/swagger.json` or `/openapi/v1.json`, and one representative endpoint. Exercise anything that compiles or loads code at runtime (Roslyn scripting, plugins, reflection).
   - If startup throws on missing configuration (an API key guard, for example), read the message and set the documented override through an environment variable for this check only. Don't edit config files.
   - Use a free port (`--no-launch-profile --urls http://localhost:<free port>`). Check that your instance actually bound it: the log should not contain "address already in use", and the listening process should be the new build's exe. A docker-compose container or another dev server on the usual port will otherwise answer your requests and give a false pass (or a misleading 404).
   - When you are done, stop only the processes you started, found by the owner of your listening port. Never kill by image name, because that can take down the user's other instances.
8. **Build the container**, if Docker is available, and confirm the runtime version inside it with `docker run --rm --entrypoint dotnet <image> --list-runtimes`. For multi-stage Dockerfiles, build each runtime target (`--target <name>`). Tag the images with a recognizable name, and in the report list them so the user can remove them (`docker rmi`).
9. **Update the docs** that state the version: prerequisites, tech stack lists, notes about the old version, and to-do items the upgrade completes.
10. **Report** the files changed, the packages bumped and why, the deprecations fixed, verification results (build warnings, test counts, runtime checks, Docker), and anything left for later.

## Known issues by target version

### .NET 10
- `WithOpenApi()` on minimal-API endpoints is obsolete (ASPDEPR002). Remove it. Endpoint metadata still reaches Swashbuckle through ApiExplorer, and it reaches the built-in `AddOpenApi()` without it.
- Swashbuckle 6.x (with no `Microsoft.AspNetCore.OpenApi` reference) still builds, generates `swagger.json`, and serves the UI on .NET 10, so it needs no change for the retarget. The conflict below only arises when both packages are present.
- `ForwardedHeadersOptions.KnownNetworks` is obsolete (ASPDEPR005). Use `KnownIPNetworks`.
- `Microsoft.AspNetCore.OpenApi` 10.x brings in Microsoft.OpenApi 2.x, and Swashbuckle versions before 10 are built on Microsoft.OpenApi 1.x. Pick one fix:
  - drop `Microsoft.AspNetCore.OpenApi` if only Swashbuckle uses it (often its only use is `WithOpenApi()`)
  - upgrade Swashbuckle to 10.x (custom filters move from `Microsoft.OpenApi.Models` to `Microsoft.OpenApi`)
  - switch to the built-in `AddOpenApi()`/`MapOpenApi()`

  Whichever you choose, confirm that `swagger.json` loads at runtime. To finish the migration, the first fix is the smallest. The other two are follow-ups (see below).

## Optional follow-up: modernize Swagger/OpenAPI (.NET 9+)

Offer this after the migration is verified, as a separate change. Don't bundle it into the retarget.

- **Built-in OpenAPI document + Swagger UI.** Microsoft's recommended path since .NET 9, and verified on .NET 10:
  - Packages: replace `Swashbuckle.AspNetCore` with `Microsoft.AspNetCore.OpenApi` (latest patch of the framework major) and `Swashbuckle.AspNetCore.SwaggerUI` (UI only).
  - Services: replace `AddEndpointsApiExplorer()` + `AddSwaggerGen()` with `builder.Services.AddOpenApi();`.
  - Pipeline: replace `UseSwagger()` + `UseSwaggerUI()` with `app.MapOpenApi();` and `app.UseSwaggerUI(o => o.SwaggerEndpoint("/openapi/v1.json", "v1"));`. The UI stays at `/swagger`, so existing redirects keep working. The document moves from `/swagger/v1/swagger.json` to `/openapi/v1.json` and is OpenAPI 3.1 (Swashbuckle 6 emits 3.0).
  - Port customizations by hand: `ISchemaFilter`/`IOperationFilter`/`IDocumentFilter` become `IOpenApiSchemaTransformer`/`IOpenApiOperationTransformer`/`IOpenApiDocumentTransformer`, and XML comments need `<GenerateDocumentationFile>`.
  - Check: the document's path count matches the old `swagger.json`, the UI loads, and any client generators or docs that referenced the old JSON URL are updated.
- **Swashbuckle 10.x.** Keeps `AddSwaggerGen`/`UseSwagger`/`UseSwaggerUI` and the `/swagger/v1/swagger.json` URL, so it is the lower-churn option. It is built on Microsoft.OpenApi 2.x: custom filters and `OpenApiInfo`/`OpenApiSecurityScheme` setup move from `Microsoft.OpenApi.Models` to `Microsoft.OpenApi`, and some model types change shape (for example `Reference` objects). With no customizations it is a version bump only. Confirm that `swagger.json` loads at runtime.

Add a section here whenever a migration turns up something new.
