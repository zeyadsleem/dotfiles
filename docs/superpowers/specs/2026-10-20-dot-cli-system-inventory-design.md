# Design: `dot` — a system CLI layer for the workstation

- **Date:** 2026-10-20
- **Status:** **Approved by the owner 2026-10-21** — v2 corrected against a live machine audit
- **Scope:** Phase 1 — system inventory (`dot list`) and health check (`dot status`)
- **Author:** designed with zeyad (owner of the machine)

## 1. Intent and the why

Zeyad's machine is a working Arch/EndeavourOS workstation with a Niri desktop, Waybar, Kitty,
Neovim, tmux, Yazi, OpenCode and a Nix Home Manager layer over the dotfiles repo. The tooling is
good. The *experience* of the tooling is not:

- **"I can't tell what's installed."** 1103 pacman packages, 22 AUR/foreign, 58 Nix CLI binaries,
  92 desktop entries, 57 binaries across mise/uv/go/vite-plus/opencode, plus hand-written scripts
  in `~/.local/bin` — with no single place that shows all of it or says who owns what.
- **"I don't know how to deal with Nix."** Nix is a visible, load-bearing layer (flakes, store
  paths, generations) for a benefit (version pinning) that does not outweigh its cognitive cost here.
- **"I want it easy and beautiful."** The reference point is *Omarchy's coherence*, not Omarchy:
  one command does one thing across the whole system, and the system is discoverable without
  knowing which tool owns what.

Phase 1 delivers the discovery layer: two commands that make the machine legible. Everything else
(`dot install`, `dot theme`, `dot update`, bar modules, shortcut cheat sheet) is Phase 2+ and is
deliberately out of scope here.

## 2. Goals

1. **One command answers "what is on this machine?"** — grouped by source, with counts, including
   the sources nobody thinks about (mise, uv, go, vite-plus, opencode).
2. **One command answers "what is broken or drifted?"** — findings grouped by severity, each with
   a copy-pasteable fix.
3. **Zero Nix knowledge required.** The user never types `nix`, `flake`, `switch` or `generations`.
4. **The inventory does not depend on the Nix decision.** Whether Nix stays or goes later, the
   inventory must report the machine as it actually is *today*.
5. **Machine-readable output** (`--json`) with a stable schema, for scripting and for a future TUI.
6. **Safe by default** — read-only. No Phase 1 command writes to `~/.config`, installs anything, or
   touches anything requiring sudo.

## 3. Non-goals

- Not a package manager. `dot install` / `dot remove` / `dot pkg` are Phase 2.
- Not a fuzzy TUI yet (`dot list --fuzzy` is Phase 2; Phase 1 output pipes into `fzf` fine).
- Not a NixOS migration, and not a decision to remove Nix — tracked separately, does not block
  Phase 1 (§8).
- Not a GUI app.
- Not a replacement for the existing `set-theme` script, which works and stays as-is.
- Not a re-implementation of `pacman -Q` dumps. 1100 raw lines is not an inventory.

## 4. Anti-goals

- A command that dumps everything and calls it "discovery".
- Requiring the user to know which manager owns which package or config before using it.
- Any command that needs `sudo` behind the user's back, or that mutates state in a "check" mode.
- A second source of truth: the dotfiles repo stays the source of truth for configs; `dot` only
  *reads* and *reports*.
- A `dot status` that can never exit 0 in the normal state (see §7.4 — repo-dirty is INFO, not a
  finding).

## 5. Constraints (verified against the live machine)

| Constraint | Consequence |
|---|---|
| EndeavourOS, Intel Broadwell-U integrated GPU, no NVIDIA | `pacman`/`yay` are the system tools; no GPU special-casing |
| Python 3.14 present; repo already ships Python scripts in `~/.local/bin` | Python 3 stdlib only — no pip, no venv |
| `~/.local/bin` → `~/dotfiles/.local/bin` (relative symlink), on `$PATH` | New commands land in the repo and work immediately — no install step |
| **`~/.local/bin/.gitignore` is deny-all with a whitelist** (`!*.sh`, `!*.py`, named files) | `git check-ignore` confirms `.local/bin/dot` would be **ignored** — the whitelist MUST get a `!dot` entry or the tool never reaches a fresh clone (§9) |
| `nix/modules/` has **7** modules; `scripts.nix` does not exist (README claims 8) | README needs a correction; `~/.local/bin` is a plain repo symlink, not HM-managed |
| `~/.config` = 137 entries (11 symlinks, 113 dirs, 13 files); `~/.local/share` = 97 (1 symlink) | Depth-1 classification finds **zero** broken links — the real breakage is one level down |
| 5 broken symlinks live at depth 2: `sway/config`, `mako/config`, `waybar/config`, `waybar/config-mango`, `ghostty/config` → repo files that do not exist | The scan must validate links **inside** config dirs, at depth 2 |
| A recursive depth-2 scan also finds ~118 broken links in AI-tool skill farms (`~/.config/crush/skills/*`, `~/.config/goose/skills/*`) and Chromium `Singleton*` IPC sockets | An exclusion list is required or the report is pure noise (§7.1) |
| `~/.config/lazygit` → `/nix/store/fi23hv3z…-home-manager-files/.config/lazygit` → `/nix/store/smisxx…-source/.config/lazygit` | A **frozen in-store copy from an older generation**; the live repo is not what the app reads (content is identical *today*, but edits to the repo would not apply) |
| Profile `bin` = 58 visible binaries + 18 hidden `.foo-wrapped` = 76; `packages.nix` declares 25 names | Package→binary mapping is **not** derivable by name (`neovim`→`nvim`, `ripgrep`→`rg`, `libnotify`→`notify-send`, `antigravity`→`antigravity-ide`) |
| Profile contains binaries no declared package provides (`man`, `apropos`, `mandb`, `exa`, `git-*`, `ffplay`, `ffprobe`, `zipinfo`, …) | Drift detection must be **bidirectional**, not only "declared but missing" |
| Repo is dirty: `packages.nix` declares `traceroute` (not installed), `Thunar/accels.scm` modified | Drift reporting must compare declaration vs installed |
| Niri config spawns `polkit-gnome-authentication-agent-1` (absolute path) — **not installed** — and `orca` — **not installed** | The MISSING class has at least two real members, and path-vs-binary detection needs two rules |

## 6. Decisions

### 6.1 Command surface (Phase 1)

```
dot list [--all] [--json] [--ownership] [--apps|--cli|--configs|--scripts|--sources]
dot status [--json]
dot --help
```

- `dot list` — the inventory. Default = curated sections + counts. `--all` = every item, ungrouped,
  for piping. `--ownership` = the config-ownership map only.
- `dot status` — the health check. Exit `0` = no findings, `1` = findings found (scriptable).
- Both support `--json`.

### 6.2 Implementation

Single Python 3 script, `~/dotfiles/.local/bin/dot`, stdlib only, `argparse` subcommands.

*Why Python and not Bash+jq:* the work is set/graph work — reconciling eight package sources,
walking a symlink forest, diffing declared-vs-installed — and the output must be both a human
table and JSON from one pass. Bash would need a jq pipeline per view and would be fragile in
exactly the places that matter. The repo already ships Python scripts, so this is consistent.

*Why one file and not a package:* the whole tool is one command; a package adds install machinery
the user does not want. The file is organised in sections (data sources → model → renderers) so it
stays readable.

### 6.3 Data sources (all read-only, no sudo)

| Source | Command / path | Notes |
|---|---|---|
| System packages | `pacman -Qq` | 1103 |
| Foreign / AUR | `pacman -Qmq` | 22 |
| Orphans | `pacman -Qdtq` | 7 — advisory only |
| Nix profile | `~/.local/state/nix/profiles/profile/bin` | 58 visible + 18 hidden wrappers |
| Nix home path | `~/.local/state/nix/profiles/home-manager/home-path/bin` | identical today; profile is canonical, `home-path` is the fallback |
| Declared Nix packages | parse `nix/modules/packages.nix` | 25 names |
| Desktop entries | `/usr/share/applications/*.desktop`, `~/.local/share/applications/*.desktop` | 65 + 27 |
| mise shims | `~/.local/share/mise/shims` | 30 |
| Go tools | `~/go/bin` | 2 |
| uv tools | `~/.local/share/uv/tools` | 3 |
| vite-plus | `~/.vite-plus/bin` | 20 |
| opencode | `~/.opencode/bin` | 2 |
| Local scripts | `~/.local/bin` | 28 entries: repo-tracked (git allowlist) vs untracked local binaries |
| Config ownership | scan `~/.config` + `~/.local/share` | §7.1 |
| Repo state | `git status` in `~/dotfiles` | INFO only |
| Outdated packages | `checkupdates` | only when explicitly asked; it hits the network — never in the default path |

Every Nix-dependent source degrades gracefully: if Nix is removed later, the tool reports
"Nix: not present" instead of failing.

### 6.4 Ownership model

Each entry under `~/.config` / `~/.local/share` is classified as exactly one of:

| Class | Detection | Meaning |
|---|---|---|
| `home-manager` | symlink → `/nix/store/…-home-manager-files/…` of the **current** generation | Managed by Home Manager; the final target is the live repo |
| `home-manager-stale` | symlink → `/nix/store/…-home-manager-files/…` of an **older** generation | Managed, but pointing at a dead generation → STALE finding |
| `frozen-store` | symlink chain ends in a `-source` store path | The app reads a frozen copy, not the repo → STALE finding (the `lazygit` case) |
| `dotfiles` | symlink → `~/dotfiles/…` | Managed by the repo directly |
| `local` | symlink → anywhere else | A symlink the user or a tool made |
| `runtime` | real directory/file created by an app | Never touched; counted, not flagged |
| `broken` | symlink whose target does not exist | Needs a decision: restore or remove |

### 6.5 Findings and severities

| Severity | Examples | Fix style |
|---|---|---|
| `BROKEN` | `~/.config/ghostty/config` → missing repo file | `rm <path>` or restore the file |
| `STALE` | `~/.config/lazygit` → frozen store copy of an old generation | re-point at the live repo |
| `MISSING` | a binary the Niri config spawns is not installed (`orca`, `polkit-gnome-authentication-agent-1`) | `sudo pacman -S <pkg>` |
| `DRIFT` | declared in `packages.nix` but not installed (`traceroute`); profile binaries with no declared owner | `dot pkg sync` (Phase 2) or the raw `nix … switch` shown as-is |
| `ORPHAN` | 7 explicitly-installed packages no longer required | `sudo pacman -Rns <pkgs>` — advisory, never auto-run |
| `INFO` | repo has uncommitted changes; 113 runtime config dirs | never affects the exit code |

Findings are ordered by severity, not by discovery order.

## 7. Resolved design details

### 7.1 Scan depth and exclusions *(my call — the builder-check's top question)*

- Depth 1 for classification of every entry in `~/.config` and `~/.local/share`.
- Depth 2 **inside** those directories to validate links (this is where the 5 real broken links are).
- Default exclusion list for tool-managed subtrees that generate their own symlink farms and
  runtime sockets: `~/.config/{crush,goose,opencode,Codex,BraveSoftware,Local,chromium,Antigravity}`
  and any `Singleton*` entry.
- User-extensible via `~/.config/dot/exclude` (one path per line, same spirit as `.gitignore`).
- Result: `dot status` reports the 5 genuine breakages, not 150 noise items.

### 7.2 The `local` class is split *(my call)*

~230 of the 294 symlinks on this machine are made by AI tools and browsers, not by the user. `local`
is therefore reported as two sub-classes — `local:user` (points into `$HOME`, e.g. `~/go/bin`,
`~/.local/share/uv/tools`) and `local:tool` (points into tool-owned trees). Default output counts
both; `--ownership` lists `local:user` in full and only counts `local:tool`.

### 7.3 Nix drift is bidirectional *(my call)*

- **Declared → installed:** compare `packages.nix` names against the profile binaries, using the
  `nix` CLI (`nix path-info --json`) when available to map packages to their binaries, and falling
  back to name matching when it is not. `traceroute` is the current positive.
- **Installed → declared:** profile binaries whose owning package is not declared. When the `nix`
  CLI is unavailable, report them as "unattributed binaries (transitive or manual)" rather than
  claiming a false owner.
- The profile is canonical; the HM `home-path` is the fallback when the profile is missing.

### 7.4 The exit-0 contract *(my call)*

`dot status` exits `0` only when there are no findings at severity `BROKEN`, `STALE`, `MISSING` or
`DRIFT`. `INFO` (dirty repo, runtime dirs) never affects the exit code, and untracked files are not
reported as drift — a dotfiles repo is uncommitted by default and flagging that would make the
tool cry wolf every day.

### 7.5 Spawn-binary extraction *(my call)*

Parse `~/.config/niri/config.kdl` for `spawn`, `spawn-sh`, `spawn-at-startup` and
`spawn-sh-at-startup`:

1. For `spawn`/`spawn-at-startup`: take the first token.
2. For `spawn-sh`: split the string on `|`, `||`, `&&`, `;` and take the first word of each
   segment, skipping shell builtins (`cd`, `exec`, `export`, `source`, `test`, `echo`, `printf`,
   `command`, `builtin`).
3. Resolution: a token containing `/` is treated as a path (expand `~`, check existence);
   otherwise it is looked up in `$PATH`.
4. Every unresolved token is a `MISSING` finding, and the finding names the keybinding that
   triggers it.

Also checked: scripts referenced by the Niri config under `~/.config/niri/scripts/`, and the
`~/.local/bin` scripts referenced by Niri and Waybar configs.

### 7.6 `--json` schema *(my call — frozen now, because Phase 2 consumes it)*

```jsonc
// dot list --json
{
  "tool": "dot", "version": "1", "command": "list",
  "generated_at": "2026-10-20T21:04:00Z",
  "summary": { "total": 0, "by_source": {}, "by_owner": {} },
  "sections": {
    "apps":    { "count": 0, "items": [] },
    "cli":     { "count": 0, "items": [] },
    "scripts": { "count": 0, "items": [] },
    "configs": { "count": 0, "items": [] }
  }
}

// dot status --json
{
  "tool": "dot", "version": "1", "command": "status",
  "ok": true,
  "counts": { "broken": 0, "stale": 0, "missing": 0, "drift": 0, "info": 0 },
  "findings": [
    { "id": "broken-symlink", "severity": "broken", "path": "", "detail": "",
      "fix": "", "command": "" }
  ]
}
```

`dot list --all --json` emits every item; the default view emits the same shape with the `items`
arrays populated per section and truncated lists in `summary`.

### 7.7 Output look

Plain text, 80-column friendly, colored only when stdout is a TTY and `NO_COLOR` is unset. Severity
has one color each (broken = red, stale = magenta, missing = orange, drift = yellow, ok = green,
muted = dim). Headers are single-line rules rather than boxes — no ASCII art, it must survive a
60-column terminal.

```
$ dot list
System inventory · EndeavourOS · zeyad
────────────────────────────────────────────────────────────
  Desktop apps      92     system 65  ·  user 27
  CLI packages    1159     pacman 1103  ·  nix 56
  Tooling            57     mise 30  ·  vite-plus 20  ·  uv 3  ·  go 2  ·  opencode 2
  AUR / foreign      22
  Orphans             7     safe to remove
  Managed configs    12     home-manager 11  ·  repo 1
  Local scripts      28     repo 14  ·  local 14

  Top CLI: btop  ffmpeg  git  lazygit  nvim  rg  tmux  zoxide
  Full lists: dot list --all --cli
```

```
$ dot status
● 9 findings — 5 broken, 1 stale, 2 missing, 1 drift

BROKEN (5)
  ✗ ~/.config/ghostty/config → ~/dotfiles/.config/ghostty/config (target missing)
      fix: rm ~/.config/ghostty/config
  …

STALE (1)
  ~ ~/.config/lazygit → frozen store copy (old generation)
      the app reads the store copy, not your repo — edits don't apply
      fix: re-point the link at ~/dotfiles/.config/lazygit

MISSING (2)
  ✗ Niri spawns `orca` (Super+Alt+S) — not installed
      fix: sudo pacman -S orca
  ✗ Niri spawns `polkit-gnome-authentication-agent-1` (at startup) — not installed
      fix: sudo pacman -S polkit-gnome

DRIFT (1)
  ~ `traceroute` declared in nix/modules/packages.nix but not installed
      fix: dot pkg sync
```

The sample output is **illustrative, not normative** — the counts come from the audit above but the
tool reports whatever it finds on the day.

### 7.8 Safety rules

- Phase 1 performs no writes anywhere; every value is computed live.
- Nothing is removed or installed without the user running the printed command themselves.
- `dot status` never runs `checkupdates` (network) unless explicitly asked.
- No `sudo` is ever invoked by `dot` itself.

### 7.9 Tests

`~/dotfiles/tests/test_dot.py`, stdlib `unittest` (no pytest dependency):

```bash
python3 -m unittest discover -s ~/dotfiles/tests
```

Covers: ownership classification (HM symlink, stale-generation HM symlink, frozen-store symlink,
repo symlink, runtime dir, broken link), the declared-vs-installed Nix diff, spawn-binary
extraction (including the `spawn-sh` pipeline form and absolute-path form), severity ordering, and
the `--json` shape. Tests build fixture trees under `tests/fixtures/` — never the real `~/.config`.

### 7.10 Docs

- `README.md`: a "The `dot` CLI" section (what it is, the commands, how to run it).
- `README.md` correction: it claims 8 modules in `nix/modules/`; there are 7 (`scripts.nix` does not
  exist).
- This spec stays as the record of Phase 1 decisions.

## 8. The Nix decision (tracked, not blocking)

Phase 1 reports Nix as one of several sources and works whether or not Nix remains. Two options
stay open, and neither changes Phase 1:

- **A1 — keep Nix hidden:** the `dot` commands wrap Home Manager; the user never writes a flake
  command again. Least disruption; the repo keeps its current structure.
- **A2 — remove Nix:** the CLI tools come from pacman/yay, configs become plain symlinks managed by
  an `install.sh` (the repo's pre-Home-Manager model). Maximum simplicity; loses version pinning and
  reproducibility.

Decision inputs are exactly what Phase 1 produces: `dot list --cli` (what the Nix layer actually
gives you: 58 binaries, 25 declared packages) and `dot status` drift findings (how much of it is
undeclared). That is the data needed to judge whether pinning earns its keep.

## 9. Phase 1 prerequisites (repo changes that must land with the tool)

1. **`.local/bin/.gitignore`: add `!dot`** — without it the tool is ignored by git and never
   reaches a fresh clone. *Blocking.*
2. **README.md:** correct "8 modules" → 7, and document the `dot` CLI.
3. `tests/` directory with the fixture tree and the unittest file.

## 10. Phase 2 (not in this spec, listed so the seams are designed for)

`dot install` / `dot remove` (pacman + yay + Nix, correct source auto-detected), `dot pkg
add|rm|sync` (edits `packages.nix` and switches Home Manager without the user writing flakes),
`dot theme <name>` (wraps the existing `set-theme`), `dot update` (pacman + Nix + configs with a
summary), `dot list --fuzzy` (fzf TUI), Waybar modules in the Omarchy style, and a shortcut cheat
sheet window.

## 11. What the builder must still decide

1. Exact wording of fix hints (printed verbatim by the user).
2. Which color for each severity, and the dim/muted styling for secondary lines.
3. How many CLI names the default view prints before truncating (proposal: 12) and where the full
   list lives.
4. Whether `dot status` also checks Waybar/Niri config references beyond spawn binaries (CSS
   includes, script paths) — proposal: yes, same `MISSING` class.
5. The default exclusion list in §7.1 — exact entries, kept as data in the script.

## 12. Owner decisions (2026-10-21)

1. **Noise policy — decided:** `dot status` reports what zeyad owns plus real hard failures. The
   default exclusion list in §7.1 stands as written; the AI-tool skill farms and the Chromium
   runtime sockets are not findings.
2. **Output form — decided:** plain coloured text first. The fzf TUI stays in Phase 2 and will
   consume the frozen `--json` schema in §7.6.
3. **Scope — decided:** Phase 1 = `dot list` + `dot status` only.

## 13. Calls the builder made (for review, not up for debate)

- Scan depth: 1 for classification, 2 for link validation, with a hardcoded default exclusion list
  plus `~/.config/dot/exclude` for user additions (§7.1).
- `local` split into `local:user` and `local:tool` (§7.2).
- Nix drift bidirectional; `nix` CLI used when available, name-matching fallback otherwise (§7.3).
- Repo-dirty and runtime dirs are `INFO`, never affect the exit code (§7.4).
- `--json` schema frozen now (§7.6), because Phase 2 consumes it.
- Output is plain text with single-line rules, no ASCII art (§7.7).
