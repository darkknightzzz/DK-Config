# Claude 通用配置

这个目录保存可以跨机器、跨平台恢复的 Claude Code 配置。模型选择、本机标识、凭据和运行时数据不纳入版本管理。

## 目录结构

```text
claude/
├── CLAUDE.md                 # 全局工作偏好
├── memory/                   # 通用工作方式和格式偏好
│   ├── MEMORY.md
│   ├── file-output-level.md
│   ├── plan-first-no-auto-changes.md
│   └── plan-format.md
├── templates/
│   └── plan-example.md       # Plan 格式示例
├── install.sh                # Git Bash / Linux / macOS
├── install.ps1               # Windows PowerShell
├── .gitignore
└── README.md
```

## 在新机器恢复

先克隆仓库并进入仓库根目录：

```bash
git clone git@github.com:darkknightzzz/DK-Config.git
cd DK-Config
```

Windows PowerShell：

```powershell
.\claude\install.ps1
```

Git Bash、Linux 或 macOS：

```bash
bash ./claude/install.sh
```

默认安装到 `~/.claude/`。脚本只安装上面列出的六个配置或模板文件，不会清空目标目录，也不会修改现有的 `settings.json`。

如果存在同名文件，脚本会先备份到：

```text
~/.claude/backups/DK-Config/<时间戳>-<进程号>/
```

### 指定测试目录或自定义目标

Git Bash、Linux 或 macOS：

```bash
CLAUDE_HOME=/path/to/.claude bash ./claude/install.sh
```

Windows PowerShell：

```powershell
.\claude\install.ps1 -TargetDir "D:\path\to\.claude"
```

## 更新并上传

在仓库中修改配置后，从仓库根目录执行：

```bash
git add claude
git commit -m "Update Claude configuration"
git push
```

新机器已有仓库时，先执行 `git pull`，再运行对应安装脚本。

## 有意不同步的内容

- `settings.json`：当前只有与平台和账号可用性相关的模型设置，保留在各机器本地。
- `.claude.json`：包含本机标识、用户标识和本地迁移状态。
- `.credentials.json`、`settings.local.json`：凭据和本地覆盖配置。
- `projects/`、`sessions/`、`session-env/`：会话数据。
- `file-history/`、`shell-snapshots/`、`backups/`：历史内容和环境快照。
- `ide/`、`plugins/store/`：编辑器及插件运行状态。
