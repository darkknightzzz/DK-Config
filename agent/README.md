# 通用 agent 配置

这个目录保存可以跨机器、跨 harness 恢复的 agent 配置。模型选择、本机标识、凭据和运行时数据不纳入版本管理。

## 支持的目标

| 目标 | 指令文件 | 连同安装的内容 |
|------|---------|-------------|
| Claude Code | `~/.claude/CLAUDE.md` | `memory/`、`skills/`、`templates/` |
| DSH | `~/.dsh/AGENTS.md` | `skills/`、`templates/` |

同一份内容会按目标渲染成不同的指令文件名；`AGENTS.md` 是唯一源文件，安装时按目标改名落盘。

**DSH 不装 `memory/`**：`~/.dsh/memory` 是 mneme 插件的存储目录（SQLite 主存储 + Markdown），属于该插件的地盘。而且 DSH 侧的记忆已经被合并进 `AGENTS.md`，单独的副本本来就不需要。

## 目录结构

```text
agent/
├── AGENTS.md                 # 全局工作偏好（唯一源，安装时改名为 CLAUDE.md / AGENTS.md）
├── memory/                   # 通用工作方式和格式偏好
│   ├── MEMORY.md
│   ├── file-output-level.md
│   ├── plan-first-no-auto-changes.md
│   └── plan-format.md
├── templates/
│   └── plan-example.md       # Plan 格式示例
├── skills/
│   └── research/
│       └── SKILL.md          # 研究续接机制
├── install.sh                # Git Bash / Linux / macOS
├── install.ps1               # Windows PowerShell
├── .gitignore
└── README.md
```

## 安装

Windows PowerShell（在仓库根目录执行）：

```powershell
.\agent\install.ps1 -Targets both -ResearchRoot "D:\worklpace\jupyter\DK-research\re-history"
```

如果提示「在此系统上禁止运行脚本」，改用：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\agent\install.ps1 -Targets both -ResearchRoot "D:\...\re-history"
```

Git Bash、Linux 或 macOS：

```bash
DK_TARGETS=both DK_RESEARCH_ROOT=/path/to/re-history bash ./agent/install.sh
```

### 参数

| PowerShell | 环境变量 | 默认 | 说明 |
|-----------|---------|------|------|
| `-Targets` | `DK_TARGETS` | `both` | `claude` / `dsh` / `both` |
| `-ClaudeHome` | `CLAUDE_HOME` | `~/.claude` | 自定义目标目录 |
| `-DshHome` | `DSH_HOME` | `~/.dsh` | 自定义目标目录 |
| `-ResearchRoot` | `DK_RESEARCH_ROOT` | 空 | research 根目录；**为空则跳过 skill 安装并告警** |
| `-ResearchMode` | `DK_RESEARCH_MODE` | `ask` | `ask` / `auto` / `auto-with-report`；非法值回落 `ask` |

`ResearchMode` 的语义见 `skills/research/SKILL.md` 第 4 节「落盘 — 询问式」。

### 自定义目标目录

```powershell
.\agent\install.ps1 -Targets dsh -DshHome "D:\tmp\.dsh" -ResearchRoot "..."
```

```bash
CLAUDE_HOME=/tmp/.claude DSH_HOME=/tmp/.dsh bash ./agent/install.sh
```

## 记忆合并渲染

安装产物 = `AGENTS.md` 正文 + `memory/` 三篇正文（去掉 YAML frontmatter，标题降两级），合并进同一份指令文件：

```text
# 通用 agent 偏好
## 工作流程 / 沟通风格 / Plan 输出格式
## 记忆细则（安装时由 memory/*.md 合并生成，勿手改）
### plan-first-no-auto-changes
### plan-format
### file-output-level
```

这样做的原因：指令文件由 harness 在每次请求时放进上下文（DSH 是持久基线消息），**规则常驻**，不依赖模型每轮主动去 Read 一遍 memory——那是一次额外工具调用，还可能漏。

因此产物是生成物：要改规则请改 `memory/*.md` 后重跑安装，直接改产物会被下次安装覆盖。

## 安装器行为

- **幂等**：目标文件内容未变则跳过，不写入、不备份
- **备份**：真正覆盖前备份到 `<home>/backups/DK-Config/<时间戳>-<PID>/`
- **空值保护**：`ResearchRoot` 为空时跳过 research skill 安装并告警，绝不写入空路径
- **换行归一**：产物一律 LF，两个安装器输出逐字节一致
- **UTF-8 无 BOM** 写入产物，避免 Windows 中文乱码

## 新机器恢复清单

1. `git clone` 仓库
2. 跑安装脚本，**必须传 `-ResearchRoot`**（这是唯一机器相关参数）
3. 确认 `research` 根目录下 `INDEX.md` 存在（数据不在本仓库，需要单独同步）
4. 若用 DSH：**新开一个会话**，全局指令在会话首次请求时加载

## 已知限制

- **DSH 侧需新开会话**：全局指令在会话首次请求时加载，装完当前会话不会变。
- **研究根目录是机器相关的**：靠 `-ResearchRoot` / `DK_RESEARCH_ROOT` 传入；`SKILL.md` 里的 `__RESEARCH_ROOT__` 是占位符，未替换即表示未配置。
- **Windows PowerShell 5.1 需 BOM**：`install.ps1` 以 UTF-8 BOM 保存，否则 5.1 会按 ANSI 解码，中文注释会吃掉引号导致语法错误。
- **Git Bash 在受限沙箱下起不来**：MSYS 需要创建命名管道，被沙箱拦截时会报 `couldn't create signal pipe`，属环境限制而非脚本问题。

## 更新并上传

```bash
git add agent
git commit -m "Update agent configuration"
git push
```
