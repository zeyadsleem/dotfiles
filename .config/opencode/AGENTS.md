# Global Agent Rules

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

## Safety Rules

- Never run destructive commands without user confirmation
- Never force push to git
- Never reset --hard without explicit request
- Always show git diff before suggesting commits
- Keep backups when making major changes
