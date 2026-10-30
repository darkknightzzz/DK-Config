---
name: plan-format
description: 所有 implementation plan 必须遵循的 markdown 模板格式
metadata:
  type: feedback
---

## Plan 模板规则

每次出 plan 必须严格遵循以下格式：

1. **标题** — emoji + 函数/功能名，下方附耗时表
2. **🎯 目标** — 独立 section，一句话说清要做什么
3. **📐 涉及文件** — 表格列出所有文件 + 角色（大项目方便快速定位）
4. **Phase** — 每个 phase 用 🟢🟡🔴 信号灯标风险等级，内含：
   - ` ```diff ` 代码块（`+` 绿色新增 / `-` 红色删除，带 `@@` hunk header）
   - 风险说明表
5. **📦 最终产出** — 表格统计每个文件改动行数 + 合计
6. **禁止** — 不要依赖图、不要执行顺序图

**Why:** 用户偏好 git diff 风格 + 信号灯风险 + 独立目标/文件区，preview 模式下视觉效果清晰。

**How to apply:** 每次出 plan 前参照 `~/.claude/templates/plan-example.md`，严格复用其 section 结构和 diff 风格。