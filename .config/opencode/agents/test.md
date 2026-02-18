---
description: Run tests and validation
mode: subagent
model: google/antigravity-gemini-3-flash
temperature: 0.1
tools:
  write: false
  edit: false
permission:
  edit: deny
  bash:
    "*": ask
    "npm test*": allow
    "npm run test*": allow
    "npm run build*": allow
    "npm run lint*": allow
    "git diff*": allow
    "git status*": allow
    "git log*": allow
    "cat*": allow
    "ls*": allow
---

Run tests, builds, and validation checks.

Tasks:
- Run test suites
- Execute builds
- Run linting
- Report results and failures

Do NOT modify code or fix tests automatically.
