# OpenCode Configuration

> A tuned OpenCode setup with free AI models, smart agents, and automatic context management.

## Quick Start

1. **Install OpenCode** — follow [opencode.ai](https://opencode.ai) instructions
2. **Copy this config** — symlink or copy this folder to `~/.config/opencode/`
3. **Run OpenCode** — open a terminal in any project and type `opencode`
4. **Start coding** — describe your task, the orchestrator handles the rest

```bash
# From any project directory
opencode
```

The default agent is `orchestrator` — it will automatically plan, delegate, and coordinate work for you.

## Models

All models are **free** through Antigravity. No API keys needed (auth handled by the plugin).

| Model | Role | Context | Notes |
|-------|------|---------|-------|
| **Gemini 3 Flash** (default) | Main + Small model | 1M tokens | Fast, supports text/image/PDF. Has thinking variants (minimal → high) |
| **Gemini 3 Pro** | Upgrade option | 1M tokens | Smarter, for complex tasks. Thinking variants (low, high) |
| **Claude Opus 4.6 Thinking** | Orchestrator | 200K tokens | Deepest reasoning. Used by orchestrator agent |
| **MiniMax M2.5** | Alternative | 1M tokens | Text-only, large context |
| **Gemini 3 Flash Preview** | Preview | 1M tokens | Latest preview from Gemini CLI |

To switch models mid-conversation, use the model selector in OpenCode's UI.

## Agents

This config uses the **Orchestrator-Workers** pattern — inspired by how teams work.

### Primary Agents (switch with Tab)

| Agent | Purpose | Model |
|-------|---------|-------|
| **orchestrator** (default) | Plans and delegates. Never does work directly | Claude Opus |
| **build** | Hands-on coding. Direct file editing | Gemini 3 Flash |
| **plan** | Read-only analysis and planning | Gemini 3 Flash |

### Worker Sub-Agents (called with @mention)

| Worker | Access | Use For |
|--------|--------|---------|
| **@explore** | Read-only | Fast codebase search, find files/functions |
| **@code** | Read/Write | Write code, edit files, implement features |
| **@research** | Read-only | Gather information, understand code structure |
| **@test** | Read/Write | Run tests, validate changes, check builds |
| **@general** | Full access | Complex multi-step tasks |

### How It Works

```
You → Orchestrator (plans) → Spawns workers in parallel → Results back to you
```

The orchestrator keeps its context clean by only reading summaries from workers — never raw file contents.

## Skills

Two skills are installed to guide code generation:

| Skill | Purpose |
|-------|---------|
| **frontend-design** | UI/UX best practices, design system guidance |
| **react-best-practices** | React patterns, hooks, component architecture |

Skills provide domain-specific instructions that agents follow automatically.

## Key Features

### Auto Context Management
- Context is treated as precious — every token counts
- Files are read surgically with `offset` and `limit`, never in full
- Search (`grep`/`glob`) before reading to find exact locations

### Parallel Execution
- Independent tasks run simultaneously across workers
- Multiple tool calls in a single response when possible
- Workers get fresh context windows — no pollution

### Safety Permissions
Pre-configured permission system:

| Action | Policy |
|--------|--------|
| File editing | ✅ Allowed |
| Safe commands (`ls`, `git status`, `npm`) | ✅ Allowed |
| Web fetch | ✅ Allowed |
| Unknown bash commands | ⚠️ Ask first |
| Destructive commands (`rm -rf`, `sudo`, `git push -f`) | ❌ Denied |

### MCP Integration
- **Chrome DevTools** MCP server is configured for browser automation, performance tracing, and web debugging.

## File Structure

```
.config/opencode/
├── opencode.json          # Main config (models, permissions, MCP)
├── AGENTS.md              # Global agent behavior rules
├── agents/                # Per-agent instructions
│   ├── orchestrator.md
│   ├── code.md
│   ├── research.md
│   └── test.md
├── skills/                # Domain-specific skills
│   ├── frontend-design/
│   └── react-best-practices/
└── package.json           # Plugin dependencies
```

## Tips

- **Use orchestrator for big tasks** — it breaks them down and runs workers in parallel
- **Use build mode for quick edits** — press Tab to switch, no delegation overhead
- **Use plan mode to explore** — read-only, safe for understanding code before changing it
- **Let agents validate** — they run `git diff`, `npm build`, and tests automatically after changes
