#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${CLAUDE_HOME:-$HOME/.claude}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)-$$"
BACKUP_DIR="$TARGET_DIR/backups/DK-Config/$TIMESTAMP"

FILES=(
  "CLAUDE.md"
  "skills/research/SKILL.md"
  "memory/MEMORY.md"
  "memory/file-output-level.md"
  "memory/plan-first-no-auto-changes.md"
  "memory/plan-format.md"
  "templates/plan-example.md"
)

backup_created=0
for relative_path in "${FILES[@]}"; do
  target_path="$TARGET_DIR/$relative_path"
  if [ -f "$target_path" ]; then
    backup_path="$BACKUP_DIR/$relative_path"
    mkdir -p "$(dirname "$backup_path")"
    cp -p "$target_path" "$backup_path"
    backup_created=1
  fi
done

for relative_path in "${FILES[@]}"; do
  target_path="$TARGET_DIR/$relative_path"
  mkdir -p "$(dirname "$target_path")"
  cp "$SOURCE_DIR/$relative_path" "$target_path"
done

printf 'Claude configuration installed to: %s\n' "$TARGET_DIR"
if [ "$backup_created" -eq 1 ]; then
  printf 'Previous managed files backed up to: %s\n' "$BACKUP_DIR"
else
  printf 'No existing managed files required backup.\n'
fi
