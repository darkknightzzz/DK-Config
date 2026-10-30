[CmdletBinding()]
param(
    [string]$TargetDir = $(if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $HOME ".claude" })
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SourceDir = $PSScriptRoot
$Timestamp = "{0}-{1}" -f (Get-Date -Format "yyyyMMdd-HHmmss"), $PID
$BackupDir = Join-Path $TargetDir "backups/DK-Config/$Timestamp"
$Files = @(
    "CLAUDE.md",
    "memory/MEMORY.md",
    "memory/file-output-level.md",
    "memory/plan-first-no-auto-changes.md",
    "memory/plan-format.md",
    "templates/plan-example.md"
)

$BackupCreated = $false
foreach ($RelativePath in $Files) {
    $TargetPath = Join-Path $TargetDir $RelativePath
    if (Test-Path -LiteralPath $TargetPath -PathType Leaf) {
        $BackupPath = Join-Path $BackupDir $RelativePath
        $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $BackupPath)
        Copy-Item -LiteralPath $TargetPath -Destination $BackupPath -Force
        $BackupCreated = $true
    }
}

foreach ($RelativePath in $Files) {
    $SourcePath = Join-Path $SourceDir $RelativePath
    $TargetPath = Join-Path $TargetDir $RelativePath
    $null = New-Item -ItemType Directory -Force -Path (Split-Path -Parent $TargetPath)
    Copy-Item -LiteralPath $SourcePath -Destination $TargetPath -Force
}

Write-Host "Claude configuration installed to: $TargetDir"
if ($BackupCreated) {
    Write-Host "Previous managed files backed up to: $BackupDir"
} else {
    Write-Host "No existing managed files required backup."
}
