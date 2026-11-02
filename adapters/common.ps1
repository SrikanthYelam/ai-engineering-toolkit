# Shared helpers for adapters. Dot-sourced by tools/install.ps1.

$script:Installed = New-Object 'System.Collections.Generic.List[string]'
$script:Previous  = @()
$utf8 = New-Object System.Text.UTF8Encoding($false)

function Read-Doc([string]$Path) {
    $raw = ([IO.File]::ReadAllText($Path)) -replace "`r`n", "`n"
    if ($raw -notmatch '(?s)^---\n(.*?)\n---\n(.*)$') { throw "Missing frontmatter: $Path" }
    $fm = $Matches[1]; $body = $Matches[2].TrimStart("`n")
    $meta = [ordered]@{}
    foreach ($line in $fm -split "`n") {
        if ($line -match '^([\w-]+):\s*(.*)$') { $meta[$Matches[1]] = $Matches[2].Trim() }
    }
    [pscustomobject]@{ Meta = $meta; Body = $body; Path = $Path }
}

# Write a file into the target project unless an unmanaged file already exists there.
function Put([string]$Rel, [byte[]]$Bytes) {
    $full = Join-Path $script:Target $Rel
    if ((Test-Path -LiteralPath $full) -and ($script:Previous -notcontains $Rel)) {
        Write-Host "skip    $Rel (exists, not managed by toolkit)" -ForegroundColor Yellow
        return
    }
    $script:Installed.Add($Rel)
    if ((Test-Path -LiteralPath $full) -and
        (@(Compare-Object ([IO.File]::ReadAllBytes($full)) $Bytes -SyncWindow 0).Count -eq 0)) {
        Write-Host "same    $Rel"; return
    }
    Write-Host "write   $Rel" -ForegroundColor Green
    if ($script:DryRun) { return }
    $dir = Split-Path $full -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    [IO.File]::WriteAllBytes($full, $Bytes)
}

function Put-Text([string]$Rel, [string]$Text) {
    Put $Rel ($utf8.GetBytes(($Text -replace "`r`n", "`n").TrimEnd("`n") + "`n"))
}

function Get-Skills {
    Get-ChildItem (Join-Path $script:Root 'skills') -Directory | ForEach-Object {
        $doc = Read-Doc (Join-Path $_.FullName 'SKILL.md')
        if ($doc.Meta['name'] -cne $_.Name -or $_.Name -notmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
            throw "Skill '$($_.Name)': frontmatter name must equal the lowercase-hyphen folder name"
        }
        if (-not $doc.Meta['description']) { throw "Skill '$($_.Name)': description is required" }
        $_
    }
}

function Get-Agents {
    Get-ChildItem (Join-Path $script:Root 'agents') -Filter *.md | ForEach-Object {
        $doc = Read-Doc $_.FullName
        if ($doc.Meta['name'] -cne $_.BaseName) { throw "Agent '$($_.Name)': name must match file name" }
        if (-not $doc.Meta['description']) { throw "Agent '$($_.Name)': description is required" }
        $doc
    }
}

function Get-Prompts {
    Get-ChildItem (Join-Path $script:Root 'prompts') -Filter *.md | ForEach-Object {
        $doc = Read-Doc $_.FullName
        $doc | Add-Member Name $_.BaseName
        $doc
    }
}

function Copy-Skills([string]$DestDir) {
    foreach ($skill in Get-Skills) {
        foreach ($f in Get-ChildItem $skill.FullName -Recurse -File) {
            $rel = $f.FullName.Substring($skill.FullName.Length + 1) -replace '\\', '/'
            Put "$DestDir/$($skill.Name)/$rel" ([IO.File]::ReadAllBytes($f.FullName))
        }
    }
}

# Single-line YAML scalar, quoted so ':' in descriptions stays valid.
function Yq([string]$s) { '"' + ($s -replace '\\', '\\' -replace '"', '\"') + '"' }
