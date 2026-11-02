# Claude Code: CLAUDE.md, .claude/skills, .claude/agents, .claude/commands

function Install-Claude {
    # CLAUDE.md imports the shared AGENTS.md so instructions are not duplicated.
    Put-Text 'CLAUDE.md' "@AGENTS.md"
    Copy-Skills '.claude/skills'

    foreach ($a in Get-Agents) {
        $fm = @('---', "name: $($a.Meta['name'])", "description: $(Yq $a.Meta['description'])")
        if ($a.Meta['access'] -eq 'read-only') { $fm += 'tools: Read, Grep, Glob, Bash' }
        Put-Text ".claude/agents/$($a.Meta['name']).md" ((($fm + '---' + '') -join "`n") + "`n" + $a.Body)
    }

    foreach ($p in Get-Prompts) {
        $fm = @('---', "description: $(Yq $p.Meta['description'])", 'argument-hint: "[request]"', '---', '')
        Put-Text ".claude/commands/$($p.Name).md" (($fm -join "`n") + ($p.Body -replace '\{\{input\}\}', '$ARGUMENTS'))
    }
}
