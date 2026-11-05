[CmdletBinding()]
param(
    [ValidateSet("claude", "dsh", "both")]
    [string]$Targets = "both",
    [string]$ClaudeHome = $(if ($env:CLAUDE_HOME) { $env:CLAUDE_HOME } else { Join-Path $HOME ".claude" }),
    [string]$DshHome = $(if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $HOME ".dsh" }),
    [string]$ResearchRoot = $env:DK_RESEARCH_ROOT,
    [string]$ResearchMode = $(if ($env:DK_RESEARCH_MODE) { $env:DK_RESEARCH_MODE } else { "ask" })
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$SourceDir = $PSScriptRoot
$Utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$Timestamp = "{0}-{1}" -f (Get-Date -Format "yyyyMMdd-HHmmss"), $PID

# 所有目标都安装的文件
$SharedFiles = @(
    "templates/plan-example.md"
)

# 仅 Claude 目标安装：DSH 的 ~/.dsh/memory 是 mneme 插件的存储目录（SQLite 主存储），
# 不能往里放配置文件；DSH 侧的记忆已内联进 AGENTS.md，不需要这些副本。
$ClaudeOnlyFiles = @(
    "memory/MEMORY.md",
    "memory/file-output-level.md",
    "memory/plan-first-no-auto-changes.md",
    "memory/plan-format.md"
)

# 合并进指令文件的记忆片段及顺序
$MemoryOrder = @(
    "memory/plan-first-no-auto-changes.md",
    "memory/plan-format.md",
    "memory/file-output-level.md"
)

$script:BackupCreated = $false
$script:Written = 0
$script:Skipped = 0

function Remove-FrontMatter {
    param([string]$Text)
    $body = $Text -replace "^\uFEFF", ""
    if ($body -match "(?s)^---\r?\n.*?\r?\n---\r?\n") {
        return $body.Substring($Matches[0].Length)
    }
    return $body
}

function New-InstructionText {
    $builder = New-Object System.Text.StringBuilder
    $base = [System.IO.File]::ReadAllText((Join-Path $SourceDir "AGENTS.md"))
    [void]$builder.Append($base.TrimEnd())
    [void]$builder.Append("`n`n## 记忆细则（安装时由 memory/*.md 合并生成，勿手改）`n")
    foreach ($relative in $MemoryOrder) {
        $body = Remove-FrontMatter ([System.IO.File]::ReadAllText((Join-Path $SourceDir $relative)))
        $body = $body -replace "(?m)^## ", "#### "
        $name = [System.IO.Path]::GetFileNameWithoutExtension($relative)
        [void]$builder.Append("`n### $name`n`n")
        [void]$builder.Append($body.Trim())
        [void]$builder.Append("`n")
    }
    return $builder.ToString()
}

function Write-ManagedFile {
    param(
        [string]$TargetHome,
        [string]$RelativePath,
        [string]$Content
    )
    # 统一切到 LF，避免源文件 CRLF/LF 混杂导致两个安装器产物不一致
    $Content = $Content.Replace("`r`n", "`n")
    $targetPath = Join-Path $TargetHome $RelativePath
    $targetDir = Split-Path -Parent $targetPath
    if (-not (Test-Path -LiteralPath $targetDir)) {
        $null = New-Item -ItemType Directory -Force -Path $targetDir
    }
    if (Test-Path -LiteralPath $targetPath -PathType Leaf) {
        $existing = [System.IO.File]::ReadAllText($targetPath)
        if ($existing -ceq $Content) {
            $script:Skipped++
            return
        }
        $backupPath = Join-Path (Join-Path $TargetHome "backups/DK-Config/$Timestamp") $RelativePath
        $backupDir = Split-Path -Parent $backupPath
        if (-not (Test-Path -LiteralPath $backupDir)) {
            $null = New-Item -ItemType Directory -Force -Path $backupDir
        }
        Copy-Item -LiteralPath $targetPath -Destination $backupPath -Force
        $script:BackupCreated = $true
    }
    [System.IO.File]::WriteAllText($targetPath, $Content, $Utf8NoBom)
    $script:Written++
}

$specs = @()
if ($Targets -eq "claude" -or $Targets -eq "both") {
    $specs += [pscustomobject]@{ Name = "Claude"; Home = $ClaudeHome; InstructionFile = "CLAUDE.md"; Memory = $true }
}
if ($Targets -eq "dsh" -or $Targets -eq "both") {
    $specs += [pscustomobject]@{ Name = "DSH"; Home = $DshHome; InstructionFile = "AGENTS.md"; Memory = $false }
}

$instructionText = New-InstructionText

$researchText = $null
if ([string]::IsNullOrWhiteSpace($ResearchRoot)) {
    Write-Warning "未提供 -ResearchRoot 或 DK_RESEARCH_ROOT，跳过 research skill 安装（不会写入空路径）。"
}
else {
    # ValidateSet 只约束显式传参；经环境变量带入的值在这里兜底校验
    $mode = $ResearchMode
    if ($mode -ne "ask" -and $mode -ne "auto" -and $mode -ne "auto-with-report") {
        Write-Warning "未知的 ResearchMode '$mode'，回落为 ask。"
        $mode = "ask"
    }
    $template = [System.IO.File]::ReadAllText((Join-Path $SourceDir "skills/research/SKILL.md"))
    $template = $template.Replace("__RESEARCH_ROOT__", $ResearchRoot)
    $researchText = $template.Replace("__RESEARCH_MODE__", $mode)
}

foreach ($spec in $specs) {
    Write-ManagedFile -TargetHome $spec.Home -RelativePath $spec.InstructionFile -Content $instructionText
    foreach ($relative in $SharedFiles) {
        $content = [System.IO.File]::ReadAllText((Join-Path $SourceDir $relative))
        Write-ManagedFile -TargetHome $spec.Home -RelativePath $relative -Content $content
    }
    if ($spec.Memory) {
        foreach ($relative in $ClaudeOnlyFiles) {
            $content = [System.IO.File]::ReadAllText((Join-Path $SourceDir $relative))
            Write-ManagedFile -TargetHome $spec.Home -RelativePath $relative -Content $content
        }
    }
    if ($null -ne $researchText) {
        Write-ManagedFile -TargetHome $spec.Home -RelativePath "skills/research/SKILL.md" -Content $researchText
    }
    Write-Host ("[{0}] -> {1}" -f $spec.Name, $spec.Home)
}

Write-Host ("写入 {0} 个文件，跳过 {1} 个未变化文件。" -f $script:Written, $script:Skipped)
if ($script:BackupCreated) {
    Write-Host ("旧文件已备份到: {0}" -f (Join-Path $specs[0].Home "backups/DK-Config/$Timestamp"))
}
