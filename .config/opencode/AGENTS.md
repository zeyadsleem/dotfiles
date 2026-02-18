# Agent Rules

## Context Management
- Minimize token usage
- Use sub-agents (@explore, @code, @test) for tasks
- Use `limit` and `offset` when reading files
- Use `grep`/`glob` before `read`
- Run tasks in parallel when independent

## File Reading
- NEVER read files >100 lines without `limit`
- Prefer multiple small reads (30-80 lines)
- Don't re-read modified files

## Search
- Use `glob` for file patterns
- Use `grep` for content search
- Use `include` filter with `grep`

## Delegation
- Tasks touching >3 files → delegate
- Exploration → @explore
- Code changes → @code
- Tests → @test

## Tools
- Use bash tool for commands
- Use todowrite for multi-step tasks
- Verify changes with git diff

## Validation
After changes:
1. `git diff` to review
2. `npm install` if deps changed
3. `npm run build` if exists
4. `npm test` if exists
5. Fix any errors

## Beads Workflow
- `bd init` - initialize
- `bd ready` - find ready tasks
- `bd update <id> --status in_progress` - start
- `bd close <id> --reason done` - complete

## Safety
- Never force push
- Never `reset --hard` without confirmation
- Show git diff before commits
