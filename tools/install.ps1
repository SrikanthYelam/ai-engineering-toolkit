<#
.SYNOPSIS
  Install shared toolkit resources into a project in agent-native formats.
.EXAMPLE
  .\tools\install.ps1 -Target C:\src\MyApp
  .\tools\install.ps1 -Target C:\src\MyApp -Agents claude,copilot -DryRun
.NOTES
  Never overwrites files it did not create. Files it created are tracked in
  <Target>\.ai-toolkit.json and are refreshed on re-run.
#>
[CmdletBinding()]
param(
    [string]$Target = (Get-Location).Path,
    [ValidateSet('claude', 'copilot', 'codex')]
    [string[]]$Agents = @('claude', 'copilot', 'codex'),
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$script:Root   = Split-Path $PSScriptRoot -Parent
$script:Target = (Resolve-Path $Target).Path
$script:DryRun = $DryRun.IsPresent

. (Join-Path $Root 'adapters/common.ps1')
foreach ($a in $Agents) { . (Join-Path $Root "adapters/$a.ps1") }

$manifest = Join-Path $script:Target '.ai-toolkit.json'
if (Test-Path $manifest) { $script:Previous = @((Get-Content $manifest -Raw | ConvertFrom-Json).files) }

# Shared instructions: one AGENTS.md read by Codex and Copilot, imported by CLAUDE.md.
$parts = Get-ChildItem (Join-Path $Root 'instructions') -Filter *.md | Sort-Object Name |
    ForEach-Object { ([IO.File]::ReadAllText($_.FullName)).Trim() }
Put-Text 'AGENTS.md' (("# Project instructions`n`n" + ($parts -join "`n`n")))

foreach ($a in $Agents) { & "Install-$((Get-Culture).TextInfo.ToTitleCase($a))" }

if (-not $DryRun) {
    $files = @($script:Previous + $script:Installed) | Sort-Object -Unique
    $json = [ordered]@{ note = 'Managed by ai-engineering-toolkit'; files = $files } | ConvertTo-Json
    [IO.File]::WriteAllText($manifest, $json + "`n", (New-Object System.Text.UTF8Encoding($false)))
}
Write-Host "`nDone$(if ($DryRun) { ' (dry run, nothing written)' })."
