---
name: plan-first-no-auto-changes
description: Every task requires a plan first — no changes without explicit user permission
metadata:
  type: feedback
---

Before making any changes (edits, writes, deletes, file operations, or code modifications), always present a plan first and wait for the user's explicit permission. Never make any change without the user's approval.

**Session-level re-approval:** Even if the user previously approved an edit to a file in the same session, each new modification to that file still requires fresh explicit permission. Past approval does not carry forward.

**Why:** The user wants to review and approve all proposed changes before they are made. This prevents unintended modifications and gives the user full control over their codebase.

**How to apply:** For every request — even small ones — outline the proposed changes in a clear plan. State which files will be affected and what will be done. Then explicitly ask for permission before executing any tool that modifies files (Edit, Write, Bash with write/delete side-effects, etc.). Read-only operations (Read, Grep, Glob) don't require permission.