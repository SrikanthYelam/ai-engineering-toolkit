## LLM / AI integration

Apply when the project calls an LLM or embedding provider.

- Secrets: read API keys from environment variables (e.g. `OPENAI_API_KEY`) or user secrets. Never hardcode them or commit them, including in `docker-compose.yml` and `appsettings*.json`.
- Boundary: put the provider behind a small interface (e.g. `IChatClient` from Microsoft.Extensions.AI, or a domain interface like `IEmbedder`). Only the composition root (`Program.cs` / DI setup) references the vendor SDK.
- Resilience: decide explicitly what happens when the AI call fails (missing key, network, unparseable output). Prefer degrading the AI-dependent part over failing the whole request, and document that choice.
- Output: treat model output as untrusted input. Validate or parse it defensively; never execute or render it unescaped.
- Tests: never call a real provider in unit tests. Use hand-written fakes that return scripted results.
- Cost: batch requests where possible, cache repeated calls, and keep model names in configuration.
