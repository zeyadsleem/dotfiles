# Global Agent Rules

## Automatic Context Management (ALWAYS ACTIVE)

> These rules apply to EVERY interaction automatically. No manual reminders needed.

### Core Principles:
1. **Context is precious** — treat every token like it costs money. Minimize context usage at all times.
2. **Delegate, don't accumulate** — use sub-agents (@explore, @code, @test) instead of doing everything in one agent. Each sub-agent gets a fresh context window.
3. **Read surgically** — NEVER read entire files. Always use `limit` and `offset` parameters. Start with 50-100 lines around the area of interest.
4. **Search before reading** — use `grep` to find the exact line numbers first, THEN read only those lines with `read` using offset/limit.
5. **Parallel over sequential** — when tasks are independent, spawn multiple sub-agents or tool calls in parallel.

### File Reading Rules (MANDATORY):
- **NEVER** use `read` without `limit` on files > 100 lines. Default to `limit: 100`.
- **ALWAYS** use `grep` or `glob` first to locate what you need, then `read` with targeted `offset` and `limit`.
- **Prefer** multiple small reads (30-80 lines each) over one large read.
- **NEVER** re-read a file you already read in this conversation unless it was modified.
- When exploring a directory, read the directory listing first, then only the relevant files.

### Search Rules (MANDATORY):
- Use `glob` to find files by name pattern — NEVER use `bash find`.
- Use `grep` to search file contents — NEVER use `bash grep` or `bash rg`.
- Use `grep` with `include` filter to narrow searches to relevant file types.
- Combine `glob` + `grep` in parallel for fastest results.

### Sub-Agent Delegation Rules:
- **Any task touching > 3 files** → delegate to a sub-agent.
- **Any exploration task** → use @explore (it's READ-ONLY and lightweight).
- **Any code change** → use @code (keeps implementation details out of orchestrator context).
- **Any test run** → use @test (keeps test output out of orchestrator context).
- The orchestrator should ONLY see summaries, never raw file contents.

### Response Efficiency:
- Keep summaries to 3-5 bullet points maximum.
- Don't repeat file contents back to the user — summarize what was found/changed.
- Don't explain what you're about to do in detail — just do it.
- After edits, show a brief `git diff` summary, not the full file.

## Orchestrator-Workers Pattern (DEFAULT WORKFLOW)

All agents follow the Orchestrator-Workers pattern by default. The `orchestrator` agent is the default primary agent.

### How It Works:
1. **Orchestrator** (العقل المدبر) = The brain. Plans, coordinates, reviews. NEVER does work directly.
2. **Workers** (العضلات) = Sub-agents. Execute specific tasks delegated by the orchestrator.
3. **Parallel Execution** = Workers run simultaneously to save time and keep context clean.

### Why This Pattern:
- **Context Window stays clean**: Orchestrator only reads summaries, not raw files (~5-10% usage instead of 40%+)
- **Less hallucination**: Each worker focuses on one small task with less context noise
- **Higher quality**: Specialized focus per worker = better results
- **Handles complex tasks**: Can solve problems 10x harder than a single agent

### Agent Hierarchy:
- **orchestrator** (primary) - Tab to switch. Plans and delegates. Uses Claude Opus (smartest model).
- **build** (primary) - Tab to switch. Direct coding when you want hands-on work.
- **plan** (primary) - Tab to switch. Read-only analysis and planning.

### Available Workers (Sub-agents):
- **@explore** - Fast codebase search (READ-ONLY)
- **@code** - Write/edit code, implement features
- **@general** - Complex multi-step tasks, full access
- **@research** - Gather information (READ-ONLY)
- **@test** - Run tests, validate changes

## Tool Usage Rules (MANDATORY)

1. **Always use bash tool - never write commands as text**
   - NEVER output shell commands in plain text when you can use the bash tool
   - ALWAYS execute commands through the bash tool
   - This applies to: git, npm, python, docker, and all system commands

2. **Use todowrite for multi-step tasks**
   - Track progress with the todowrite tool
   - Update todos as you complete steps

3. **Verify changes**
   - After editing files, read them to verify changes
   - Use git diff to see what changed

## Agent Usage Guide

**Use @explore** when you need to:
- Quickly find files by patterns
- Search code for keywords
- Answer questions about the codebase

**Use @research** when you need to:
- Explore the codebase structure
- Find specific files or functions
- Understand how something works
- Gather information before implementing

**Use @test** when you need to:
- Run tests and verify functionality
- Check build status
- Validate changes
- Get test coverage reports

**Use @code** when you need to:
- Write new code
- Modify existing files
- Implement features or fixes
- Install dependencies

## SDLC Workflow

### Using Orchestrator (Recommended for large codebases):
1. Switch to **orchestrator** agent (Tab key)
2. Describe your task - it will automatically:
   - Break it into sub-tasks
   - Spawn workers in parallel
   - Coordinate and review results
   - Report back to you

### For direct hands-on work:
1. Switch to **Build** mode (Tab key)
2. Work directly with the code

### For planning only:
1. Switch to **Plan** mode (Tab key)
2. Analyze without making changes

## Validation Rules

After implementing code changes:
1. Run `git diff` to review changes
2. Run `npm install` if dependencies changed
3. Run `npm run build` if it exists
4. Run `npm test` if it exists
5. Check for errors and fix them

If validation fails, fix the issues and re-run validation.

## Project Management (Beads Workflow)

Beads is a git-backed issue tracker for AI agents. Official docs: https://steveyegge.github.io/beads/

### Workflow:
1. **Initialize** (once per project): `bd init`
2. **Create from PRD**: `python /home/zeyad/.config/opencode/scripts/prd_to_beads.py prd.md`
3. **Find ready work**: `bd ready` or `bd ready --json` (for agents)
4. **Start task**: `bd update <id> --status in_progress`
5. **Complete task**: `bd close <id> --reason "done"`
6. **View progress**: `bd stats`, `bd blocked`, `bd dep tree <id>`

### Key Commands:
- `bd list` - list all issues
- `bd create "title" -p 1 -t task` - create new task
- `bd dep add <child> <parent>` - add dependency
- `bd ready --priority 1` - filter by priority

## Safety Rules

- Never run destructive commands without user confirmation
- Never force push to git
- Never reset --hard without explicit request
- Always show git diff before suggesting commits
- Keep backups when making major changes
