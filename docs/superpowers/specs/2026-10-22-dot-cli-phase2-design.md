# dot CLI — Phase 2: the Omarchy-like layer

**Status:** Approved by the owner 2026-10-22 (scope, `dot pkg` behaviour, and the bar contents were all chosen explicitly by the owner).

**Supersedes nothing.** This document extends
[`2026-10-20-dot-cli-system-inventory-design.md`](./2026-10-20-dot-cli-system-inventory-design.md)
("Phase 1"), whose §7.6 JSON contract stays frozen and untouched.

---

## 1. Intent

Phase 1 made the machine *legible*: `dot list` and `dot status` answer "what is installed and
what is broken". The owner's complaint was that the system still feels like a collection of
parts rather than one coherent surface — there is no single place that shows the health of
the machine, no way to add a nix package without hand-editing a Nix file, no launcher that
knows what the machine owns, and no shortcut sheet.

Phase 2 builds the **operating surface** on top of the Phase 1 inventory:

| Piece | What it is | Why it matters to the owner |
|---|---|---|
| `dot health` | a cheap, always-on health probe | the bar can show the state of the system at a glance |
| `dot pkg` | declarative nix package management | adding a tool must not mean editing `packages.nix` by hand |
| `dot browse` | an fzf launcher over everything the machine owns | one keyboard-driven entry point to apps, tools and configs |
| `dot keys` | a live keybinding cheat sheet for niri | the shortcuts exist but nobody remembers them |
| The bar | an Omarchy-style waybar with health, stats, battery and clock | the desktop should look and feel finished |

## 2. Goals

1. `dot health` must answer "is this machine healthy?" in **under 300 ms** — fast enough for a
   bar module that refreshes every few seconds.
2. `dot pkg add/rm/sync` must be the only way the owner touches `nix/modules/packages.nix`.
3. `dot browse` must be a single keystroke away and must know about apps, CLI tools, scripts
   and config files.
4. `dot keys` must read the **live** niri config, so it can never drift from the real binds.
5. The bar must degrade gracefully: a machine without a battery shows no battery widget; a
   machine with a broken config link shows a red dot.
6. Nothing in Phase 2 may make `dot` slower, heavier, or less readable than Phase 1.

## 3. Non-goals

- **No new package manager.** `dot pkg` manages the nix profile only. pacman stays pacman;
  `dot` keeps printing `sudo pacman -S …` suggestions and never runs them.
- **No theme manager.** `set-theme` already exists and keeps working. Phase 2 does not touch it.
- **No `dot install` / `dot remove` for desktop apps.** The inventory is read-only for apps.
- **No migration of the machine to Omarchy.** The goal is an Omarchy-*like* feel on niri,
  not the Omarchy codebase.
- **No fzf TUI for `dot list`.** The TUI is a new command (`dot browse`); `dot list --json`
  keeps its frozen shape.

## 4. Anti-goals

- A bar widget that runs the full `dot status` (1.31 s) on a timer. That would peg a core and
  make the bar flicker; the health probe is a **separate, cheap** collector.
- A `dot pkg` that runs `sudo`. The nix profile is a *user* profile; `home-manager switch`
  needs no root and `dot` must never ask for it.
- A cheat sheet that is a hand-written markdown file. It would drift from the niri config
  within a week.
- A TUI that hides the inventory behind a fuzzy finder with no preview. The preview is where
  the value is.
- Two languages for the same thing. `dot`'s own output stays English; the two *daily-use*
  surfaces the owner asked for (the cheat sheet and the Hijri clock) are Arabic, because
  they are for the owner, not for a log.

## 5. Constraints (verified facts, not assumptions)

| Fact | Consequence |
|---|---|
| `dot status` = 1.31 s (`pacman -Qmq` 404 ms, `-Qdtq` 313 ms, `-Qq` 63 ms, `nix profile list` 64 ms, `git status` 12 ms) | the bar cannot use `dot status`; `dot health` skips pacman and nix entirely |
| `scan_configs` alone = 52 ms over ~2830 entries | a config-only health probe is affordable at a 10 s interval |
| `/sys/class/power_supply/` contains only `AC` — no battery on this machine | the battery widget must hide itself, and the owner must be told the machine exposes no battery |
| 4 cores, 11 GB RAM, Intel Broadwell-U | CPU/RAM widgets must read `/proc` directly, not shell out to `btop`/`fastfetch` |
| `home-manager switch --flake ~/dotfiles#zeyad` is the only apply path; the flake exposes exactly one `homeConfigurations."zeyad"` | `dot pkg` derives the configuration name from the flake instead of hardcoding it |
| `nix eval --impure --expr '(builtins.getFlake "<repo>").inputs.nixpkgs.legacyPackages.x86_64-linux.<name>.name'` resolves an attribute in ~2.8 s | attribute validation is available, at the cost of ~3 s per `dot pkg add` |
| `packages.nix` mixes bare names (`git`) with a multi-line `mkDerivation` block (`workmux`) | the package editor must parse the list by paren depth, not by line |
| `~/.config/waybar/` is a real directory holding runtime content (`colors.css`, `scripts/`) | new waybar scripts must be linked **per file**, never as a whole directory |
| `~/.config/niri/config.kdl` is linked per file by Home Manager; every bind is on a single line | the key parser can be line-based; a per-file link means a `home-manager switch` is needed to publish niri changes |
| `fzf` is at `/usr/bin/fzf`; `zenity` 4.2.2 and `yad` 15.0 are installed; no webkit2gtk | the cheat sheet window is `zenity --text-info`, never `yad --html` |
| `hijri-date.py` runs through `uv` and prints **English** | the Hijri clock needs an Arabic form; it must fall back to the Gregorian date when `uv`/the dependency is missing |
| `.local/bin/.gitignore` is deny-all + allowlist (`!*.sh`, `!*.py`, `!dot`, …) | any new file under `.local/bin` must be `*.sh`/`*.py` or explicitly allowlisted |
| `dot` is one self-contained Python file (1491 lines) with a `#!/usr/bin/env python3` shebang | Phase 2 stays in that file; splitting it would break the "copy this one file" property the repo depends on |

## 6. Decisions

### D1 — `dot` stays one file, organised in sections

Phase 2 adds roughly 500 lines to `.local/bin/dot`. They are added as clearly delimited
sections (`# ── health ──`, `# ── packages ──`, `# ── browse ──`, `# ── keys ──`) rather than
as a new module tree. Rationale: the script is copied by symlink into `~/.local/bin` and must
keep working with no package layout, no `__init__.py`, and no import path tricks. The cost is
a long file; the benefit is that `dot` stays installable by symlink and stays readable with
`less`.

### D2 — `dot health` is a separate collector, not a flag on `dot status`

`dot status` answers "what is wrong with everything". `dot health` answers "is the structure
of the machine sound" and is allowed to be incomplete: it looks at **config links** (broken,
stale) and **compositor spawns** (missing binaries) only. It never touches pacman, nix, or
git. It is honest about this: the tooltip says what it did and did not check.

### D3 — `dot health --json` prints exactly three keys

Waybar's `return-type: json` custom module parses `{"text", "tooltip", "class"}`. Emitting a
richer document risks the module failing to render on a waybar version that is stricter about
unknown keys. So `dot health --json` prints exactly `text`, `tooltip` and `class`; the counts
live inside the tooltip string, and the machine-readable detail stays where it already is —
`dot status --json`.

### D4 — `dot pkg` edits the file textually, never regenerates it

`nix/modules/packages.nix` is a hand-maintained Nix file that already contains a multi-line
derivation and comments. Regenerating it would destroy both. `dot pkg` therefore parses the
`home.packages` list, inserts or removes **one line** per package, and leaves every other byte
of the file alone. A package whose entry is not a bare name (the `workmux` derivation) cannot
be removed automatically and is refused with an explanation.

### D5 — `dot pkg` validates against the flake's own nixpkgs

A package is accepted only if `nix eval` resolves it in
`inputs.nixpkgs.legacyPackages.${builtins.currentSystem}`. This is the same nixpkgs the
flake builds against, so a name that validates here will build. The check costs ~3 s, which
is acceptable for a command that then runs `home-manager switch` (tens of seconds). The owner
is told the check is running.

### D6 — `dot pkg` confirms, applies, and rolls back

The sequence for `add`/`rm` is: validate → show a unified diff → ask for confirmation →
write the file → run `home-manager switch` → on failure, **restore the previous file content**
and report the error. The rollback restores the file only; it does not re-run the switch,
because the previous Home Manager generation is still active and the machine is unchanged.

`--yes` skips the confirmation (for scripted use); `--dry-run` prints the diff and stops.

### D7 — `dot browse` is a launcher *and* an inspector

fzf over every item the machine owns — desktop apps, CLI binaries, local scripts, config
files. The preview pane shows the details of the highlighted item (who owns it, where it
points, what it is), and Enter performs the action that makes sense for that kind of item:
launch an app, open a config in `$EDITOR`, copy a tool's path to the clipboard.

### D8 — `dot browse` uses a light inventory

The full inventory costs 1.2 s, almost all of it in `pacman -Qmq` and `pacman -Qdtq`, which
the browser does not need. The browser's rows come from `pacman -Qq` (63 ms) plus the nix
profile, the tool directories, the scripts and the config scan — about 150 ms in total.

### D9 — `dot show` resolves one item without building the inventory

The fzf preview calls `dot show <id>` on every keystroke. Rebuilding the inventory per
keystroke would be unusable, so `dot show` answers from targeted lookups: `shutil.which` for
a binary, a single `classify()` call for a config path, a desktop-file read for an app.

### D10 — `dot keys` parses the live niri config

The cheat sheet is generated from `~/.config/niri/config.kdl` at the moment it is opened. The
parser is line-based, because every bind in this config is on one line; a bind whose braces
do not close on the same line is skipped and counted, not guessed at.

### D11 — the cheat sheet is Arabic by default

`dot keys` prints a key → description table in Arabic, because it is a daily-use surface for
the owner. `--lang en` prints the same table in English. niri's own action names are
translated through an explicit table, with a generic fallback for anything unknown.

### D12 — the bar is waybar, configured in the repo

The bar is the existing waybar instance (`~/.config/waybar/config-niri`, already a
per-file Home Manager link). Phase 2 adds modules to that config, styles them in
`style.css`, and links the new helper scripts per file in `nix/modules/dotfiles.nix`. Nothing
new is launched; the bar the owner already has becomes the Omarchy-like one.

### D13 — the health dot reads a cache-free cheap probe

The health module runs `dot health --json` every 10 seconds. At ~100 ms per run that is
~1 % of one core. No cache file, no daemon, no background process: the probe is honest about
being a snapshot and cheap enough not to need one.

### D14 — `dot pkg sync` is the drift fix

The Phase 1 drift finding already prints `fix: dot pkg sync`. `dot pkg sync` runs
`home-manager switch` with no file edit and then re-reports the drift, so the printed hint
and the command agree.

## 7. Resolved details

### 7.1 `dot health`

```
dot health          # one human line
dot health --json   # exactly {"text", "tooltip", "class"}
```

Exit code 0 when healthy, 1 when not — the same contract as `dot status`.

**What it checks:** the config scan (`~/.config` and `~/.local/share`, depth 3, the Phase 1
exclusion list) for broken and stale links, and the niri config's spawn targets for missing
binaries. **What it does not check:** packages, nix drift, git state.

**Text form:** `● no problems` or `● 3 problems` — one line, the same dot the bar shows.

**Tooltip form:** `dot: no problems` or `dot: 2 broken · 1 missing`.

**Class form:** `ok` when nothing is wrong, `bad` when any broken/stale/missing finding
exists. There is no `warn` state, because health only reports structural damage.

### 7.2 `dot pkg`

```
dot pkg list                    # declared packages, and whether each is installed
dot pkg add <name>...           # add packages to home.packages and apply
dot pkg rm <name>...            # remove packages from home.packages and apply
dot pkg sync                    # apply the repository as it stands, then re-check drift
```

Flags: `--yes` (skip the confirmation), `--dry-run` (print the diff, change nothing),
`--config <name>` (the Home Manager configuration name; by default it is read from the flake).

**`dot pkg list`** prints one line per declared package, marked as installed or not, then the
drift summary (declared but absent, installed but undeclared).

**`dot pkg add`** does this, in order:

1. Resolve each name: if it is not a nixpkgs attribute, try to map it from a known
   binary→package table; if that fails, stop with the nix error and no change.
2. Read `nix/modules/packages.nix` and parse the `home.packages` list.
3. Skip names that are already declared.
4. Show the unified diff of the change.
5. Ask `Apply this change? [y/N]`. Without a TTY, and without `--yes`, refuse.
6. Write the file.
7. Run `home-manager switch --flake <repo>#<config>`.
8. If the switch fails, restore the file and report the error.

**`dot pkg rm`** is the same, with the removal of one line per package. A package that is not
declared is reported and skipped. A package whose entry is not a bare name is refused with an
explanation ("this entry is an expression; edit the file by hand").

**`dot pkg sync`** runs the switch with no edit and then prints the drift state.

**Never** `sudo`, never `pacman -S`, never `pacman -R`. `dot pkg` is the only mutating
command in the tool, and it only ever touches `nix/modules/packages.nix` and the user's own
Home Manager generation.

### 7.3 `dot browse`

```
dot browse
```

fzf over four kinds of item: **app**, **cli**, **script**, **config**. Each row carries a
hidden id, a label and a short detail; the preview pane is `dot show <id>`.

Enter acts on the highlighted row:

| Kind | Action |
|---|---|
| app | launch it (`gtk-launch <desktop file id>`) |
| config | open the resolved target in `$EDITOR` (default `xdg-open` for a directory) |
| cli / script | copy the absolute path to the clipboard (`wl-copy`) and print it |

`Esc` or an empty selection exits with status 0. If `fzf` is not installed, `dot browse`
prints the row list to stdout instead of failing.

### 7.4 `dot keys`

```
dot keys            # the table, in Arabic
dot keys --lang en  # the same table, in English
dot keys --gui      # the table in a scrollable window
```

The table is generated from the live niri config. Each row is a key combination, the action
as niri wrote it, and a human description.

`--gui` opens `zenity --text-info` with the same text; if `zenity` is missing it falls back
to `yad --text`, and if both are missing it prints the table to stdout.

### 7.5 The bar

Modules, in order:

| Position | Module | Source |
|---|---|---|
| left | `custom/launcher`, `niri/workspaces`, `niri/window` | unchanged |
| left | `custom/dot-health` | `dot health --json`, every 10 s |
| center | `clock` | native, unchanged |
| center | `custom/hijri` | `hijri-date.py`, Arabic Hijri date |
| right | `cpu`, `memory` | native, rounded like the other pills |
| right | `battery` | native; hidden automatically when the machine has no battery |
| right | `niri/language`, `network`, `pulseaudio`, `backlight`, `tray`, `custom/power` | unchanged |

The Hijri widget falls back to the Gregorian date when `uv` or the `hijri-converter`
dependency is unavailable, so the module is never empty.

### 7.6 The niri binding for the cheat sheet

`Super+Shift+Slash` opens the cheat sheet window. It is free in the current config
(`Mod+Shift+Slash` is niri's own hotkey overlay, and is left alone).

### 7.7 Arabic month names and the Hijri fallback

`hijri-date.py` gains an Arabic output (`١٠ جمادى الأولى ١٤٤٨ هـ`) and keeps `--english` for
the old form. The waybar wrapper `.config/waybar/scripts/hijri-clock.sh` runs it, discards
stderr, and falls back to `date +%F` if the script fails.

### 7.8 Safety

- `dot pkg` writes only `nix/modules/packages.nix`, and only after a confirmation.
- `dot pkg` never runs `sudo` and never touches pacman.
- `dot browse` launches an app only when the user presses Enter on that row.
- `dot health`, `dot keys`, `dot show` and `dot list`/`dot status` remain strictly read-only.
- Every command that can change something prints what it is about to do first.

### 7.9 Tests

The existing suite is 101 tests in `tests/test_dot.py` (stdlib `unittest`). Phase 2 adds
tests in the same file, in the same style, covering: the health probe's three-key JSON and
its severity mapping; the package list parser (bare names, comments, the multi-line
derivation, a missing list); add/remove round-trips; the confirmation gate; the rollback;
the attribute validation; the niri bind parser; the Arabic/English description tables; the
fzf row builder and the fallback when fzf is missing; and the waybar scripts' syntax.

### 7.10 Documentation

`README.md` gains a section for the new commands and the bar. This spec's status becomes
"Implemented". The Phase 1 ledger is not touched.

## 8. Open questions

None. Every decision that changes the shape of the work was made by the owner on 2026-10-22:
the scope, the fact that `dot pkg` applies the change itself, and the contents of the bar.
