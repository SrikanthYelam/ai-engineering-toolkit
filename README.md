# ai-engineering-toolkit

One place for reusable AI engineering resources, installed into any VS Code project for
**Claude Code**, **GitHub Copilot**, and **OpenAI Codex**. Content is written once; thin adapters
emit each tool's native format. Initial emphasis is C#/.NET, but nothing is language-bound.

## Layout

| Folder | Source (edit here) | Installed as |
|---|---|---|
| `instructions/` | shared `*.md` principles/guidelines | `AGENTS.md` (Codex, Copilot); `CLAUDE.md` imports it |
| `skills/<name>/SKILL.md` | [Agent Skills](https://agentskills.io) standard | `.claude/skills`, `.github/skills`, `.agents/skills` |
| `agents/<name>.md` | neutral frontmatter + prompt body | `.claude/agents/*.md`, `.github/agents/*.agent.md`, `.codex/agents/*.toml` |
| `prompts/<name>.md` | prompt with `{{input}}` placeholder | `.claude/commands/`, `.github/prompts/*.prompt.md` (not Codex: its custom prompts are deprecated for skills) |
| `adapters/` | one PowerShell file per vendor | - |
| `tools/` | `install.ps1`; future scripts and MCP integrations | - |
| `workflows/` | future multi-agent workflows | - |

## Setup

Requires PowerShell 5.1+ (Windows PowerShell or `pwsh`). Clone this repo anywhere, then:

```powershell
# preview, then install into a project
.\tools\install.ps1 -Target C:\src\MyApp -DryRun
.\tools\install.ps1 -Target C:\src\MyApp

# only some assistants
.\tools\install.ps1 -Target C:\src\MyApp -Agents claude,copilot
```

"Install" does not copy this repo into your project. The installer reads the toolkit's sources and
writes only the files each assistant looks for inside the project (`AGENTS.md`, `CLAUDE.md`,
`.claude/`, `.github/`, `.agents/`, `.codex/`). Skills are copied as-is; agents, prompts, and
instructions are translated into each tool's format. `adapters/`, `tools/`, and `workflows/` never
leave this repo. The generated files are snapshots, so re-run the installer after changing the toolkit.

Behavior:
- **Never overwrites** a file it didn't create. Existing `AGENTS.md`, `CLAUDE.md`, skills, etc. are skipped with a warning (merge by hand, e.g. add `@AGENTS.md` to your `CLAUDE.md`).
- Files it did create are listed in `<project>\.ai-toolkit.json`; re-run the installer after `git pull` here to refresh them. Commit installed files to the project, or add them to its `.gitignore`.
- Invalid skills/agents (name not matching folder/file, missing description) fail the install.

## Usage

- Claude Code: `/implement-feature <request>`, `@code-reviewer`, skills load automatically.
- Copilot (VS Code): pick `code-reviewer` / `test-writer` in the agents dropdown; run `/implement-feature` in chat.
- Codex: agents in `.codex/agents`, skills via `$dotnet-verify`, instructions from `AGENTS.md`.

## Adding things

- **Skill:** create `skills/<kebab-name>/SKILL.md` with `name` (equal to the folder) and `description`.
- **Agent:** create `agents/<name>.md` with `name`, `description`, optional `access: read-only`, then the prompt body.
- **Prompt:** create `prompts/<name>.md` with `description`; use `{{input}}` for the user's request.
- **Instruction:** add a `.md` to `instructions/`; files are concatenated in name order, so use a numeric prefix (`04-...md`).
- **New assistant:** add `adapters/<name>.ps1` defining `Install-<Name>` and add it to the `-Agents` ValidateSet.

Re-run the installer in each project after changes.
