<#
.SYNOPSIS
  Install shared toolkit resources into a project in agent-native formats.
.EXAMPLE
  .\tools\install.ps1 -Target C:\src\MyApp
  .\tools\install.ps1 -Target C:\src\MyApp -Agents claude,copilot -DryRun
  .\tools\install.ps1 -Target C:\src\MyApp -Skills dotnet-*,conventional-commit -Prompts fix-bug -Subagents none
.NOTES
  Never overwrites files it did not create. Files it created are tracked in
  <Target>\.ai-toolkit.json and are refreshed on re-run. Each run installs exactly the
  current selection: managed files that are no longer selected are removed.
  -Skills/-Subagents/-Prompts/-Instructions take names (folder or file name without .md),
  wildcards allowed; 'none' installs nothing of that kind. Default is everything.
#>
[CmdletBinding()]
param(
    [string]$Target = (Get-Location).Path,
    [ValidateSet('claude', 'copilot', 'codex')]
    [string[]]$Agents = @('claude', 'copilot', 'codex'),
    [string[]]$Skills = @('*'),
    [string[]]$Subagents = @('*'),
    [string[]]$Prompts = @('*'),
    [string[]]$Instructions = @('*'),
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$script:Root   = Split-Path $PSScriptRoot -Parent
$script:Target = (Resolve-Path $Target).Path
$script:DryRun = $DryRun.IsPresent

. (Join-Path $Root 'adapters/common.ps1')
foreach ($a in $Agents) { . (Join-Path $Root "adapters/$a.ps1") }
$script:Select = @{ skills = $Skills; subagents = $Subagents; prompts = $Prompts; instructions = $Instructions }

# Validate the selection and every selected source before writing anything.
$null = Get-Skills; $null = Get-Agents; $null = Get-Prompts
$instructionFiles = @(Get-Instructions)

$manifest = Join-Path $script:Target '.ai-toolkit.json'
if (Test-Path $manifest) { $script:Previous = @((Get-Content $manifest -Raw | ConvertFrom-Json).files) }

# Shared instructions: one AGENTS.md read by Codex and Copilot, imported by CLAUDE.md.
if ($instructionFiles.Count) {
    $parts = $instructionFiles | ForEach-Object { ([IO.File]::ReadAllText($_.FullName)).Trim() }
    Put-Text 'AGENTS.md' (("# Project instructions`n`n" + ($parts -join "`n`n")))
}

foreach ($a in $Agents) { & "Install-$((Get-Culture).TextInfo.ToTitleCase($a))" }

# Remove files from earlier runs that are no longer selected, plus folders left empty.
foreach ($rel in $script:Previous | Where-Object { $script:Installed -notcontains $_ }) {
    $full = Join-Path $script:Target $rel
    if (-not (Test-Path -LiteralPath $full)) { continue }
    Write-Host "remove  $rel" -ForegroundColor Cyan
    if ($DryRun) { continue }
    Remove-Item -LiteralPath $full -Force
    $dir = Split-Path $full -Parent
    while ($dir.Length -gt $script:Target.Length -and -not (Get-ChildItem -LiteralPath $dir -Force)) {
        Remove-Item -LiteralPath $dir -Force
        $dir = Split-Path $dir -Parent
    }
}

if (-not $DryRun) {
    $files = @(@($script:Installed) | Sort-Object -Unique)
    $json = [ordered]@{ note = 'Managed by ai-engineering-toolkit'; files = $files } | ConvertTo-Json
    [IO.File]::WriteAllText($manifest, $json + "`n", (New-Object System.Text.UTF8Encoding($false)))
}
Write-Host "`nDone$(if ($DryRun) { ' (dry run, nothing written)' })."
