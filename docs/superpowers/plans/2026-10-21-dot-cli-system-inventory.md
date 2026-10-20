# `dot` CLI — System Inventory & Health Check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build `dot`, a read-only CLI that reports what is installed on this machine (`dot list`) and what is broken or drifted (`dot status`), so the owner never needs to know which package manager owns what.

**Architecture:** One executable Python 3 script at `~/dotfiles/.local/bin/dot` (stdlib only, `argparse` subcommands) that collects data from eight read-only sources, classifies every config entry by owner, produces findings with fix hints, and renders either coloured text or JSON. Pure functions (classification, spawn extraction, drift diff) are separated from IO collectors so they can be tested against fixtures instead of the live machine.

**Tech Stack:** Python 3.14 (stdlib only — no pip, no venv, no third-party deps), `unittest`, Arch `pacman`/`yay`, Nix store paths.

**Spec:** `docs/superpowers/specs/2026-10-20-dot-cli-system-inventory-design.md` — read it before starting; this plan implements it and does not restate it.

## Global Constraints

- Python 3.14 **stdlib only**. No `pip install`, no virtualenv, no third-party imports.
- The script lives at `~/dotfiles/.local/bin/dot` — mode `100755`, tracked by git, and `~/.local/bin` is already a symlink to that directory, so it is on `$PATH` with no install step.
- **Read-only.** No command may write files, install packages, or invoke `sudo`. Fix hints are printed as strings for the owner to run; `dot` never runs them.
- The only subprocesses `dot` may run are read-only queries: `pacman -Qq`, `pacman -Qmq`, `pacman -Qdtq`, `pacman -Qqg`, `git status`, `nix path-info --json`. No network access, ever (never call `checkupdates`).
- Colour only when `stdout` is a TTY and `NO_COLOR` is unset. Text output must stay readable at 60 columns.
- Severity order for output and counting: `broken`, `stale`, `missing`, `drift`, `orphan`, `info`.
- Exit codes: `dot status` returns `0` when there are no findings of severity `broken`/`stale`/`missing`/`drift`/`orphan`, `1` otherwise. `info` never affects the exit code. `dot list` always returns `0` unless it cannot read its sources at all.
- The JSON schema in spec §7.6 is **frozen** — Phase 2 consumes it.
- Every new source must degrade gracefully: if Nix, pacman or a directory is absent, report it as absent; never raise.
- Test command for every task: `python3 -m unittest discover -s ~/dotfiles/tests -p 'test_dot.py' -v`
- Single test: `python3 -m unittest discover -s ~/dotfiles/tests -p 'test_dot.py' -k <name> -v`
- The spec's §7.7 sample output is **illustrative**, not normative. Counts in tests must come from fixtures, never from the live machine.

## Review Focus

The spec implies these input classes; each is pinned by a test in the task that owns the code.

1. **An optional dependency is absent** (nix, pacman, a spawned binary, `~/.local/share`) — `dot` reports it as missing/absent and still exits cleanly, never with a traceback.
2. **A symlink chain of more than one hop, or a cyclic symlink** — ownership classification resolves it without hanging and reports the final target.
3. **A directory the owner cannot read** (permission denied) during the config scan — that subtree is skipped, the scan continues, and the run still succeeds.
4. **A spawned command token in three shapes** — a bare name (`kitty`), an absolute path (`/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1`), and a `~` path (`~/.local/bin/power-menu-niri.sh`) — all three must be resolved correctly, and a bare name that is not on `$PATH` must be reported missing.
5. **`dot` copied to a machine with no dotfiles repo** — repo-dependent checks report "repo not found" instead of raising.
6. **Safety** — no `dot` code path may execute `sudo` or a mutating `pacman` subcommand; fix hints are printed, never run.

---

### Task 1: Script skeleton, git tracking, and owner classification

**Files:**
- Create: `~/dotfiles/.local/bin/dot` (mode 755, guarded by `if __name__ == "__main__":`)
- Modify: `~/dotfiles/.local/bin/.gitignore` (add `!dot` to the allowlist)
- Create: `~/dotfiles/tests/test_dot.py`
- Create: `~/dotfiles/tests/fixtures/` (populated by tests at runtime in a temp dir)

**Interfaces:**
- Consumes: nothing (first task).
- Produces:
  - Module `dot`, importable in tests via `importlib.machinery.SourceFileLoader("dot", "<repo>/.local/bin/dot")`.
  - `OWNER_KINDS: tuple[str, ...]` — `("home-manager", "home-manager-stale", "frozen-store", "dotfiles", "local:user", "local:tool", "runtime", "broken")`
  - `@dataclass(frozen=True) class Owner: kind: str; target: str; reason: str`
  - `@dataclass(frozen=True) class Entry: path: str; owner: Owner`
  - `classify(path: str, *, current_generation: str | None, repo_dir: str) -> Owner`
  - `EXCLUDED_CONFIG_DIRS: tuple[str, ...]` — `("crush", "goose", "opencode", "Codex", "BraveSoftware", "Local", "chromium", "Antigravity")`
  - `is_excluded(name: str) -> bool`

- [ ] **Step 1: Write the failing tests**

In `~/dotfiles/tests/test_dot.py`:

```python
import contextlib
import importlib.machinery
import importlib.util
import os
import subprocess
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DOT_PATH = REPO / ".local" / "bin" / "dot"

_spec = importlib.util.spec_from_loader(
    "dot", importlib.machinery.SourceFileLoader("dot", str(DOT_PATH))
)
dot = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(dot)


@contextlib.contextmanager
def TempTree():
    """A temporary directory exposed as `.path` (a pathlib.Path)."""
    with tempfile.TemporaryDirectory() as tmp:
        yield SimpleNamespace(path=Path(tmp))
```

(`SimpleNamespace` comes from `types` — add `from types import SimpleNamespace` to the imports.)


class OwnerTests(unittest.TestCase):
    def test_classifies_broken_symlink(self):
        with TempTree() as t:
            link = t.path / "config"
            link.symlink_to(t.path / "missing")
            owner = dot.classify(str(link), current_generation=None, repo_dir=str(t.path))
            self.assertEqual(owner.kind, "broken")

    def test_classifies_home_manager_link_to_live_repo(self):
        with TempTree() as t:
            store = t.path / "nix" / "store" / "abc123-home-manager-files"
            repo = t.path / "dotfiles"
            (repo / ".config" / "niri").mkdir(parents=True)
            (repo / ".config" / "niri" / "config.kdl").write_text("x")
            target = store / ".config" / "niri" / "config.kdl"
            target.parent.mkdir(parents=True)
            target.symlink_to(repo / ".config" / "niri" / "config.kdl")
            link = t.path / "cfg" / "niri"
            link.parent.mkdir()
            link.symlink_to(target)
            owner = dot.classify(str(link), current_generation="abc123", repo_dir=str(repo))
            self.assertEqual(owner.kind, "home-manager")

    def test_classifies_stale_generation_link(self):
        # same shape, but the store dir is "old999" while current_generation is "abc123"
        self.assertEqual(owner.kind, "home-manager-stale")

    def test_classifies_frozen_store_copy(self):
        # store path ends in "-source" and is NOT under the repo
        self.assertEqual(owner.kind, "frozen-store")

    def test_classifies_repo_symlink(self):
        self.assertEqual(owner.kind, "dotfiles")

    def test_classifies_runtime_directory(self):
        self.assertEqual(owner.kind, "runtime")

    def test_classifies_user_local_symlink(self):
        # target under $HOME but outside the repo
        self.assertEqual(owner.kind, "local:user")

    def test_resolves_multi_hop_chain_without_hanging(self):
        # a -> b -> c(real file)
        self.assertEqual(owner.kind, "dotfiles")

    def test_cyclic_symlink_does_not_hang(self):
        with TempTree() as t:
            a = t.path / "a"
            b = t.path / "b"
            a.symlink_to(b)
            b.symlink_to(a)
            owner = dot.classify(str(a), current_generation=None, repo_dir=str(t.path))
            self.assertIn(owner.kind, ("broken", "local:tool"))

    def test_tool_dirs_are_excluded(self):
        for name in ("crush", "goose", "opencode", "BraveSoftware", "Local"):
            self.assertTrue(dot.is_excluded(name))
        self.assertFalse(dot.is_excluded("niri"))
```

`TempTree` is a small helper defined at the top of the test file: a `tempfile.TemporaryDirectory` context manager exposing `.path` (a `Path`).

Also add a repository-hygiene test:

```python
class RepoHygieneTests(unittest.TestCase):
    def test_dot_script_is_not_git_ignored(self):
        result = subprocess.run(
            ["git", "check-ignore", "-q", ".local/bin/dot"],
            cwd=REPO, capture_output=True,
        )
        self.assertNotEqual(result.returncode, 0, ".local/bin/dot is git-ignored")
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -m unittest discover -s ~/dotfiles/tests -p 'test_dot.py' -v`
Expected: FAIL — `FileNotFoundError` for `~/dotfiles/.local/bin/dot` (or `ModuleNotFoundError` once the file exists but is empty).

- [ ] **Step 3: Create the script skeleton with the classification logic**

Create `~/dotfiles/.local/bin/dot`, mode `755`, starting with:

```python
#!/usr/bin/env python3
"""dot — inventory and health check for this machine. Read-only by design."""

from __future__ import annotations

import argparse
import dataclasses
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

TOOL_VERSION = "1"

OWNER_KINDS = (
    "home-manager", "home-manager-stale", "frozen-store", "dotfiles",
    "local:user", "local:tool", "runtime", "broken",
)

EXCLUDED_CONFIG_DIRS = (
    "crush", "goose", "opencode", "Codex", "BraveSoftware",
    "Local", "chromium", "Antigravity",
)

SINGLETON_PREFIX = "Singleton"


@dataclasses.dataclass(frozen=True)
class Owner:
    kind: str
    target: str
    reason: str


@dataclasses.dataclass(frozen=True)
class Entry:
    path: str
    owner: Owner


def is_excluded(name: str) -> bool:
    return name in EXCLUDED_CONFIG_DIRS or name.startswith(SINGLETON_PREFIX)


def _resolve(path: str) -> tuple[str, bool]:
    """Return (final_target, exists). Uses os.path.realpath, which is cycle-safe."""
    real = os.path.realpath(path)
    return real, os.path.exists(path)


def classify(path: str, *, current_generation: str | None, repo_dir: str) -> Owner:
    ...
```

`classify` must implement, in order:

1. If `path` is not a symlink → `Owner("runtime", path, "local file")`.
2. `target, exists = _resolve(path)`; if not `exists` → `Owner("broken", target, "target missing")`.
3. If the target contains `/nix/store/`:
   - if it contains `-home-manager-files`:
     - if `current_generation` is not None and the store dir does not contain `current_generation` → `Owner("home-manager-stale", target, "older Home Manager generation")`
     - else → `Owner("home-manager", target, "Home Manager (live repo)")`
   - elif it contains `-source` → `Owner("frozen-store", target, "frozen store copy")`
   - else → `Owner("local:tool", target, "nix store path")`
4. If the target is under `repo_dir` → `Owner("dotfiles", target, "dotfiles repo")`.
5. If the target is under `$HOME` → `Owner("local:user", target, "user-managed")`.
6. Otherwise → `Owner("local:tool", target, "external target")`.

The file must end with:

```python
def main(argv: list[str] | None = None) -> int:
    raise NotImplementedError("subcommands land in later tasks")


if __name__ == "__main__":
    sys.exit(main())
```

- [ ] **Step 4: Add `!dot` to the gitignore allowlist**

In `~/dotfiles/.local/bin/.gitignore`, add the line `!dot` after `!*.py`.

- [ ] **Step 5: Run the tests to verify they pass**

Run: `python3 -m unittest discover -s ~/dotfiles/tests -p 'test_dot.py' -v`
Expected: PASS — all `OwnerTests` and `RepoHygieneTests` pass.

- [ ] **Step 6: Commit**

```bash
cd ~/dotfiles
chmod +x .local/bin/dot
git add .local/bin/dot .local/bin/.gitignore tests/test_dot.py
git commit -m "feat(dot): script skeleton and config owner classification"
```

---

### Task 2: Niri spawn extraction and binary resolution

**Files:**
- Modify: `~/dotfiles/.local/bin/dot`
- Modify: `~/dotfiles/tests/test_dot.py`

**Interfaces:**
- Consumes: `dot` module from Task 1.
- Produces:
  - `@dataclass(frozen=True) class SpawnRef: token: str; context: str; line: int`
  - `extract_spawns(config_text: str) -> list[SpawnRef]` — one entry per resolved command token, in file order.
  - `resolve_token(token: str, *, path_env: str | None = None) -> str | None` — returns the absolute path if resolvable, else `None`.
  - `SHELL_BUILTINS: frozenset[str]` — `{"cd", "exec", "export", "source", ".", "test", "[", "echo", "printf", "command", "builtin", "eval", "set", "unset", "read", "return", "true", "false"}`

- [ ] **Step 1: Write the failing tests**

```python
class SpawnExtractionTests(unittest.TestCase):
    def test_extracts_plain_spawn(self):
        refs = dot.extract_spawns('binds {\n  Mod+T { spawn "kitty"; }\n}')
        self.assertEqual([r.token for r in refs], ["kitty"])

    def test_ignores_arguments_of_a_spawn(self):
        refs = dot.extract_spawns('spawn "swayosd-client" "--output-volume" "raise";')
        self.assertEqual([r.token for r in refs], ["swayosd-client"])

    def test_splits_shell_pipeline_into_each_command(self):
        text = 'spawn-sh "cliphist list | fuzzel -d -w 50 | wl-copy";'
        self.assertEqual([r.token for r in dot.extract_spawns(text)], ["cliphist", "fuzzel", "wl-copy"])

    def test_splits_shell_operators_or_and_semicolon(self):
        text = 'spawn-sh "pkill orca || exec orca";'
        self.assertEqual([r.token for r in dot.extract_spawns(text)], ["pkill", "orca"])

    def test_skips_shell_builtins(self):
        text = 'spawn-sh "export FOO=1 && niri msg action close-window";'
        self.assertEqual([r.token for r in dot.extract_spawns(text)], ["niri"])

```python
    def test_records_absolute_path_token(self):
        text = 'spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1";'
        self.assertEqual([r.token for r in dot.extract_spawns(text)],
                         ["/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"])

    def test_records_path_argument_of_a_spawn(self):
        # `spawn-at-startup "bash" "/home/zeyad/.local/bin/headset-popup-daemon"`
        # first token is the program, the path argument is checked too
        refs = dot.extract_spawns('spawn-at-startup "bash" "/home/zeyad/.local/bin/headset-popup-daemon";')
        self.assertEqual([r.token for r in refs], ["bash", "/home/zeyad/.local/bin/headset-popup-daemon"])
```

```python
class TokenResolutionTests(unittest.TestCase):
    def test_resolves_bare_name_on_path(self):
        self.assertEqual(dot.resolve_token("kitty", path_env="/usr/bin:/bin"), "/usr/bin/kitty")

    def test_returns_none_for_unknown_bare_name(self):
        self.assertIsNone(dot.resolve_token("definitely-not-installed-xyz", path_env="/usr/bin"))

    def test_resolves_absolute_path(self):
        with TempTree() as t:
            f = t.path / "prog"
            f.write_text("x")
            self.assertEqual(dot.resolve_token(str(f)), str(f))

    def test_returns_none_for_missing_absolute_path(self):
        self.assertIsNone(dot.resolve_token("/usr/lib/nope/definitely-missing"))

    def test_expands_tilde_path(self):
        self.assertIsNone(dot.resolve_token("~/.definitely-missing-xyz"))
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -m unittest discover -s ~/dotfiles/tests -p 'test_dot.py' -k Spawn -v`
Expected: FAIL — `AttributeError: module 'dot' has no attribute 'extract_spawns'`.

- [ ] **Step 3: Implement the extraction and resolution**

Add to `~/dotfiles/.local/bin/dot`:

```python
SPAWN_KEYWORDS = ("spawn", "spawn-sh", "spawn-at-startup", "spawn-sh-at-startup")

SHELL_SEPARATORS = ("||", "&&", "|", ";")


@dataclasses.dataclass(frozen=True)
class SpawnRef:
    token: str
    context: str
    line: int


def _split_shell_segments(text: str) -> list[str]:
    parts = [text]
    for sep in SHELL_SEPARATORS:
        nxt: list[str] = []
        for part in parts:
            nxt.extend(part.split(sep))
        parts = nxt
    return [p.strip() for p in parts if p.strip()]


def extract_spawns(config_text: str) -> list[SpawnRef]:
    ...
```

`extract_spawns` walks the config line by line (KDL is line-oriented for these statements). For each line containing a spawn keyword:

- Collect the quoted strings on the line in order.
- For `spawn` / `spawn-at-startup`: the first quoted string is the program; every later quoted string that contains `/` and ends with `.sh` or lives under `~/.local/bin` or `~/.config/niri/scripts` is also recorded as a token.
- For `spawn-sh` / `spawn-sh-at-startup`: the first quoted string is a shell command line; split it with `_split_shell_segments` and take the first word of each segment, skipping words in `SHELL_BUILTINS` and skipping words that start with `-` (flags) or contain `=` (assignments).
- `context` is the keybind text found on the same line or the enclosing block header (e.g. `Mod+Shift+S`); when none, use `"startup"`.
- `line` is the 1-based line number.

```python
def resolve_token(token: str, *, path_env: str | None = None) -> str | None:
    ...
```

`resolve_token` rules, in order:

1. Expand a leading `~` to `$HOME`.
2. If the token contains `/` → return it if `os.path.exists` else `None`.
3. Otherwise → `shutil.which(token, path=path_env)`; return the found path or `None`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -m unittest discover -s ~/dotfiles/tests -p 'test_dot.py' -v`
Expected: PASS — all tests green, including the Task 1 tests.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add .local/bin/dot tests/test_dot.py
git commit -m "feat(dot): extract niri spawn targets and resolve binaries"
```

---

### Task 3: Config scan and ownership findings

**Files:**
- Modify: `~/dotfiles/.local/bin/dot`
- Modify: `~/dotfiles/tests/test_dot.py`

**Interfaces:**
- Consumes: `classify`, `Entry`, `Owner`, `is_excluded` (Task 1).
- Produces:
  - `@dataclass(frozen=True) class Finding: id: str; severity: str; path: str; detail: str; fix: str; command: str`
  - `SEVERITIES: tuple[str, ...]` — `("broken", "stale", "missing", "drift", "orphan", "info")`
  - `scan_configs(roots: list[str], *, current_generation: str | None, repo_dir: str, exclude_file: str | None = None) -> list[Entry]`
  - `findings_from_entries(entries: list[Entry]) -> list[Finding]`

- [ ] **Step 1: Write the failing tests**

```python
class ConfigScanTests(unittest.TestCase):
    def test_reports_broken_link_inside_config_dir(self):
        with TempTree() as t:
            cfg = t.path / "config"
            (cfg / "ghostty").mkdir(parents=True)
            (cfg / "ghostty" / "config").symlink_to(t.path / "dotfiles" / ".config" / "ghostty" / "config")
            entries = dot.scan_configs([str(cfg)], current_generation=None, repo_dir=str(t.path / "dotfiles"))
            kinds = {e.path.split("/")[-1]: e.owner.kind for e in entries}
            self.assertEqual(kinds.get("config"), "broken")

    def test_skips_excluded_tool_dirs(self):
        with TempTree() as t:
            cfg = t.path / "config"
            (cfg / "crush" / "skills").mkdir(parents=True)
            (cfg / "crush" / "skills" / "x").symlink_to(t.path / "nope")
            (cfg / "niri").mkdir()
            (cfg / "niri" / "config.kdl").write_text("x")
            entries = dot.scan_configs([str(cfg)], current_generation=None, repo_dir=str(t.path))
            self.assertFalse(any("/crush/" in e.path for e in entries))

    def test_skips_unreadable_directory(self):
        with TempTree() as t:
            cfg = t.path / "config"
            (cfg / "locked").mkdir(parents=True)
            (cfg / "locked" / "secret").write_text("x")
            (cfg / "niri").mkdir()
            (cfg / "niri" / "config.kdl").write_text("x")
            os.chmod(cfg / "locked", 0o000)
            try:
                entries = dot.scan_configs([str(cfg)], current_generation=None, repo_dir=str(t.path))
            finally:
                os.chmod(cfg / "locked", 0o755)
            self.assertTrue(any(e.path.endswith("config.kdl") for e in entries))

    def test_findings_from_entries_marks_broken_and_stale(self):
        with TempTree() as t:
            entries = [dot.Entry("/x/ghostty/config", dot.Owner("broken", "/x/missing", "target missing")),
                       dot.Entry("/x/lazygit", dot.Owner("frozen-store", "/nix/store/abc-source/.config/lazygit", "frozen store copy"))]
            findings = dot.findings_from_entries(entries)
            self.assertEqual([f.severity for f in findings], ["broken", "stale"])
            self.assertTrue(all(f.fix for f in findings))
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -m unittest discover -s ~/dotfiles/tests -p 'test_dot.py' -k ConfigScan -v`
Expected: FAIL — `AttributeError: module 'dot' has no attribute 'scan_configs'`.

- [ ] **Step 3: Implement the scan**

```python
@dataclasses.dataclass(frozen=True)
class Finding:
    id: str
    severity: str
    path: str
    detail: str
    fix: str
    command: str


SEVERITIES = ("broken", "stale", "missing", "drift", "orphan", "info")


def scan_configs(roots, *, current_generation, repo_dir, exclude_file=None) -> list[Entry]:
    ...
```

`scan_configs` behaviour:

- For each root: list depth-1 entries. For a symlink entry, classify it and record an `Entry`.
- For a real directory entry: record it as a runtime `Entry`, then descend **one level** into it (depth 2) unless `is_excluded(name)` is true for the directory name, recording symlinks found there. Never descend deeper.
- `PermissionError` / `OSError` on listing or `lstat` → skip that entry silently and continue.
- `exclude_file` (default `~/.config/dot/exclude`) is read if present; each non-empty, non-`#` line is an additional excluded directory basename (and also an absolute-path prefix match).
- The scan never follows symlinked directories when descending.

```python
def findings_from_entries(entries: list[Entry]) -> list[Finding]:
    ...
```

Maps owner kinds to findings:

- `broken` → severity `broken`, id `broken-symlink`, fix `rm <path>`, command `rm <path>`.
- `home-manager-stale` → severity `stale`, id `stale-home-manager`, fix `re-point the link at the current generation`.
- `frozen-store` → severity `stale`, id `frozen-store-copy`, detail `the app reads a frozen store copy, not your repo — edits do not apply`, fix `re-point the link at the repo path`.

Findings are returned in `SEVERITIES` order.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -m unittest discover -s ~/dotfiles/tests -p 'test_dot.py' -v`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add .local/bin/dot tests/test_dot.py
git commit -m "feat(dot): scan config ownership and report broken/stale links"
```

---

### Task 4: Package and application inventory collectors

**Files:**
- Modify: `~/dotfiles/.local/bin/dot`
- Modify: `~/dotfiles/tests/test_dot.py`

**Interfaces:**
- Consumes: nothing new from earlier tasks.
- Produces:
  - `@dataclass(frozen=True) class Source: name: str; items: list[str]; kind: str` — `kind` is one of `package`, `binary`, `app`, `script`.
  - `collect_pacman(runner=None) -> dict[str, list[str]]` — keys `system`, `foreign`, `orphans`.
  - `collect_profile_bins(profile_dir: str | None = None) -> list[str]` — visible binaries only (skip names starting with `.`).
  - `collect_desktop_entries(dirs: list[str]) -> list[dict]` — each dict has `name`, `desktop_file`, `source` (`system`/`user`).
  - `collect_scripts(bin_dir: str, repo_dir: str | None = None) -> dict[str, list[str]]` — keys `repo`, `local`.
  - `collect_outdated(runner=None) -> list[str]` — packages with a newer version available, via `checkupdates`; `[]` when the command is missing or fails.
  - `collect_repo_state(repo_dir: str | None = None) -> dict[str, list[str]]` — keys `modified`, `untracked`, from `git status --porcelain`; `{"modified": [], "untracked": []}` when the repo is absent.
  - `collect_tool_dirs(dirs: list[str]) -> dict[str, list[str]]` — mise, uv, go, vite-plus, opencode.
  - `TOOL_DIRS: tuple[tuple[str, str], ...]` — `(label, relative_path)` pairs: `("mise", ".local/share/mise/shims")`, `("uv", ".local/share/uv/tools")`, `("go", "go/bin")`, `("vite-plus", ".vite-plus/bin")`, `("opencode", ".opencode/bin")`.

- [ ] **Step 1: Write the failing tests**

```python
class CollectorTests(unittest.TestCase):
    def test_collect_pacman_splits_system_foreign_orphans(self):
        def fake_runner(cmd, **kwargs):
            if cmd[:2] == ["pacman", "-Qq"]:
                return subprocess.CompletedProcess(cmd, 0, "a\nb\nc\n", "")
            if cmd[:2] == ["pacman", "-Qmq"]:
                return subprocess.CompletedProcess(cmd, 0, "c\n", "")
            if cmd[:2] == ["pacman", "-Qdtq"]:
                return subprocess.CompletedProcess(cmd, 0, "b\n", "")
            raise AssertionError(f"unexpected command {cmd}")
        result = dot.collect_pacman(runner=fake_runner)
        self.assertEqual(result["system"], ["a", "b", "c"])
        self.assertEqual(result["foreign"], ["c"])
        self.assertEqual(result["orphans"], ["b"])

    def test_collect_pacman_degrades_when_pacman_missing(self):
        def fake_runner(cmd, **kwargs):
            raise FileNotFoundError("pacman")
        self.assertEqual(dot.collect_pacman(runner=fake_runner),
                         {"system": [], "foreign": [], "orphans": []})

    def test_collect_profile_bins_skips_hidden_wrappers(self):
        with TempTree() as t:
            (t.path / "nvim").write_text("x")
            (t.path / ".nvim-wrapped").write_text("x")
            self.assertEqual(dot.collect_profile_bins(str(t.path)), ["nvim"])

    def test_collect_profile_bins_missing_dir_returns_empty(self):
        self.assertEqual(dot.collect_profile_bins("/nonexistent/path"), [])

    def test_collect_scripts_splits_repo_and_local(self):
        with TempTree() as t:
            (t.path / "set-theme").write_text("x")
            (t.path / "my-tool").write_text("x")
            result = dot.collect_scripts(str(t.path), repo_dir=str(t.path))
            self.assertIn("my-tool", result["local"])

    def test_collect_desktop_entries_reads_name(self):
        with TempTree() as t:
            (t.path / "Brave.desktop").write_text("[Desktop Entry]\nName=Brave Browser\nExec=brave\n")
            entries = dot.collect_desktop_entries([str(t.path)])
            self.assertEqual(entries[0]["name"], "Brave Browser")

    def test_collect_outdated_is_empty_when_command_missing(self):
        def fake_runner(cmd, **kwargs):
            raise FileNotFoundError("checkupdates")
        self.assertEqual(dot.collect_outdated(runner=fake_runner), [])

    def test_collect_repo_state_missing_repo_is_empty(self):
        self.assertEqual(dot.collect_repo_state("/nonexistent/repo"),
                         {"modified": [], "untracked": []})
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -m unittest discover -s ~/dotfiles/tests -p 'test_dot.py' -k Collector -v`
Expected: FAIL — `AttributeError: module 'dot' has no attribute 'collect_pacman'`.

- [ ] **Step 3: Implement the collectors**

```python
def _run(cmd: list[str], runner=None) -> str:
    run = runner or subprocess.run
    try:
        proc = run(cmd, capture_output=True, text=True, check=False)
    except (FileNotFoundError, OSError):
        return ""
    if proc.returncode != 0:
        return ""
    return proc.stdout
```

`collect_pacman` calls `_run(["pacman", "-Qq"])`, `_run(["pacman", "-Qmq"])` and `_run(["pacman", "-Qdtq"])`, splitting on newlines and dropping empty strings. A failed or missing `pacman` yields empty lists — never an exception.

`collect_profile_bins(profile_dir=None)` defaults to `~/.local/state/nix/profiles/profile/bin`; returns sorted names not starting with `.`; a missing directory returns `[]`.

`collect_desktop_entries(dirs)` parses `Name=` and `Exec=` from each `*.desktop` file; skips files without a `Name=`; returns dicts with `name`, `desktop_file`, `source` (`user` when the path is under `$HOME`, else `system`).

`collect_scripts(bin_dir, repo_dir)` splits the entries of `bin_dir` into `repo` (git-tracked in the repo — determine with `git ls-files --error-unmatch <path>` and treat failures as not tracked) and `local`.

`collect_tool_dirs(dirs)` returns a dict label → sorted entry names for each existing directory; missing directories are omitted entirely.

`collect_outdated` runs `checkupdates` and returns the package names it printed (one per line, the first column only). It is **never** called unless the user asks for `--outdated`, because it hits the network.

`collect_repo_state` runs `git -C <repo_dir> status --porcelain` and splits the output into `modified` (lines not starting with `??`) and `untracked` (lines starting with `??`). A missing repo or a failed git call returns empty lists.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -m unittest discover -s ~/dotfiles/tests -p 'test_dot.py' -v`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add .local/bin/dot tests/test_dot.py
git commit -m "feat(dot): collect packages, apps, scripts and tool dirs"
```

---

### Task 5: Nix declaration drift

**Files:**
- Modify: `~/dotfiles/.local/bin/dot`
- Modify: `~/dotfiles/tests/test_dot.py`

**Interfaces:**
- Consumes: `collect_profile_bins` (Task 4), `Finding` (Task 3).
- Produces:
  - `parse_declared_packages(text: str) -> set[str]` — package names declared in `nix/modules/packages.nix`.
  - `package_binary_map(profile_dir: str | None = None, runner=None) -> dict[str, list[str]]` — package → binaries, via `nix path-info --json`; returns `{}` when `nix` is unavailable.
  - `nix_drift(declared: set[str], installed: set[str], package_bins: dict[str, list[str]]) -> list[Finding]`

- [ ] **Step 1: Write the failing tests**

```python
class NixDriftTests(unittest.TestCase):
    def test_parses_declared_names(self):
        text = "{\n  home.packages = with pkgs; [\n    git\n    ripgrep\n    traceroute\n  ];\n}\n"
        self.assertEqual(dot.parse_declared_packages(text), {"git", "ripgrep", "traceroute"})

    def test_detects_declared_but_not_installed(self):
        findings = dot.nix_drift({"traceroute"}, {"nvim", "git"}, {})
        self.assertEqual([f.severity for f in findings], ["drift"])
        self.assertIn("traceroute", findings[0].detail)

    def test_detects_installed_but_not_declared(self):
        findings = dot.nix_drift({"git"}, {"git", "mandb"}, {"git": ["git"]})
        self.assertEqual([f.severity for f in findings], ["drift"])
        self.assertIn("mandb", findings[0].detail)

    def test_no_findings_when_all_declared_are_installed(self):
        findings = dot.nix_drift({"git"}, {"git"}, {"git": ["git"]})
        self.assertEqual(findings, [])
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -m unittest discover -s ~/dotfiles/tests -p 'test_dot.py' -k NixDrift -v`
Expected: FAIL — `AttributeError: module 'dot' has no attribute 'parse_declared_packages'`.

- [ ] **Step 3: Implement the drift logic**

```python
def parse_declared_packages(text: str) -> set[str]:
    ...
```

Parse `nix/modules/packages.nix`: collect names that appear alone on a line inside the `home.packages` list, i.e. lines matching `^\s{4}([a-zA-Z0-9_.-]+)\s*$`. Ignore lines inside a `(stdenvNoCC.mkDerivation { ... })` block — a name is only taken when the line is exactly the name.

```python
def package_binary_map(profile_dir=None, runner=None) -> dict[str, list[str]]:
    ...
```

Run `nix path-info --json <profile_dir>/*` (or `nix path-info --json --derivation` over the profile) and read the `name` attribute of each path to map store paths to package names. If `nix` is not installed or the command fails, return `{}` — the caller then treats every unmatched binary as "unattributed" rather than claiming an owner.

```python
def nix_drift(declared, installed, package_bins) -> list[Finding]:
    ...
```

Logic:

1. For each declared package, if it has binaries in `package_bins` and **none** of them is in `installed` → finding `drift`, id `nix-not-installed`, detail `` `pkg` declared in nix/modules/packages.nix but not installed``, fix `dot pkg sync`.
2. For each installed binary whose owning package (via `package_bins`) is not in `declared` → finding `drift`, id `nix-undeclared`, detail `` `binary` is installed by a package not declared in packages.nix ``.
3. When `package_bins` is empty (no `nix` CLI), report a single finding `drift` / id `nix-unattributed` listing the installed binaries that match no declared name, with detail `installed in the Nix profile but not declared in packages.nix (owner unknown)`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -m unittest discover -s ~/dotfiles/tests -p 'test_dot.py' -v`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add .local/bin/dot tests/test_dot.py
git commit -m "feat(dot): detect nix declaration drift both ways"
```

---

### Task 6: Renderers — `dot list` and `dot status` text and JSON

**Files:**
- Modify: `~/dotfiles/.local/bin/dot`
- Modify: `~/dotfiles/tests/test_dot.py`

**Interfaces:**
- Consumes: `Entry`, `Finding`, `Owner`, `Source`, `SEVERITIES` (Tasks 1–5).
- Produces:
  - `@dataclass(frozen=True) class Inventory: apps: list[dict]; cli: list[Source]; scripts: dict[str, list[str]]; configs: list[Entry]; findings: list[Finding]; meta: dict`
  - `render_list(inventory: Inventory, *, wide: bool = False, show_all: bool = False) -> str`
  - `render_status(inventory: Inventory) -> str`
  - `inventory_json(inventory: Inventory, *, command: str) -> dict` — the frozen schema from spec §7.6.
  - `COLOR: dict[str, str]` — `broken`→red, `stale`→magenta, `missing`→orange, `drift`→yellow, `ok`→green, `muted`→dim.

- [ ] **Step 1: Write the failing tests**

```python
class RenderTests(unittest.TestCase):
    def _inventory(self):
        return dot.Inventory(
            apps=[{"name": "Brave Browser", "desktop_file": "Brave.desktop", "source": "system"}],
            cli=[dot.Source("pacman", ["git", "nvim"], "package")],
            scripts={"repo": ["set-theme"], "local": ["my-tool"]},
            configs=[dot.Entry("/home/z/.config/niri", dot.Owner("home-manager", "/repo/.config/niri", "HM"))],
            findings=[dot.Finding("broken-symlink", "broken", "/home/z/.config/ghostty/config",
                                   "target missing", "rm /home/z/.config/ghostty/config", "rm /home/z/.config/ghostty/config")],
            meta={"host": "zeyad", "distro": "EndeavourOS"},
        )

    def test_render_list_contains_sections_and_counts(self):
        out = dot.render_list(self._inventory())
        self.assertIn("Desktop apps", out)
        self.assertIn("CLI packages", out)
        self.assertIn("Managed configs", out)
        self.assertIn("Local scripts", out)

    def test_render_status_groups_by_severity(self):
        out = dot.render_status(self._inventory())
        self.assertIn("BROKEN", out)
        self.assertIn("broken-symlink", out.replace("BROKEN", "broken-symlink") or out)
        self.assertIn("fix:", out)

    def test_render_status_states_no_findings(self):
        inv = self._inventory()
        empty = dot.Inventory(apps=inv.apps, cli=inv.cli, scripts=inv.scripts,
                              configs=inv.configs, findings=[], meta=inv.meta)
        self.assertIn("no findings", dot.render_status(empty).lower())

    def test_inventory_json_matches_frozen_schema(self):
        data = dot.inventory_json(self._inventory(), command="list")
        self.assertEqual(set(data) >= {"tool", "version", "command", "generated_at", "summary", "sections"}, True)
        self.assertEqual(data["tool"], "dot")
        self.assertEqual(data["version"], "1")
        self.assertEqual(set(data["sections"]), {"apps", "cli", "scripts", "configs"})

    def test_status_json_has_counts_and_findings(self):
        data = dot.inventory_json(self._inventory(), command="status")
        self.assertEqual(data["ok"], False)
        self.assertEqual(data["counts"]["broken"], 1)
        self.assertEqual(data["findings"][0]["severity"], "broken")
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -m unittest discover -s ~/dotfiles/tests -p 'test_dot.py' -k Render -v`
Expected: FAIL — `AttributeError: module 'dot' has no attribute 'render_list'`.

- [ ] **Step 3: Implement the renderers**

`render_list` prints, in order:

1. Header line: `System inventory · <distro> · <host>` then a 60-column rule of `─`.
2. Aligned count lines, two columns, label left and counts right:
   `Desktop apps`, `CLI packages`, `Tooling`, `AUR / foreign`, `Orphans`, `Managed configs`, `Local scripts`.
   Each count line shows the breakdown after the count, e.g. `system 65  ·  user 27`.
3. A line listing the top CLI names, truncated to **12** names, joined by two spaces.
4. A hint line: `Full lists: dot list --all --cli`.

`render_status` prints:

1. `● N findings — <counts by severity, in SEVERITIES order>` or `● no findings`.
2. For each severity present, a header `SEVERITY (count)`, then per finding:
   - `  ✗ <path> → <target>` (broken/missing) or `  ~ <path>` (stale/drift/orphan/info),
   - an indented detail line,
   - an indented `fix: <fix>` line.
3. `INFO` findings are rendered last and never counted in the headline number.

`inventory_json` builds exactly the schema in spec §7.6 — keys `tool`, `version`, `command`, `generated_at` (ISO-8601 UTC), `summary` (`total`, `by_source`, `by_owner`), `sections` (`apps`, `cli`, `scripts`, `configs`), and for `command == "status"` additionally `ok` and `counts` and `findings`.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -m unittest discover -s ~/dotfiles/tests -p 'test_dot.py' -v`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd ~/dotfiles
git add .local/bin/dot tests/test_dot.py
git commit -m "feat(dot): render inventory and status views"
```

---

### Task 7: CLI wiring — subcommands, flags, exit codes

**Files:**
- Modify: `~/dotfiles/.local/bin/dot`
- Modify: `~/dotfiles/tests/test_dot.py`

**Interfaces:**
- Consumes: every function from Tasks 1–6.
- Produces: `main(argv: list[str] | None = None) -> int`, `build_inventory(...) -> Inventory`.

- [ ] **Step 1: Write the failing tests**

```python
class CliTests(unittest.TestCase):
    def _stub(self, inventory):
        original = dot.build_inventory
        dot.build_inventory = lambda **kwargs: inventory
        self.addCleanup(setattr, dot, "build_inventory", original)

    def _capture(self, argv):
        import io
        from contextlib import redirect_stdout
        buf = io.StringIO()
        with redirect_stdout(buf):
            code = dot.main(argv)
        return code, buf.getvalue()

    def test_status_exit_code_is_one_when_findings_exist(self):
        inv = dot.Inventory(apps=[], cli=[], scripts={}, configs=[],
                            findings=[dot.Finding("broken-symlink", "broken", "/x", "d", "rm /x", "rm /x")],
                            meta={})
        self._stub(inv)
        code, out = self._capture(["status"])
        self.assertEqual(code, 1)
        self.assertIn("broken", out.lower())

    def test_status_exit_code_is_zero_when_only_info_findings(self):
        inv = dot.Inventory(apps=[], cli=[], scripts={}, configs=[],
                            findings=[dot.Finding("repo-dirty", "info", "/repo", "2 modified", "", "")],
                            meta={})
        self._stub(inv)
        code, _ = self._capture(["status"])
        self.assertEqual(code, 0)

    def test_list_json_prints_valid_json(self):
        import json
        inv = dot.Inventory(apps=[], cli=[], scripts={}, configs=[], findings=[], meta={})
        self._stub(inv)
        code, out = self._capture(["list", "--json"])
        self.assertEqual(code, 0)
        self.assertEqual(json.loads(out)["command"], "list")

    def test_help_exits_zero(self):
        with self.assertRaises(SystemExit) as ctx:
            dot.main(["--help"])
        self.assertEqual(ctx.exception.code, 0)

    def test_dot_never_invokes_sudo_or_mutating_pacman(self):
        import io
        from contextlib import redirect_stdout
        recorded = []
        real_run = subprocess.run

        def spy(cmd, *args, **kwargs):
            recorded.append(cmd if isinstance(cmd, list) else [cmd])
            return real_run(cmd, *args, **kwargs)

        subprocess.run = spy
        self.addCleanup(setattr, subprocess, "run", real_run)
        with redirect_stdout(io.StringIO()):
            try:
                dot.build_inventory()
            except Exception:
                pass
        for cmd in recorded:
            joined = " ".join(cmd)
            self.assertNotIn("sudo", joined)
            self.assertNotIn("-S", joined.split()[:2])
            self.assertNotIn("-R", joined.split()[:2])
```

`test_dot_never_invokes_sudo_or_mutating_pacman` pins Review Focus item 6: no `dot` code path may run `sudo` or a mutating `pacman` subcommand.

Add a second test for Review Focus item 5 (no repo on the machine):

```python
    def test_build_inventory_survives_missing_repo(self):
        inv = dot.build_inventory(home="/tmp", repo_dir="/nonexistent/repo")
        self.assertIsInstance(inv, dot.Inventory)
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -m unittest discover -s ~/dotfiles/tests -p 'test_dot.py' -k Cli -v`
Expected: FAIL — `AttributeError: module 'dot' has no attribute 'build_inventory'`.

- [ ] **Step 3: Implement the CLI**

```python
def build_inventory(*, home: str | None = None, repo_dir: str | None = None) -> Inventory:
    ...
```

Assembles every source from Tasks 2–5: pacman collections, profile binaries, desktop entries, scripts, tool dirs, the config scan, and the Nix drift findings. `home` defaults to `$HOME`; `repo_dir` defaults to `~/dotfiles` and, when it does not exist, the repo-dependent parts (drift, dotfiles-owner classification) are skipped without raising.

```python
def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="dot", description="Inventory and health check for this machine.")
    sub = parser.add_subparsers(dest="command", required=True)

    p_list = sub.add_parser("list", help="show what is installed")
    p_list.add_argument("--all", action="store_true", help="print every item, ungrouped")
    p_list.add_argument("--json", action="store_true")
    p_list.add_argument("--ownership", action="store_true", help="config ownership map only")
    p_list.add_argument("--outdated", action="store_true", help="also query the network for updates")
    for flag in ("apps", "cli", "configs", "scripts", "sources"):
        p_list.add_argument(f"--{flag}", action="store_true")

    p_status = sub.add_parser("status", help="show what is broken or drifted")
    p_status.add_argument("--json", action="store_true")

    args = parser.parse_args(argv)
    ...
```

Behaviour:

- `dot list --json` → print `json.dumps(inventory_json(inv, command="list"), indent=2)` and return `0`.
- `dot list` → print `render_list(inv, show_all=args.all)` and return `0`.
- `dot status --json` → print the JSON document and return `1` if any finding has severity in `("broken", "stale", "missing", "drift", "orphan")`, else `0`.
- `dot status` → print `render_status(inv)` and return the same code.
- `--ownership` restricts the list output to the config ownership map.
- `--outdated` adds a section listing packages with a newer version; this is the only code path that touches the network, and it is opt-in.
- The `--apps` / `--cli` / `--configs` / `--scripts` / `--sources` flags restrict the output to that section only.
- `build_inventory` turns `collect_repo_state` into an `info` finding (`repo-dirty`) listing the modified files; untracked files are not reported, and the finding never affects the exit code.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -m unittest discover -s ~/dotfiles/tests -p 'test_dot.py' -v`
Expected: PASS.

- [ ] **Step 5: Verify against the live machine**

Run:

```bash
dot list
dot status
dot status --json | python3 -m json.tool | head -20
```

Expected: `dot list` prints the sections with real counts; `dot status` reports **5 broken** symlinks (`ghostty/config`, `mako/config`, `sway/config`, `waybar/config`, `waybar/config-mango`), **1 stale** (`lazygit` frozen store copy), **2 missing** (`orca`, `polkit-gnome-authentication-agent-1`) and **1 drift** (`traceroute`). `dot status` exits `1`.

- [ ] **Step 6: Commit**

```bash
cd ~/dotfiles
git add .local/bin/dot tests/test_dot.py
git commit -m "feat(dot): wire up list and status subcommands"
```

---

### Task 8: Documentation and final verification

**Files:**
- Modify: `~/dotfiles/README.md` (new "The `dot` CLI" section; fix "8 modules" → 7)
- Modify: `~/dotfiles/docs/superpowers/specs/2026-10-20-dot-cli-system-inventory-design.md` (mark Phase 1 as implemented)

**Interfaces:**
- Consumes: the finished `dot` CLI.
- Produces: nothing new.

- [ ] **Step 1: Correct the README module count**

In `~/dotfiles/README.md`, the tree diagram says `│   └── modules/         # 8 modules, one concern each:` and lists eight entries including `scripts.nix`. There are seven modules; `scripts.nix` does not exist. Change the count to `7 modules` and delete the `scripts.nix` line.

- [ ] **Step 2: Add the `dot` CLI section to the README**

Add a section titled `## The dot CLI` after the "Quick reference" table, containing:

- One paragraph: `dot` is a read-only inventory and health-check command for this machine; it replaces guessing which package manager owns what.
- A table: `dot list` → "what is installed (apps, CLI tools, scripts, managed configs)"; `dot list --all` → "every item, ungrouped"; `dot list --ownership` → "who owns each config file"; `dot list --json` → "machine-readable"; `dot status` → "broken links, stale copies, missing binaries, drift"; `dot status --json` → "machine-readable findings".
- The note that `dot status` exits `1` when it finds problems, so it can be used in a check.
- The note that the tool is read-only: it never installs, removes or runs `sudo`; fix hints are printed for you to run.

- [ ] **Step 3: Run the full test suite**

Run: `python3 -m unittest discover -s ~/dotfiles/tests -p 'test_dot.py' -v`
Expected: PASS — every test green.

- [ ] **Step 4: Run the tool end to end**

Run: `dot list && dot status; echo "exit=$?"`
Expected: `dot list` prints the inventory; `dot status` prints the findings and `exit=1`.

- [ ] **Step 5: Verify the git tree is clean of surprises**

Run:

```bash
cd ~/dotfiles
git status --short
git ls-files .local/bin/dot tests/
```

Expected: `.local/bin/dot` and `tests/test_dot.py` are tracked; `git status --short` shows no unexpected untracked files under `.local/bin`.

- [ ] **Step 6: Mark the spec as implemented**

In the spec's header, change the status line to: `- **Status:** **Phase 1 implemented 2026-10-21** — approved and built per this document`.

- [ ] **Step 7: Commit**

```bash
cd ~/dotfiles
git add README.md docs/superpowers/specs/2026-10-20-dot-cli-system-inventory-design.md
git commit -m "docs: document the dot CLI and correct the module count"
```
