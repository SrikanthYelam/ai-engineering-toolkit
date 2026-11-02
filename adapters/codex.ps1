# OpenAI Codex: AGENTS.md, .agents/skills, .codex/agents/*.toml
# Codex custom prompts are deprecated in favor of skills, so prompts/ is not installed for Codex.

function Install-Codex {
    Copy-Skills '.agents/skills'

    foreach ($a in Get-Agents) {
        if ($a.Body -match "'''") { throw "Agent '$($a.Meta['name'])': body must not contain '''" }
        $t = @("name = $(Yq $a.Meta['name'])", "description = $(Yq $a.Meta['description'])")
        if ($a.Meta['access'] -eq 'read-only') { $t += 'sandbox_mode = "read-only"' }
        $t += "developer_instructions = '''", $a.Body.TrimEnd("`n"), "'''"
        Put-Text ".codex/agents/$($a.Meta['name']).toml" ($t -join "`n")
    }
}
