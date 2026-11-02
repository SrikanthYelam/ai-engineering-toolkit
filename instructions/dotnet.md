## C# / .NET guidelines

Apply only when the project contains .NET code.

- Follow the existing `.editorconfig` and project style; otherwise use the .NET framework design guidelines.
- Keep nullable reference types enabled; do not suppress warnings with `!` without a reason.
- Use `async`/`await` end to end; accept and pass `CancellationToken`; never block with `.Result` or `.Wait()`.
- Prefer constructor injection; depend on interfaces only where a seam is needed.
- Use `ILogger<T>` with structured message templates, not string interpolation.
- Throw specific exceptions; do not swallow them. Use `ArgumentNullException.ThrowIfNull` and similar guards.
- Build with `dotnet build` and test with `dotnet test`; keep the build warning-free.
- Tests: xUnit/NUnit/MSTest as already used in the repo; name tests `Method_Scenario_Expected`.
