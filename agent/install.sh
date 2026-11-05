#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGETS="${DK_TARGETS:-both}"
CLAUDE_DIR="${CLAUDE_HOME:-$HOME/.claude}"
DSH_DIR="${DSH_HOME:-$HOME/.dsh}"
RESEARCH_ROOT="${DK_RESEARCH_ROOT:-}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)-$$"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# 所有目标都安装的文件
SHARED_FILES=(
  "templates/plan-example.md"
)

# 仅 Claude 目标安装：DSH 的 ~/.dsh/memory 是 mneme 插件的存储目录（SQLite 主存储），
# 不能往里放配置文件；DSH 侧的记忆已内联进 AGENTS.md，不需要这些副本。
CLAUDE_ONLY_FILES=(
  "memory/MEMORY.md"
  "memory/file-output-level.md"
  "memory/plan-first-no-auto-changes.md"
  "memory/plan-format.md"
)

# 合并进指令文件的记忆片段及顺序
MEMORY_ORDER=(
  "memory/plan-first-no-auto-changes.md"
  "memory/plan-format.md"
  "memory/file-output-level.md"
)

backup_created=0
written=0
skipped=0

# 统一切到 LF，避免源文件 CRLF/LF 混杂导致两个安装器产物不一致
normalize() {
  tr -d '\r' < "$1" > "$2"
}

# 输入已是 LF 文件：去掉 YAML frontmatter，把二级标题降为四级，并去掉前导空行
strip_body() {
  awk '
    BEGIN { state = 0 }
    state == 0 && NR == 1 && /^---[[:space:]]*$/ { state = 1; next }
    state == 1 && /^---[[:space:]]*$/              { state = 2; next }
    state == 0 { print; next }
    state == 2 { if (substr($0, 1, 3) == "## ") print "##" $0; else print }
  ' "$1" | sed -e '/./,$!d'
}

# 内容未变则跳过；变则先备份再写
write_file_if_changed() {
  local target_dir="$1"
  local relative_path="$2"
  local source_file="$3"
  local target_path="$target_dir/$relative_path"

  mkdir -p "$(dirname "$target_path")"

  if [ -f "$target_path" ] && cmp -s "$source_file" "$target_path"; then
    skipped=$((skipped + 1))
    return 0
  fi

  if [ -f "$target_path" ]; then
    local backup_path="$target_dir/backups/DK-Config/$TIMESTAMP/$relative_path"
    mkdir -p "$(dirname "$backup_path")"
    cp -p "$target_path" "$backup_path"
    backup_created=1
  fi

  cp "$source_file" "$target_path"
  written=$((written + 1))
}

# ── 预生成：全部产物先落到临时目录，统一 LF ──
mkdir -p "$TMP_DIR/src"
normalize "$SOURCE_DIR/AGENTS.md" "$TMP_DIR/agents.md"

for relative_path in "${SHARED_FILES[@]}" "${CLAUDE_ONLY_FILES[@]}"; do
  mkdir -p "$TMP_DIR/src/$(dirname "$relative_path")"
  normalize "$SOURCE_DIR/$relative_path" "$TMP_DIR/src/$relative_path"
done

for memory_file in "${MEMORY_ORDER[@]}"; do
  normalize "$SOURCE_DIR/$memory_file" "$TMP_DIR/mem-$(basename "$memory_file" .md).md"
done

{
  printf '%s' "$(cat "$TMP_DIR/agents.md")"
  printf '\n\n## 记忆细则（安装时由 memory/*.md 合并生成，勿手改）\n'
  for memory_file in "${MEMORY_ORDER[@]}"; do
    memory_name="$(basename "$memory_file" .md)"
    printf '\n### %s\n\n%s\n' "$memory_name" "$(strip_body "$TMP_DIR/mem-$memory_name.md")"
  done
} > "$TMP_DIR/instruction.md"

if [ -z "$RESEARCH_ROOT" ]; then
  printf 'warning: 未提供 DK_RESEARCH_ROOT，跳过 research skill 安装（不会写入空路径）。\n' >&2
  RESEARCH_TEMPLATE=""
else
  escaped_root="$(printf '%s' "$RESEARCH_ROOT" | sed -e 's/[\\&|]/\\&/g')"
  normalize "$SOURCE_DIR/skills/research/SKILL.md" "$TMP_DIR/research-source.md"
  sed "s|__RESEARCH_ROOT__|$escaped_root|g" \
    "$TMP_DIR/research-source.md" > "$TMP_DIR/research-SKILL.md"
  RESEARCH_TEMPLATE="$TMP_DIR/research-SKILL.md"
fi

install_target() {
  local home_dir="$1"
  local instruction_name="$2"
  local install_memory="$3"

  write_file_if_changed "$home_dir" "$instruction_name" "$TMP_DIR/instruction.md"

  for relative_path in "${SHARED_FILES[@]}"; do
    write_file_if_changed "$home_dir" "$relative_path" "$TMP_DIR/src/$relative_path"
  done

  if [ "$install_memory" -eq 1 ]; then
    for relative_path in "${CLAUDE_ONLY_FILES[@]}"; do
      write_file_if_changed "$home_dir" "$relative_path" "$TMP_DIR/src/$relative_path"
    done
  fi

  if [ -n "$RESEARCH_TEMPLATE" ]; then
    write_file_if_changed "$home_dir" "skills/research/SKILL.md" "$RESEARCH_TEMPLATE"
  fi
}

case "$TARGETS" in
  claude) install_target "$CLAUDE_DIR" "CLAUDE.md" 1 ;;
  dsh)    install_target "$DSH_DIR" "AGENTS.md" 0 ;;
  both)
    install_target "$CLAUDE_DIR" "CLAUDE.md" 1
    install_target "$DSH_DIR" "AGENTS.md" 0
    ;;
  *)
    printf 'error: 未知的 DK_TARGETS=%s（可选 claude | dsh | both）\n' "$TARGETS" >&2
    exit 1
    ;;
esac

printf '写入 %d 个文件，跳过 %d 个未变化文件。\n' "$written" "$skipped"
if [ "$backup_created" -eq 1 ]; then
  printf '旧文件已备份到: <home>/backups/DK-Config/%s\n' "$TIMESTAMP"
fi
