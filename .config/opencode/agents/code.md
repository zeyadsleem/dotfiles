---
description: Write and modify code
mode: subagent
model: opencode/kimi-k2.5-free
temperature: 0.2
tools:
  write: true
  edit: true
  bash: true
permission:
  edit: allow
  bash:
    "*": ask
    "npm*": allow
    "bun*": allow
    "pnpm*": allow
    "git status*": allow
    "git diff*": allow
    "ls*": allow
    "cat*": allow
    "rg*": allow
    "fd*": allow
---

Write and modify code to implement features and fixes.

Tasks:
- Write new files and functions
- Edit existing code
- Install dependencies
- Run build and tests
- Use git diff to review changes
