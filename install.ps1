[CmdletBinding()]
param(
    [string]$RepoUrl = 'https://github.com/Fadinggo/claude-skills.git',
    [string]$Root = (Join-Path $env:USERPROFILE 'claude-skills'),
    [string]$SkillsDir = (Join-Path $env:USERPROFILE '.claude\skills'),
    [string]$TaskName = 'ClaudeSkillsSync',
    [switch]$NoTask
)

$ErrorActionPreference = 'Stop'
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Host 'Git is required. Install it with: winget install --id Git.Git -e'
    exit 1
}

try {
    $Root = [System.IO.Path]::GetFullPath($Root)
    $SkillsDir = [System.IO.Path]::GetFullPath($SkillsDir)
    if (-not (Test-Path -LiteralPath $Root)) {
        & git clone -- $RepoUrl $Root
        if ($LASTEXITCODE -ne 0) { throw 'Git clone failed.' }
        $repoStatus = 'cloned'
    } else {
        if (-not (Test-Path -LiteralPath $Root -PathType Container)) {
            throw "Root is not a directory: $Root"
        }
        $topLevel = & git -C $Root rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -ne 0 -or [System.IO.Path]::GetFullPath($topLevel).TrimEnd('\', '/') -ine $Root.TrimEnd('\', '/')) {
            throw "Root is not a Git repository root: $Root"
        }
        & git -C $Root pull --ff-only -q
        if ($LASTEXITCODE -ne 0) {
            Write-Warning 'Git pull failed; continuing with the existing files.'
            $repoStatus = 'pull failed; existing files used'
        } else {
            $repoStatus = 'updated'
        }
    }

    New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
    $linked = @()
    $unchanged = @()
    $skipped = @()
    foreach ($skill in Get-ChildItem -LiteralPath $Root -Directory -Force) {
        if (-not (Test-Path -LiteralPath (Join-Path $skill.FullName 'SKILL.md') -PathType Leaf)) { continue }
        $linkPath = Join-Path $SkillsDir $skill.Name
        $existing = Get-Item -LiteralPath $linkPath -Force -ErrorAction SilentlyContinue
        if ($null -ne $existing) {
            if ($existing.LinkType -ne 'Junction') {
                Write-Warning "Skipping '$linkPath': an existing file or non-junction directory is in the way."
                $skipped += $skill.Name
                continue
            }
            $target = [System.IO.Path]::GetFullPath([string]$existing.Target).TrimEnd('\', '/')
            if ($target -ieq $skill.FullName.TrimEnd('\', '/')) {
                $unchanged += $skill.Name
                continue
            }
            & cmd.exe /d /c rmdir "`"$linkPath`""
            if ($LASTEXITCODE -ne 0) { throw "Could not remove junction: $linkPath" }
        }
        New-Item -ItemType Junction -Path $linkPath -Target $skill.FullName | Out-Null
        $linked += $skill.Name
    }

    $taskStatus = 'skipped (-NoTask)'
    if (-not $NoTask) {
        $scriptPath = Join-Path $Root 'install.ps1'
        $arguments = '-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File "{0}" -NoTask -Root "{1}" -SkillsDir "{2}"' -f $scriptPath, $Root, $SkillsDir
        $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument $arguments
        $trigger = New-ScheduledTaskTrigger -AtLogOn -User ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)
        $repeating = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 3) -RepetitionDuration (New-TimeSpan -Days 1)
        $repeating.Repetition.Duration = $null
        $trigger.Repetition = $repeating.Repetition
        $principal = New-ScheduledTaskPrincipal -UserId ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
        Register-ScheduledTask -TaskName $TaskName -Action $action -Trigger $trigger -Principal $principal -Force | Out-Null
        $taskStatus = "registered ($TaskName)"
    }

    Write-Host "Repo: $repoStatus"
    Write-Host "Linked or repaired: $(if ($linked.Count) { $linked -join ', ' } else { 'none' })"
    Write-Host "Already linked: $(if ($unchanged.Count) { $unchanged -join ', ' } else { 'none' })"
    Write-Host "Skipped: $(if ($skipped.Count) { $skipped -join ', ' } else { 'none' })"
    Write-Host "Scheduled task: $taskStatus"
} catch {
    Write-Error $_
    exit 1
}
