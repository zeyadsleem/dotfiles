# Beads Workflow Skill
Decompose PRDs into a dependency graph of tasks using Beads (`bd`).

## When to Use
- When a user provides a PRD or a list of requirements.
- When starting a new feature that requires multiple steps.

## Workflow
1. **Initialize**: Run `bd init` in the project root if not already done.
2. **Decompose**:
   - Save the PRD text to `prd.md`.
   - Run `python3 /home/zeyad/.config/opencode/scripts/prd_to_beads.py prd.md`.
3. **Task Loop**:
   - Run `bd ready` to see what tasks are unblocked.
   - Run `bd update <id> --status in_progress` to start work.
   - After completing code changes, run `bd close <id>`.
   - Repeat until no tasks are left in `bd ready`.
