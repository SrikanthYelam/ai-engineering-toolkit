# GitHub Copilot (VS Code): .github/skills, .github/agents/*.agent.md, .github/prompts/*.prompt.md
# Copilot reads the shared AGENTS.md for instructions.

function Install-Copilot {
    Copy-Skills '.github/skills'

    foreach ($a in Get-Agents) {
        $fm = @('---', "name: $($a.Meta['name'])", "description: $(Yq $a.Meta['description'])")
        if ($a.Meta['access'] -eq 'read-only') { $fm += "tools: ['read', 'search', 'execute']" }
        Put-Text ".github/agents/$($a.Meta['name']).agent.md" ((($fm + '---' + '') -join "`n") + "`n" + $a.Body)
    }

    foreach ($p in Get-Prompts) {
        $fm = @('---', "description: $(Yq $p.Meta['description'])", 'agent: agent', '---', '')
        $body = $p.Body -replace '\{\{input\}\}', '${input:request:Describe the request}'
        Put-Text ".github/prompts/$($p.Name).prompt.md" (($fm -join "`n") + $body)
    }
}
