# dot CLI Phase 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Omarchy-like operating surface on top of the `dot` inventory — a cheap health probe for the bar, `dot pkg` for nix packages, an fzf launcher, a live niri shortcut cheat sheet, and the bar itself.

**Architecture:** Everything lands in the existing single-file tool `.local/bin/dot` (stdlib only), plus four small shell scripts and one config change for the bar. Phase 2 adds new subcommands (`health`, `pkg`, `browse`, `keys`, `show`); it does not change the Phase 1 JSON contract or the existing `list`/`status` behaviour.

**Tech Stack:** Python 3 (stdlib only, no third-party imports), `nix` / `home-manager` CLI, `fzf`, `zenity`, waybar 0.15 JSON custom modules, shell (`/bin/sh`).

**Spec:** `docs/superpowers/specs/2026-10-22-dot-cli-phase2-design.md` — the plan argues from that spec; executors read both.

## Global Constraints

- `dot` stays a **single self-contained Python file** at `.local/bin/dot` with a `#!/usr/bin/env python3` shebang: stdlib imports only, no module tree, no third-party packages.
- `dot` **never runs `sudo`** and **never runs a mutating pacman command** (`-S`, `-R`, `-U`, `-Sy`, `-Rns`); it prints the command instead. The existing test `test_dot_never_invokes_sudo_or_mutating_pacman` guards this.
- `dot pkg` is the **only** mutating command. It writes only `nix/modules/packages.nix`, and only after a confirmation.
- `dot health` must finish in **under 300 ms** on this machine. It runs the config scan and the spawn check only — never pacman, nix or git.
- `dot health --json` prints **exactly three keys**: `text`, `tooltip`, `class`.
- The Phase 1 JSON contract (`dot list --json`, `dot status --json`) is **frozen**; Phase 2 does not change it.
- New files under `.local/bin/` must match the `.local/bin/.gitignore` allowlist (`*.sh`, `*.py`, or an explicitly named file).
- Every command that can change something prints what it is about to do **before** it does it.
- The tests live in `tests/test_dot.py` (stdlib `unittest`) and run with `python3 -m unittest discover -s tests -p test_dot.py`.
- The user's two uncommitted modifications — `.config/Thunar/accels.scm` and `nix/modules/packages.nix` — **must never be committed**. Never `git add -A`; add paths explicitly.

---

## Review Focus

Six input classes the spec implies but no task's own tests exercise. Each line below is pinned to a test in the task that owns the code.

1. **A broken link three levels deep** (`~/.config/app/sub/file` → a missing target) — `dot health` must report it. The Phase 1 depth rule (depth 3 for findings, depth 2 for counts) must survive the new probe. → Task 1, `test_health_counts_a_broken_link_three_levels_deep`.
2. **No niri config at all** (`~/.config/niri/config.kdl` missing) — `dot health` must not crash and must not invent a "missing" finding about the config file itself. → Task 1, `test_health_ignores_a_missing_niri_config`.
3. **`dot pkg add` of a package that is already declared** — the file must not gain a second line and the diff must be empty. → Task 2, `test_add_packages_skips_a_name_that_is_already_declared`.
4. **`dot pkg add rg`** — `rg` is a binary, not a nixpkgs attribute. The tool must map it to `ripgrep` or refuse; it must never write `rg` verbatim, because that breaks the build. → Task 3, `test_pkg_add_maps_a_binary_name_to_its_package`.
5. **`home-manager switch` fails after the file was written** — the file must be restored byte for byte. → Task 3, `test_apply_package_change_restores_the_file_when_the_switch_fails`.
6. **A helper tool is missing** (`fzf`, `zenity`, `niri`, `uv`) — `dot browse`, `dot keys` and the bar scripts must degrade to printing text, never crash and never render an empty widget. → Task 4 (`test_browse_prints_the_rows_when_fzf_is_missing`), Task 5 (`test_keys_falls_back_to_text_without_zenity`), Task 6 (`test_health_script_prints_valid_json_even_when_dot_fails`).

---

### Task 1: `dot health` — the cheap health probe

**Files:**
- Modify: `.local/bin/dot` (new section `# ── health ──` between the renderers and `main`)
- Test: `tests/test_dot.py` (new class `HealthTests`)

**Interfaces:**
- Consumes: `scan_configs(roots, *, current_generation, repo_dir, exclude_file, home, shallow_roots)`, `findings_from_entries(entries)`, `_spawn_findings(config_path)`, `current_generation(home)`, `default_repo_dir()`, the `Finding` dataclass, `SEVERITIES`.
- Produces (later tasks rely on these names):
  - `HEALTH_TEXT = "●"`
  - `scan_home_configs(base: str, repo: str) -> list[Entry]` — the config scan of the home
    directory, shared by the health probe, the browser and the inventory
  - `@dataclasses.dataclass(frozen=True) class Health:` with fields `ok: bool`, `counts: dict[str, int]`, `findings: list[Finding]`, `text: str`, `tooltip: str`, `style: str`
  - `collect_health(*, home: str | None = None, repo_dir: str | None = None) -> Health`
  - `health_json(health: Health) -> dict`
  - `render_health(health: Health) -> str`
  - CLI: `dot health` and `dot health --json`

- [ ] **Step 1: Write the failing tests**

Add to `tests/test_dot.py`:

```python
class HealthTests(unittest.TestCase):
    """The health probe is the cheap one: no pacman, no nix, no git."""

    def _home(self, t):
        home = t.path / "home"
        (home / ".config").mkdir(parents=True)
        return home

    def test_health_is_clean_when_nothing_is_broken(self):
        with TempTree() as t:
            home = self._home(t)
            health = dot.collect_health(home=str(home), repo_dir=str(t.path / "dotfiles"))
            self.assertTrue(health.ok)
            self.assertEqual(health.style, "ok")
            self.assertEqual(health.counts, {"broken": 0, "stale": 0, "missing": 0})

    def test_health_counts_a_broken_link(self):
        with TempTree() as t:
            home = self._home(t)
            (home / ".config" / "app").mkdir()
            (home / ".config" / "app" / "config").symlink_to(home / ".config" / "app" / "missing")
            health = dot.collect_health(home=str(home), repo_dir=str(t.path / "dotfiles"))
            self.assertFalse(health.ok)
            self.assertEqual(health.counts["broken"], 1)
            self.assertEqual(health.style, "bad")

    def test_health_counts_a_broken_link_three_levels_deep(self):
        with TempTree() as t:
            home = self._home(t)
            deep = home / ".config" / "app" / "sub"
            deep.mkdir(parents=True)
            (deep / "file").symlink_to(deep / "missing")
            health = dot.collect_health(home=str(home), repo_dir=str(t.path / "dotfiles"))
            self.assertEqual(health.counts["broken"], 1)

    def test_health_reports_a_missing_spawn_binary(self):
        with TempTree() as t:
            home = self._home(t)
            niri = home / ".config" / "niri"
            niri.mkdir(parents=True)
            (niri / "config.kdl").write_text('binds {\n    Mod+T { spawn "definitely-not-installed-xyz"; }\n}\n')
            health = dot.collect_health(home=str(home), repo_dir=str(t.path / "dotfiles"))
            self.assertEqual(health.counts["missing"], 1)
            self.assertFalse(health.ok)

    def test_health_ignores_a_missing_niri_config(self):
        with TempTree() as t:
            home = self._home(t)
            health = dot.collect_health(home=str(home), repo_dir=str(t.path / "dotfiles"))
            self.assertEqual(health.counts["missing"], 0)
            self.assertTrue(health.ok)

    def test_health_json_has_exactly_three_keys(self):
        health = dot.Health(ok=True, counts={"broken": 0, "stale": 0, "missing": 0},
                            findings=[], text="●", tooltip="dot: no problems", style="ok")
        data = dot.health_json(health)
        self.assertEqual(sorted(data.keys()), ["class", "text", "tooltip"])
        self.assertEqual(data["class"], "ok")

    def test_health_json_style_is_bad_when_something_is_broken(self):
        health = dot.Health(ok=False, counts={"broken": 2, "stale": 0, "missing": 0},
                            findings=[], text="●", tooltip="dot: 2 broken", style="bad")
        self.assertEqual(dot.health_json(health)["class"], "bad")

    def test_health_command_exits_zero_when_healthy(self):
        original = dot.collect_health
        dot.collect_health = lambda **kwargs: dot.Health(
            ok=True, counts={"broken": 0, "stale": 0, "missing": 0}, findings=[],
            text="●", tooltip="dot: no problems", style="ok")
        self.addCleanup(setattr, dot, "collect_health", original)
        code, out = self._capture(["health"])
        self.assertEqual(code, 0)
        self.assertIn("no problems", out)

    def test_health_command_exits_one_when_unhealthy(self):
        original = dot.collect_health
        dot.collect_health = lambda **kwargs: dot.Health(
            ok=False, counts={"broken": 1, "stale": 0, "missing": 0}, findings=[],
            text="●", tooltip="dot: 1 broken", style="bad")
        self.addCleanup(setattr, dot, "collect_health", original)
        code, out = self._capture(["health"])
        self.assertEqual(code, 1)
```

Also add a `_capture` helper to `HealthTests` — copy the four-line helper from `CliTests` (`_capture` at `tests/test_dot.py:710`), it redirects stdout and returns `(code, output)`.

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -m unittest discover -s tests -p test_dot.py -k Health -v`
Expected: FAIL — `AttributeError: module 'dot' has no attribute 'collect_health'`.

- [ ] **Step 3: Implement the probe in `.local/bin/dot`**

Add the section, between `_repo_dirty_finding`/`_sort_findings` and `build_inventory`:

```python
HEALTH_TEXT = "●"
HEALTH_SEVERITIES = ("broken", "stale", "missing")


def scan_home_configs(base: str, repo: str) -> list[Entry]:
    """The config entries of this home directory.

    One scan, one rule: `~/.config` is read three levels deep, `~/.local/share`
    only two, because a broken link in an application's state directory is
    noise rather than a configuration mistake.
    """
    return scan_configs(
        [os.path.join(base, ".config"), os.path.join(base, ".local", "share")],
        current_generation=current_generation(base),
        repo_dir=repo,
        home=base,
        shallow_roots={os.path.join(base, ".local", "share")},
    )


@dataclasses.dataclass(frozen=True)
class Health:
    """The cheap health of the machine: the links and the spawn targets."""

    ok: bool
    counts: dict[str, int]
    findings: list[Finding]
    text: str
    tooltip: str
    style: str


def collect_health(*, home: str | None = None, repo_dir: str | None = None) -> Health:
    """The cheap health probe: the config links and the compositor spawns only.

    The bar calls this on a timer, so it must not run pacman, nix or git: a
    full `dot status` costs more than a second, this costs about a tenth.
    """
    base = os.path.abspath(home) if home is not None else str(Path.home())
    repo = repo_dir if repo_dir is not None else default_repo_dir()
    if repo and not os.path.isdir(repo):
        repo = ""
    entries = scan_home_configs(base, repo)
    findings = findings_from_entries(entries)
    findings.extend(_spawn_findings(os.path.join(base, NIRI_CONFIG_REL)))
    counts = {key: 0 for key in HEALTH_SEVERITIES}
    for finding in findings:
        if finding.severity in counts:
            counts[finding.severity] += 1
    broken = counts["broken"] + counts["stale"] + counts["missing"]
    if broken:
        parts = [f"{counts[key]} {key}" for key in HEALTH_SEVERITIES if counts[key]]
        tooltip = "dot: " + " · ".join(parts)
        style = "bad"
    else:
        tooltip = "dot: no problems"
        style = "ok"
    return Health(
        ok=not broken,
        counts=counts,
        findings=findings,
        text=HEALTH_TEXT,
        tooltip=tooltip,
        style=style,
    )


def health_json(health: Health) -> dict:
    """Exactly the three keys a waybar json custom module reads."""
    return {"text": health.text, "tooltip": health.tooltip, "class": health.style}


def render_health(health: Health) -> str:
    """The one line a terminal shows."""
    if health.ok:
        return f"{health.text} no problems"
    parts = [f"{health.counts[key]} {key}" for key in HEALTH_SEVERITIES if health.counts[key]]
    return f"{health.text} {len(parts)} problems"
```

Register the subcommand in `main`, next to the existing `list`/`status` parsers:

```python
    p_health = sub.add_parser("health", help="a fast health check for the bar")
    p_health.add_argument("--json", action="store_true", help="print the waybar document")
```

and handle it **before** `inventory = build_inventory()` so the health probe never pays for the full inventory:

```python
    args = parser.parse_args(argv)

    if args.command == "health":
        health = collect_health()
        if args.json:
            print(json.dumps(health_json(health)))
        else:
            print(render_health(health))
        return 0 if health.ok else 1

    inventory = build_inventory()
```

In `build_inventory`, replace the inline `scan_configs(...)` call with the new helper
(`entries = scan_home_configs(base, repo)`). The arguments are identical, so the behaviour
is unchanged — the 101 existing tests are the guard. This keeps one scan rule in the file
instead of three copies of it.

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -m unittest discover -s tests -p test_dot.py -v`
Expected: OK — the whole suite passes, including the 101 existing tests.

- [ ] **Step 5: Check the probe is actually fast**

Run: `time ~/.local/bin/dot health`
Expected: the `ok` line, and a real time under 0.3 s. If it is slower, the probe is running something it must not — find it before continuing.

- [ ] **Step 6: Commit**

```bash
git add .local/bin/dot tests/test_dot.py
git commit -m "feat(dot): add the fast health probe for the bar"
```

---

### Task 2: the package list editor

**Files:**
- Modify: `.local/bin/dot` (new section `# ── package editing ──`)
- Test: `tests/test_dot.py` (new class `PackageEditorTests`)

**Interfaces:**
- Consumes: `DECLARATIONS_FILE` (`"nix/modules/packages.nix"`), `parse_declared_packages(text)`.
- Produces (Task 3 depends on every name here):
  - `@dataclasses.dataclass(frozen=True) class PackageEntry:` with fields `name: str`, `line: int` (1-based), `indent: str`
  - `class PackageEditError(Exception)`
  - `package_block(text: str) -> str` — the text between the `home.packages` list brackets
  - `package_entries(text: str) -> list[PackageEntry]`
  - `add_packages(text: str, names: list[str]) -> tuple[str, list[str]]`
  - `remove_packages(text: str, names: list[str]) -> tuple[str, list[str]]`

- [ ] **Step 1: Write the failing tests**

```python
PACKAGES_NIX = """{ pkgs, ... }:
{
  home.packages = with pkgs; [
    git
    neovim
    # a comment inside the list
    ripgrep
    (stdenvNoCC.mkDerivation {
      pname = "workmux";
      installPhase = ''
        true
      '';
    })
    libnotify
  ];
}
"""


class PackageEditorTests(unittest.TestCase):
    def test_package_entries_reads_the_declared_names(self):
        entries = dot.package_entries(PACKAGES_NIX)
        self.assertEqual([e.name for e in entries], ["git", "neovim", "ripgrep", "libnotify"])

    def test_package_entries_skips_a_derivation_block(self):
        entries = dot.package_entries(PACKAGES_NIX)
        self.assertNotIn("workmux", [e.name for e in entries])

    def test_package_entries_skips_comments(self):
        entries = dot.package_entries(PACKAGES_NIX)
        self.assertNotIn("# a comment inside the list", [e.name for e in entries])

    def test_add_packages_inserts_one_line_inside_the_list(self):
        text, added = dot.add_packages(PACKAGES_NIX, ["fd"])
        self.assertEqual(added, ["fd"])
        self.assertIn("\n    fd\n", text)
        self.assertEqual([e.name for e in dot.package_entries(text)],
                         ["git", "neovim", "ripgrep", "libnotify", "fd"])

    def test_add_packages_skips_a_name_that_is_already_declared(self):
        text, added = dot.add_packages(PACKAGES_NIX, ["git"])
        self.assertEqual(added, [])
        self.assertEqual(text, PACKAGES_NIX)

    def test_add_packages_without_a_list_raises(self):
        with self.assertRaises(dot.PackageEditError):
            dot.add_packages("{ pkgs, ... }: { }", ["fd"])

    def test_remove_packages_removes_the_whole_line(self):
        text, removed = dot.remove_packages(PACKAGES_NIX, ["ripgrep"])
        self.assertEqual(removed, ["ripgrep"])
        self.assertNotIn("    ripgrep\n", text)
        self.assertIn("    git\n", text)

    def test_remove_packages_refuses_an_entry_that_is_an_expression(self):
        with self.assertRaises(dot.PackageEditError):
            dot.remove_packages(PACKAGES_NIX, ["workmux"])

    def test_remove_packages_ignores_a_name_that_is_not_declared(self):
        text, removed = dot.remove_packages(PACKAGES_NIX, ["nothing"])
        self.assertEqual(removed, [])
        self.assertEqual(text, PACKAGES_NIX)

    def test_add_and_remove_round_trip_leaves_the_file_unchanged(self):
        text, _ = dot.add_packages(PACKAGES_NIX, ["fd"])
        text, _ = dot.remove_packages(text, ["fd"])
        self.assertEqual(text, PACKAGES_NIX)
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -m unittest discover -s tests -p test_dot.py -k PackageEditor -v`
Expected: FAIL — `AttributeError: module 'dot' has no attribute 'package_entries'`.

- [ ] **Step 3: Implement the editor in `.local/bin/dot`**

```python
PACKAGE_NAME_RE = re.compile(r"^[A-Za-z0-9_][A-Za-z0-9_.'-]*$")
PACKAGE_LIST_RE = re.compile(r"home\.packages\s*=\s*with\s+pkgs\s*;")
DEFAULT_PACKAGE_INDENT = "    "


@dataclasses.dataclass(frozen=True)
class PackageEntry:
    """One bare package name inside the home.packages list."""

    name: str
    line: int
    indent: str


class PackageEditError(Exception):
    """The package list cannot be edited the way the caller asked."""


def _package_list_bounds(text: str) -> tuple[int, int] | None:
    """The line numbers of the home.packages list, opening bracket included."""
    lines = text.splitlines()
    for index, line in enumerate(lines):
        if not PACKAGE_LIST_RE.search(line):
            continue
        if "[" not in line:
            continue
        for end in range(index + 1, len(lines)):
            if lines[end].strip().startswith("]"):
                return index, end
    return None


def package_entries(text: str) -> list[PackageEntry]:
    """The bare package names of the home.packages list, in file order.

    An entry that is an expression (a derivation written over several lines)
    is not a name this tool can add or remove, so it is not an entry.
    """
    bounds = _package_list_bounds(text)
    if bounds is None:
        return []
    start, end = bounds
    lines = text.splitlines()
    entries: list[PackageEntry] = []
    depth = 0
    for number in range(start + 1, end):
        raw = lines[number]
        stripped = raw.strip()
        depth += raw.count("(") - raw.count(")")
        if depth != 0 or not stripped or stripped.startswith("#"):
            continue
        if not PACKAGE_NAME_RE.match(stripped):
            continue
        entries.append(PackageEntry(
            name=stripped,
            line=number + 1,
            indent=raw[: len(raw) - len(raw.lstrip())],
        ))
    return entries


def package_block(text: str) -> str:
    """The text inside the home.packages list."""
    bounds = _package_list_bounds(text)
    if bounds is None:
        return ""
    start, end = bounds
    return "\n".join(text.splitlines()[start + 1: end])


def add_packages(text: str, names: list[str]) -> tuple[str, list[str]]:
    """Add the names that are not declared yet; returns the new text and what was added."""
    bounds = _package_list_bounds(text)
    if bounds is None:
        raise PackageEditError(f"{DECLARATIONS_FILE} has no home.packages list")
    entries = package_entries(text)
    declared = {entry.name for entry in entries}
    wanted = [name for name in names if name not in declared]
    if not wanted:
        return text, []
    lines = text.splitlines()
    indent = entries[-1].indent if entries else DEFAULT_PACKAGE_INDENT
    insert_at = entries[-1].line if entries else bounds[0] + 1
    for offset, name in enumerate(wanted):
        lines.insert(insert_at + offset, f"{indent}{name}")
    return "\n".join(lines) + ("\n" if text.endswith("\n") else ""), wanted


def remove_packages(text: str, names: list[str]) -> tuple[str, list[str]]:
    """Remove the named packages; returns the new text and what was removed.

    A name that is present but is not a bare entry cannot be removed without
    the caller editing the file by hand, so it is refused.
    """
    bounds = _package_list_bounds(text)
    if bounds is None:
        raise PackageEditError(f"{DECLARATIONS_FILE} has no home.packages list")
    entries = package_entries(text)
    by_name = {entry.name: entry for entry in entries}
    block = package_block(text)
    removed: list[str] = []
    for name in names:
        if name in by_name:
            removed.append(name)
        elif name in block:
            raise PackageEditError(
                f"{name} is not a plain entry — it is an expression; edit the file by hand")
    if not removed:
        return text, []
    lines = text.splitlines()
    for entry in sorted((by_name[name] for name in removed), key=lambda e: -e.line):
        del lines[entry.line - 1]
    return "\n".join(lines) + ("\n" if text.endswith("\n") else ""), removed
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -m unittest discover -s tests -p test_dot.py -v`
Expected: OK — the whole suite passes.

- [ ] **Step 5: Try it on the real file**

Run: `python3 -c "
import importlib.machinery, importlib.util, sys
spec = importlib.util.spec_from_loader('dot', importlib.machinery.SourceFileLoader('dot', '.local/bin/dot'))
dot = importlib.util.module_from_spec(spec); sys.modules['dot'] = dot; spec.loader.exec_module(dot)
text = open('nix/modules/packages.nix').read()
print([e.name for e in dot.package_entries(text)])
"`
Expected: the declared names, including `workmux` **excluded** and `traceroute` present.

- [ ] **Step 6: Commit**

```bash
git add .local/bin/dot tests/test_dot.py
git commit -m "feat(dot): edit the home.packages list without rewriting the file"
```

---

### Task 3: `dot pkg` — add, remove, sync

**Files:**
- Modify: `.local/bin/dot` (new section `# ── dot pkg ──`, and the `main` wiring)
- Test: `tests/test_dot.py` (new class `PkgTests`)

**Interfaces:**
- Consumes: `package_entries`, `package_block`, `add_packages`, `remove_packages`, `PackageEditError`, `DECLARATIONS_FILE`, `default_repo_dir()`, `_run`, `collect_profile_entries`, `package_binary_map`, `parse_declared_packages`, `nix_drift`.
- Produces:
  - `SWITCH_TIMEOUT = 900`
  - `nix_attribute_name(name: str, repo_dir: str, runner=None) -> str | None`
  - `home_manager_configurations(repo_dir: str, runner=None) -> list[str]`
  - `run_home_manager_switch(repo_dir: str, config: str, runner=None) -> tuple[bool, str]`
  - `package_diff(before: str, after: str, path: str) -> str`
  - `confirm(question: str, *, assume_yes: bool = False, stream=None) -> bool`
  - `apply_package_change(repo_dir: str, new_text: str, old_text: str, config: str, *, runner=None) -> tuple[bool, str]`
  - `pkg_list_output(*, home=None, repo_dir=None) -> str`
  - CLI: `dot pkg list`, `dot pkg add NAME...`, `dot pkg rm NAME...`, `dot pkg sync`, each with `--yes`, `--dry-run`, `--config`

- [ ] **Step 1: Write the failing tests**

```python
class PkgTests(unittest.TestCase):
    """dot pkg is the only mutating command; it never uses sudo."""

    def _repo(self, t, text=PACKAGES_NIX):
        repo = t.path / "dotfiles"
        (repo / "nix" / "modules").mkdir(parents=True)
        (repo / "nix" / "modules" / "packages.nix").write_text(text)
        return str(repo)

    def _stub_config(self, name="zeyad"):
        original = dot.home_manager_configurations
        dot.home_manager_configurations = lambda repo_dir, runner=None: [name]
        self.addCleanup(setattr, dot, "home_manager_configurations", original)

    def test_nix_attribute_name_accepts_a_known_attribute(self):
        def fake_runner(cmd, **kwargs):
            self.assertIn("legacyPackages", cmd[-1])
            return subprocess.CompletedProcess(cmd, 0, "git-2.55.0\n", "")
        self.assertEqual(dot.nix_attribute_name("git", "/repo", runner=fake_runner), "git-2.55.0")

    def test_nix_attribute_name_rejects_an_unknown_attribute(self):
        def fake_runner(cmd, **kwargs):
            return subprocess.CompletedProcess(cmd, 1, "", "error: attribute 'zzz' missing")
        self.assertIsNone(dot.nix_attribute_name("zzz", "/repo", runner=fake_runner))

    def test_home_manager_configurations_reads_the_flake(self):
        def fake_runner(cmd, **kwargs):
            return subprocess.CompletedProcess(cmd, 0, '["zeyad"]\n', "")
        self.assertEqual(dot.home_manager_configurations("/repo", runner=fake_runner), ["zeyad"])

    def test_run_home_manager_switch_reports_failure(self):
        def fake_runner(cmd, **kwargs):
            self.assertEqual(cmd[:2], ["home-manager", "switch"])
            return subprocess.CompletedProcess(cmd, 1, "", "error: build failed")
        ok, output = dot.run_home_manager_switch("/repo", "zeyad", runner=fake_runner)
        self.assertFalse(ok)
        self.assertIn("build failed", output)

    def test_package_diff_shows_the_added_line(self):
        after, _ = dot.add_packages(PACKAGES_NIX, ["fd"])
        diff = dot.package_diff(PACKAGES_NIX, after, "nix/modules/packages.nix")
        self.assertIn("+    fd", diff)

    def test_confirm_without_a_terminal_is_no(self):
        self.assertFalse(dot.confirm("Apply?", stream=io.StringIO("\n")))

    def test_confirm_with_assume_yes_is_yes(self):
        self.assertTrue(dot.confirm("Apply?", assume_yes=True, stream=io.StringIO("")))

    def test_apply_package_change_restores_the_file_when_the_switch_fails(self):
        with TempTree() as t:
            repo = self._repo(t)
            path = os.path.join(repo, "nix", "modules", "packages.nix")
            before = open(path).read()
            after, _ = dot.add_packages(before, ["fd"])

            def fake_runner(cmd, **kwargs):
                return subprocess.CompletedProcess(cmd, 1, "", "error: build failed")

            ok, _ = dot.apply_package_change(repo, after, before, "zeyad", runner=fake_runner)
            self.assertFalse(ok)
            self.assertEqual(open(path).read(), before)

    def test_pkg_add_maps_a_binary_name_to_its_package(self):
        with TempTree() as t:
            repo = self._repo(t)
            self._stub_config()
            path = os.path.join(repo, "nix", "modules", "packages.nix")

            def fake_attr(name, repo_dir, runner=None):
                return "ripgrep-14.1.0" if name == "ripgrep" else None

            original = dot.nix_attribute_name
            dot.nix_attribute_name = fake_attr
            self.addCleanup(setattr, dot, "nix_attribute_name", original)

            original_map = dot.package_binary_map
            dot.package_binary_map = lambda *args, **kwargs: {"ripgrep": ["rg"]}
            self.addCleanup(setattr, dot, "package_binary_map", original_map)

            original_switch = dot.run_home_manager_switch
            dot.run_home_manager_switch = lambda repo_dir, config, runner=None: (True, "ok")
            self.addCleanup(setattr, dot, "run_home_manager_switch", original_switch)

            code, out = self._capture(["pkg", "add", "rg", "--yes"], repo=repo)
            self.assertEqual(code, 0)
            text = open(path).read()
            self.assertIn("    ripgrep\n", text)
            self.assertNotIn("    rg\n", text)

    def test_pkg_add_refuses_without_a_confirmation(self):
        with TempTree() as t:
            repo = self._repo(t)
            self._stub_config()
            path = os.path.join(repo, "nix", "modules", "packages.nix")
            before = open(path).read()

            def fake_attr(name, repo_dir, runner=None):
                return "fd-9.0.0"

            original = dot.nix_attribute_name
            dot.nix_attribute_name = fake_attr
            self.addCleanup(setattr, dot, "nix_attribute_name", original)

            code, out = self._capture(["pkg", "add", "fd"], repo=repo, assume_yes=False)
            self.assertEqual(code, 1)
            self.assertEqual(open(path).read(), before)

    def test_pkg_add_writes_the_file_and_runs_the_switch(self):
        with TempTree() as t:
            repo = self._repo(t)
            self._stub_config()
            path = os.path.join(repo, "nix", "modules", "packages.nix")
            switched = []

            def fake_attr(name, repo_dir, runner=None):
                return "fd-9.0.0"

            def fake_switch(repo_dir, config, runner=None):
                switched.append((repo_dir, config))
                return True, "ok"

            original = dot.nix_attribute_name
            dot.nix_attribute_name = fake_attr
            self.addCleanup(setattr, dot, "nix_attribute_name", original)
            original_switch = dot.run_home_manager_switch
            dot.run_home_manager_switch = fake_switch
            self.addCleanup(setattr, dot, "run_home_manager_switch", original_switch)

            code, out = self._capture(["pkg", "add", "fd", "--yes"], repo=repo)
            self.assertEqual(code, 0)
            self.assertIn("fd", open(path).read())
            self.assertEqual(switched, [(repo, "zeyad")])

    def test_pkg_never_runs_sudo_or_a_mutating_pacman(self):
        recorded = []
        real_run = subprocess.run

        def spy(cmd, *args, **kwargs):
            recorded.append(cmd if isinstance(cmd, list) else [cmd])
            if cmd and cmd[0] == "home-manager":
                return subprocess.CompletedProcess(cmd, 0, "ok\n", "")
            return real_run(cmd, *args, **kwargs)

        subprocess.run = spy
        self.addCleanup(setattr, subprocess, "run", real_run)
        with TempTree() as t:
            repo = self._repo(t)
            self._stub_config()
            original_repo = dot.default_repo_dir
            dot.default_repo_dir = lambda: repo
            self.addCleanup(setattr, dot, "default_repo_dir", original_repo)
            with contextlib.redirect_stdout(io.StringIO()):
                code = dot.main(["pkg", "sync", "--yes"])
        self.assertEqual(code, 0)
        self.assertTrue(recorded, "dot pkg ran no command at all, so nothing was checked")
        for cmd in recorded:
            program = os.path.basename(cmd[0])
            self.assertNotEqual(program, "sudo")
            if program == "pacman":
                self.assertNotIn(cmd[1], ("-S", "-R", "-U", "-Sy", "-Rns"))
```

The `_capture` helper for this class takes the repo and the confirmation flag, because `dot pkg` needs a repository to work on:

```python
    def _capture(self, argv, repo=None, assume_yes=False):
        buf = io.StringIO()
        original_repo = dot.default_repo_dir
        original_confirm = dot.confirm
        if repo is not None:
            dot.default_repo_dir = lambda: repo
        dot.confirm = lambda question, **kwargs: assume_yes
        self.addCleanup(setattr, dot, "default_repo_dir", original_repo)
        self.addCleanup(setattr, dot, "confirm", original_confirm)
        with contextlib.redirect_stdout(buf):
            code = dot.main(argv)
        return code, buf.getvalue()
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -m unittest discover -s tests -p test_dot.py -k Pkg -v`
Expected: FAIL — `AttributeError: module 'dot' has no attribute 'nix_attribute_name'`.

- [ ] **Step 3: Implement the nix helpers in `.local/bin/dot`**

```python
SWITCH_TIMEOUT = 900
NIX_EVAL_TIMEOUT = 120


def _nix_expr(repo_dir: str, expression: str) -> str:
    """A nix expression that reads the flake of this repository."""
    return f'(builtins.getFlake "{repo_dir}").{expression}'


def nix_attribute_name(name: str, repo_dir: str, runner=None) -> str | None:
    """The nixpkgs version of an attribute, or None when nixpkgs has no such attribute.

    The attribute is looked up in the flake's own nixpkgs, so a name that
    resolves here is a name the configuration can build.
    """
    expression = _nix_expr(
        repo_dir,
        f"inputs.nixpkgs.legacyPackages.${{builtins.currentSystem}}.{name}.name",
    )
    output = _run(["nix", "eval", "--impure", "--raw", "--expr", expression],
                  runner, timeout=NIX_EVAL_TIMEOUT).strip()
    return output or None


def home_manager_configurations(repo_dir: str, runner=None) -> list[str]:
    """The homeConfigurations the flake exposes."""
    expression = _nix_expr(repo_dir, "outputs.homeConfigurations")
    output = _run(["nix", "eval", "--impure", "--json", "--expr",
                   f"builtins.attrNames {expression}"],
                  runner, timeout=NIX_EVAL_TIMEOUT).strip()
    if not output:
        return []
    try:
        names = json.loads(output)
    except json.JSONDecodeError:
        return []
    return [str(name) for name in names] if isinstance(names, list) else []


def run_home_manager_switch(repo_dir: str, config: str, runner=None) -> tuple[bool, str]:
    """Run `home-manager switch`; returns whether it worked and what it said."""
    cmd = ["home-manager", "switch", "--flake", f"{repo_dir}#{config}"]
    run = runner or subprocess.run
    try:
        proc = run(cmd, capture_output=True, text=True, check=False, timeout=SWITCH_TIMEOUT)
    except (FileNotFoundError, OSError, subprocess.TimeoutExpired) as error:
        return False, str(error)
    output = (proc.stdout or "") + (proc.stderr or "")
    return proc.returncode == 0, output


def package_diff(before: str, after: str, path: str) -> str:
    """A unified diff of the change, for the confirmation prompt."""
    diff = difflib.unified_diff(
        before.splitlines(keepends=True),
        after.splitlines(keepends=True),
        fromfile=f"a/{path}",
        tofile=f"b/{path}",
    )
    return "".join(diff)


def confirm(question: str, *, assume_yes: bool = False, stream=None) -> bool:
    """Ask the question; without a terminal the answer is no."""
    if assume_yes:
        return True
    source = stream if stream is not None else sys.stdin
    try:
        interactive = source.isatty()
    except (AttributeError, ValueError):
        interactive = False
    if not interactive:
        print(f"{question} [y/N] (no terminal: refusing)")
        return False
    print(f"{question} [y/N] ", end="", flush=True)
    answer = source.readline().strip().lower()
    return answer in ("y", "yes")


def resolve_package_name(name: str, package_bins: dict[str, list[str]]) -> str | None:
    """The package that provides a binary, when the profile knows one."""
    for package, binaries in package_bins.items():
        if name in binaries:
            return package
    return None
```

Add `import difflib` to the imports at the top of the file.

- [ ] **Step 4: Implement the `dot pkg` command**

```python
def pkg_list_output(*, home: str | None = None, repo_dir: str | None = None) -> str:
    """The declared packages and whether the profile has them."""
    base = home if home is not None else str(Path.home())
    repo = repo_dir if repo_dir is not None else default_repo_dir()
    path = os.path.join(repo, DECLARATIONS_FILE)
    try:
        with open(path, encoding="utf-8") as handle:
            text = handle.read()
    except OSError:
        return f"{DECLARATIONS_FILE} cannot be read: {repo}"
    declared = parse_declared_packages(text)
    profile_dir = os.path.join(base, PROFILE_BIN_REL)
    entries = collect_profile_entries()
    installed = {entry.get("name", "") for entry in entries}
    lines = [f"Declared packages ({len(declared)}):"]
    for name in sorted(declared):
        mark = "installed" if name in installed else "declared"
        lines.append(f"  {name}  ({mark})")
    return "\n".join(lines)


def apply_package_change(
    repo_dir: str,
    new_text: str,
    old_text: str,
    config: str,
    *,
    runner=None,
) -> tuple[bool, str]:
    """Write the file, run the switch, and restore the file when the switch fails."""
    path = os.path.join(repo_dir, DECLARATIONS_FILE)
    try:
        with open(path, "w", encoding="utf-8") as handle:
            handle.write(new_text)
    except OSError as error:
        return False, f"cannot write {path}: {error}"
    ok, output = run_home_manager_switch(repo_dir, config, runner=runner)
    if not ok:
        try:
            with open(path, "w", encoding="utf-8") as handle:
                handle.write(old_text)
        except OSError as error:
            return False, f"the switch failed and the file could not be restored: {error}\n{output}"
        return False, f"the switch failed, the file was restored\n{output}"
    return True, output
```

Wire the subcommand in `main`:

```python
    p_pkg = sub.add_parser("pkg", help="manage the nix packages of the profile")
    pkg_sub = p_pkg.add_subparsers(dest="pkg_command", required=True)
    pkg_sub.add_parser("list", help="show the declared packages")
    for action, help_text in (("add", "add packages"), ("rm", "remove packages")):
        parser_action = pkg_sub.add_parser(action, help=help_text)
        parser_action.add_argument("names", nargs="+", help="the package names")
        parser_action.add_argument("--yes", action="store_true", help="do not ask")
        parser_action.add_argument("--dry-run", action="store_true", help="print the change and stop")
        parser_action.add_argument("--config", default="", help="the Home Manager configuration name")
    parser_sync = pkg_sub.add_parser("sync", help="apply the repository as it stands")
    parser_sync.add_argument("--yes", action="store_true", help="do not ask")
    parser_sync.add_argument("--config", default="", help="the Home Manager configuration name")
```

and the handler, placed **before** `inventory = build_inventory()` so `dot pkg` never pays for the inventory:

```python
    if args.command == "pkg":
        return pkg_main(args)
```

```python
def pkg_main(args) -> int:
    """The `dot pkg` command: the only part of `dot` that changes anything."""
    repo = default_repo_dir()
    if not repo:
        print("the dotfiles repository cannot be found", file=sys.stderr)
        return 1
    path = os.path.join(repo, DECLARATIONS_FILE)
    if args.pkg_command == "list":
        print(pkg_list_output(repo_dir=repo))
        return 0
    config = args.config or ""
    if not config:
        configs = home_manager_configurations(repo)
        if len(configs) == 1:
            config = configs[0]
        elif not configs:
            print("the flake exposes no home configuration", file=sys.stderr)
            return 1
        else:
            print(f"the flake exposes {', '.join(configs)} — choose one with --config",
                  file=sys.stderr)
            return 1
    try:
        with open(path, encoding="utf-8") as handle:
            before = handle.read()
    except OSError as error:
        print(f"cannot read {path}: {error}", file=sys.stderr)
        return 1
    if args.pkg_command == "sync":
        print(f"running home-manager switch for {repo}#{config}")
        ok, output = run_home_manager_switch(repo, config)
        print(output)
        return 0 if ok else 1
    names = []
    for name in args.names:
        resolved = nix_attribute_name(name, repo)
        if resolved is None:
            mapped = resolve_package_name(name, package_binary_map())
            if mapped is None:
                print(f"{name} is not a nixpkgs package", file=sys.stderr)
                return 1
            resolved = nix_attribute_name(mapped, repo)
            if resolved is None:
                print(f"{name} is not a nixpkgs package", file=sys.stderr)
                return 1
            name = mapped
        names.append(name)
    try:
        if args.pkg_command == "add":
            after, changed = add_packages(before, names)
        else:
            after, changed = remove_packages(before, names)
    except PackageEditError as error:
        print(str(error), file=sys.stderr)
        return 1
    if not changed:
        print("nothing to change")
        return 0
    diff = package_diff(before, after, DECLARATIONS_FILE)
    print(diff)
    if args.dry_run:
        return 0
    if not confirm("Apply this change?", assume_yes=args.yes):
        print("nothing was changed")
        return 1
    ok, output = apply_package_change(repo, after, before, config)
    print(output)
    if not ok:
        print("the change was not applied", file=sys.stderr)
        return 1
    print("the profile was updated")
    return 0
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `python3 -m unittest discover -s tests -p test_dot.py -v`
Expected: OK — the whole suite passes.

- [ ] **Step 6: Try it on the real repository, without changing anything**

Run: `~/.local/bin/dot pkg list`
Expected: the declared packages, `traceroute` among them.

Run: `~/.local/bin/dot pkg add fd --dry-run`
Expected: the unified diff of the added line, and **no** change to `nix/modules/packages.nix`. Check with `git diff --stat nix/modules/packages.nix` — the file must still show only the user's own `traceroute` modification.

- [ ] **Step 7: Commit**

```bash
git add .local/bin/dot tests/test_dot.py
git commit -m "feat(dot): add dot pkg to manage the nix profile"
```

---

### Task 4: `dot browse` — the fzf launcher

**Files:**
- Modify: `.local/bin/dot` (new section `# ── browse ──`)
- Test: `tests/test_dot.py` (new class `BrowseTests`)

**Interfaces:**
- Consumes: `collect_desktop_entries(dirs, *, home)`, `collect_profile_bins(profile_dir)`, `tool_dir_paths(home)`, `collect_tool_dirs(dirs)`, `collect_scripts(bin_dir, repo_dir)`, `scan_configs(...)`, `classify(...)`, `_run`, `DESKTOP_DIRS`, `SYSTEM_DESKTOP_DIR`, `PROFILE_BIN_REL`.
- Produces:
  - `browse_rows(*, home=None, repo_dir=None) -> list[dict]` — each row `{"id", "kind", "label", "detail"}`
  - `run_fzf(rows: list[str], *, runner=None) -> list[str]`
  - `show_item(item_id: str, *, home=None, repo_dir=None) -> str`
  - `browse(*, home=None, repo_dir=None, runner=None, launcher=None) -> int`
  - CLI: `dot browse`

- [ ] **Step 1: Write the failing tests**

```python
class BrowseTests(unittest.TestCase):
    """The browser knows what the machine owns, and degrades when fzf is missing."""

    def _home(self, t):
        home = t.path / "home"
        (home / ".config").mkdir(parents=True)
        (home / ".local" / "bin").mkdir(parents=True)
        (home / ".local" / "share" / "applications").mkdir(parents=True)
        return home

    def test_browse_rows_cover_apps_cli_scripts_and_configs(self):
        with TempTree() as t:
            home = self._home(t)
            (home / ".local" / "share" / "applications" / "demo.desktop").write_text(
                "[Desktop Entry]\nName=Demo\n")
            (home / ".local" / "bin" / "myscript").write_text("#!/bin/sh\n")
            (home / ".config" / "demo").mkdir()
            rows = dot.browse_rows(home=str(home), repo_dir=str(t.path / "dotfiles"))
            kinds = {row["kind"] for row in rows}
            self.assertIn("app", kinds)
            self.assertIn("script", kinds)
            self.assertIn("config", kinds)

    def test_browse_prints_the_rows_when_fzf_is_missing(self):
        with TempTree() as t:
            home = self._home(t)
            (home / ".config" / "demo").mkdir()

            def fake_runner(cmd, stdin_text=None, **kwargs):
                raise FileNotFoundError("fzf")

            buf = io.StringIO()
            with contextlib.redirect_stdout(buf):
                code = dot.browse(home=str(home), repo_dir=str(t.path / "dotfiles"),
                                  runner=fake_runner)
            self.assertEqual(code, 0)
            self.assertIn("config", buf.getvalue())

    def test_browse_launches_the_selected_app(self):
        launched = []

        def fake_runner(cmd, stdin_text=None, **kwargs):
            return "app:Demo\0"

        def fake_launcher(cmd):
            launched.append(cmd)

        with TempTree() as t:
            home = self._home(t)
            (home / ".local" / "share" / "applications" / "demo.desktop").write_text(
                "[Desktop Entry]\nName=Demo\n")
            code = dot.browse(home=str(home), repo_dir=str(t.path / "dotfiles"),
                              runner=fake_runner, launcher=fake_launcher)
            self.assertEqual(code, 0)
            self.assertTrue(launched)
            self.assertEqual(launched[0][0], "gtk-launch")
            self.assertEqual(launched[0][1], "demo")

    def test_browse_opens_the_selected_config(self):
        launched = []

        def fake_runner(cmd, stdin_text=None, **kwargs):
            return "config:/tmp/x\0"

        def fake_launcher(cmd):
            launched.append(cmd)

        with TempTree() as t:
            home = self._home(t)
            code = dot.browse(home=str(home), repo_dir=str(t.path / "dotfiles"),
                              runner=fake_runner, launcher=fake_launcher)
            self.assertEqual(code, 0)
            self.assertTrue(launched)

    def test_browse_copies_the_path_of_a_selected_tool(self):
        launched = []

        def fake_runner(cmd, stdin_text=None, **kwargs):
            return "cli:rg\0"

        def fake_launcher(cmd):
            launched.append(cmd)

        with TempTree() as t:
            home = self._home(t)
            code = dot.browse(home=str(home), repo_dir=str(t.path / "dotfiles"),
                              runner=fake_runner, launcher=fake_launcher)
            self.assertEqual(code, 0)
            self.assertTrue(launched)
            self.assertEqual(launched[0][0], "wl-copy")

    def test_show_item_reports_the_owner_of_a_config(self):
        with TempTree() as t:
            home = self._home(t)
            repo = t.path / "dotfiles"
            (repo / ".config").mkdir(parents=True)
            (repo / ".config" / "niri").write_text("x")
            link = home / ".config" / "niri"
            link.symlink_to(repo / ".config" / "niri")
            text = dot.show_item(f"config:{link}", home=str(home), repo_dir=str(repo))
            self.assertIn("dotfiles", text)

    def test_show_item_resolves_a_binary(self):
        with TempTree() as t:
            home = self._home(t)
            text = dot.show_item("cli:sh", home=str(home), repo_dir=str(t.path / "dotfiles"))
            self.assertIn("sh", text)
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -m unittest discover -s tests -p test_dot.py -k Browse -v`
Expected: FAIL — `AttributeError: module 'dot' has no attribute 'browse_rows'`.

- [ ] **Step 3: Implement the browser in `.local/bin/dot`**

```python
BROWSE_KINDS = ("app", "cli", "script", "config")


def browse_rows(*, home: str | None = None, repo_dir: str | None = None) -> list[dict]:
    """The items the browser offers: apps, cli tools, scripts and config files.

    It skips the expensive pacman queries: a browser that takes a second to
    open is a browser nobody opens.
    """
    base = os.path.abspath(home) if home is not None else str(Path.home())
    repo = repo_dir if repo_dir is not None else default_repo_dir()
    rows: list[dict] = []
    app_dirs = [os.path.join(base, relative) for relative in DESKTOP_DIRS]
    app_dirs.append(SYSTEM_DESKTOP_DIR)
    for app in collect_desktop_entries(app_dirs, home=base):
        name = app.get("name", "")
        desktop_file = app.get("desktop_file", "")
        rows.append({
            "id": f"app:{name}",
            "kind": "app",
            "label": name,
            "detail": app.get("source", ""),
            "target": os.path.basename(desktop_file)[:-len(".desktop")] if desktop_file else name,
        })
    names = collect_profile_bins(os.path.join(base, PROFILE_BIN_REL))
    for tool, items in collect_tool_dirs(tool_dir_paths(base)).items():
        names.extend(items)
    for name in sorted(set(names)):
        rows.append({"id": f"cli:{name}", "kind": "cli", "label": name,
                     "detail": "cli", "target": name})
    scripts = collect_scripts(os.path.join(base, ".local", "bin"), repo or None)
    for group, script_names in scripts.items():
        for name in script_names:
            rows.append({"id": f"script:{name}", "kind": "script", "label": name,
                         "detail": group, "target": name})
    for entry in scan_home_configs(base, repo):
        if entry.owner.kind == RUNTIME_OWNER:
            continue
        rows.append({"id": f"config:{entry.path}", "kind": "config",
                     "label": entry.path, "detail": entry.owner.kind,
                     "target": entry.owner.target})
    return rows


def _run_with_input(cmd: list[str], stdin_text: str) -> str:
    """Run a command and feed it text on stdin."""
    proc = subprocess.run(cmd, input=stdin_text, capture_output=True, text=True, check=False)
    return proc.stdout


def run_fzf(rows: list[str], *, runner=None) -> list[str] | None:
    """Feed the rows to fzf and return the chosen ids.

    None means fzf is not installed, so the caller can print the rows
    instead; an empty list means fzf ran and nothing was chosen.
    """
    script = os.path.realpath(__file__)
    cmd = [
        "fzf",
        "--delimiter=\t",
        "--with-nth=2..",
        "--multi",
        "--print0",
        f"--preview={script} show {{1}}",
    ]
    run = runner or _run_with_input
    try:
        output = run(cmd, "\n".join(rows) + "\n")
    except (FileNotFoundError, OSError):
        return None
    return [line.strip() for line in output.split("\0") if line.strip()]


def show_item(item_id: str, *, home=None, repo_dir=None) -> str:
    """The details of one item, for the browser preview."""
    base = os.path.abspath(home) if home is not None else str(Path.home())
    repo = repo_dir if repo_dir is not None else default_repo_dir()
    kind, _, name = item_id.partition(":")
    if kind == "config":
        owner = classify(name, current_generation=current_generation(base),
                         repo_dir=repo, home=base)
        return f"{name}\nowner: {owner.kind}\ntarget: {owner.target}"
    if kind == "app":
        app_dirs = [os.path.join(base, relative) for relative in DESKTOP_DIRS]
        app_dirs.append(SYSTEM_DESKTOP_DIR)
        for app in collect_desktop_entries(app_dirs, home=base):
            if app.get("name") == name:
                return (f"{name}\ndesktop file: {app.get('desktop_file', '')}"
                        f"\nsource: {app.get('source', '')}")
        return f"{name}\nnot found"
    path = shutil.which(name)
    if path is None:
        candidate = os.path.join(base, ".local", "bin", name)
        path = candidate if os.path.exists(candidate) else None
    if path is None:
        return f"{name}\nnot found on PATH"
    return f"{name}\npath: {path}"


def browse(*, home=None, repo_dir=None, runner=None, launcher=None) -> int:
    """The interactive browser over everything the machine owns."""
    base = os.path.abspath(home) if home is not None else str(Path.home())
    rows = browse_rows(home=base, repo_dir=repo_dir)
    if not rows:
        print("nothing to browse")
        return 0
    lines = [f"{row['id']}\t{row['label']}\t{row['detail']}" for row in rows]
    chosen = run_fzf(lines, runner=runner)
    if chosen is None:
        print("\n".join(f"{row['label']}  ({row['kind']})" for row in rows))
        return 0
    if not chosen:
        print("nothing was chosen")
        return 0
    by_id = {row["id"]: row for row in rows}
    run = launcher or (lambda cmd: subprocess.run(cmd, check=False))
    for item_id in chosen:
        row = by_id.get(item_id, {})
        kind, _, name = item_id.partition(":")
        if kind == "app":
            run(["gtk-launch", row.get("target") or name])
        elif kind == "config":
            editor = os.environ.get("EDITOR", "xdg-open")
            run([editor, name])
        else:
            path = shutil.which(name) or os.path.join(base, ".local", "bin", name)
            run(["wl-copy", path])
            print(path)
    return 0
```

Register the subcommand in `main`:

```python
    p_browse = sub.add_parser("browse", help="search everything the machine owns")
    p_show = sub.add_parser("show", help="the details of one item")
    p_show.add_argument("item", help="the id of the item, for example config:/home/zeyad/.config/niri")
```

and handle both before `build_inventory()`:

```python
    if args.command == "browse":
        return browse()

    if args.command == "show":
        print(show_item(args.item))
        return 0
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -m unittest discover -s tests -p test_dot.py -v`
Expected: OK — the whole suite passes.

- [ ] **Step 5: Try it for real**

Run: `~/.local/bin/dot browse`
Expected: the fzf picker opens with apps, cli tools, scripts and configs. Press `Esc` to leave. If fzf is not on the PATH in this shell, the row list is printed instead.

- [ ] **Step 6: Commit**

```bash
git add .local/bin/dot tests/test_dot.py
git commit -m "feat(dot): add the browse launcher over the inventory"
```

---

### Task 5: `dot keys` — the niri cheat sheet

**Files:**
- Modify: `.local/bin/dot` (new section `# ── keys ──`)
- Modify: `.config/niri/config.kdl` (add one bind)
- Test: `tests/test_dot.py` (new class `KeyTests`)

**Interfaces:**
- Consumes: `NIRI_CONFIG_REL`, `Path`, `re`.
- Produces:
  - `@dataclasses.dataclass(frozen=True) class KeyBinding:` with fields `keys: str`, `action: str`, `description: str`
  - `parse_key_bindings(text: str) -> list[KeyBinding]`
  - `describe_action(action: str, *, lang: str = "ar") -> str`
  - `render_key_bindings(bindings: list[KeyBinding], *, lang: str = "ar") -> str`
  - `key_bindings(*, home=None) -> list[KeyBinding]`
  - CLI: `dot keys [--lang ar|en] [--gui]`

- [ ] **Step 1: Write the failing tests**

Add `import shutil` to the imports at the top of `tests/test_dot.py` — the suite does not
import it yet and the window fallback test needs it.

```python
NIRI_CONFIG = """
binds {
    Mod+Shift+Slash { show-hotkey-overlay; }
    Mod+T { spawn "kitty"; }
    Mod+O { toggle-overview; }
    XF86AudioRaiseVolume allow-when-locked=true { spawn "swayosd-client" "--output-volume" "raise"; }
}
"""


class KeyTests(unittest.TestCase):
    def test_parses_the_bindings_of_a_niri_config(self):
        bindings = dot.parse_key_bindings(NIRI_CONFIG)
        self.assertEqual([b.keys for b in bindings],
                         ["Mod+Shift+Slash", "Mod+T", "Mod+O", "XF86AudioRaiseVolume"])

    def test_keeps_the_action_of_a_binding(self):
        bindings = dot.parse_key_bindings(NIRI_CONFIG)
        self.assertEqual(bindings[1].action, 'spawn "kitty"')

    def test_skips_a_binding_that_does_not_close_on_its_line(self):
        broken = "binds {\n    Mod+T { spawn \"kitty\"\n}\n"
        self.assertEqual(dot.parse_key_bindings(broken), [])

    def test_describes_a_spawn_binding_in_arabic(self):
        self.assertIn("kitty", dot.describe_action('spawn "kitty"', lang="ar"))

    def test_describes_a_spawn_binding_in_english(self):
        self.assertIn("kitty", dot.describe_action('spawn "kitty"', lang="en"))

    def test_describes_a_niri_action(self):
        arabic = dot.describe_action("toggle-overview", lang="ar")
        english = dot.describe_action("toggle-overview", lang="en")
        self.assertNotEqual(arabic, english)
        self.assertIn("toggle", english.lower())
        self.assertIn("عرض", arabic)

    def test_render_key_bindings_lists_every_binding(self):
        text = dot.render_key_bindings(dot.parse_key_bindings(NIRI_CONFIG))
        for keys in ("Mod+Shift+Slash", "Mod+T", "Mod+O"):
            self.assertIn(keys, text)

    def test_keys_falls_back_to_text_without_zenity(self):
        with TempTree() as t:
            home = t.path / "home"
            (home / ".config" / "niri").mkdir(parents=True)
            (home / ".config" / "niri" / "config.kdl").write_text(NIRI_CONFIG)
            text = dot.keys_window_text(home=str(home))
            self.assertIn("Mod+T", text)

    def test_open_keys_window_returns_false_without_a_window_tool(self):
        original = shutil.which
        shutil.which = lambda name, **kwargs: None
        self.addCleanup(setattr, shutil, "which", original)
        self.assertFalse(dot.open_keys_window("hello"))
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -m unittest discover -s tests -p test_dot.py -k Key -v`
Expected: FAIL — `AttributeError: module 'dot' has no attribute 'parse_key_bindings'`.

- [ ] **Step 3: Implement the cheat sheet in `.local/bin/dot`**

```python
BIND_RE = re.compile(
    r"^\s*(?P<keys>[A-Za-z0-9_+.\-]+)"
    r"(?P<flags>(?:\s+[a-z][a-z-]*(?:=[^\s]+)?)*)"
    r"\s*\{\s*(?P<action>.*?);?\s*\}\s*$"
)

ACTION_DESCRIPTIONS = {
    "toggle-overview": ("عرض كل النوافذ", "Toggle the overview"),
    "show-hotkey-overlay": ("طبقة الاختصارات", "Show the hotkey overlay"),
    "focus-window-left": ("التركيز على النافذة يساراً", "Focus the window to the left"),
    "focus-window-right": ("التركيز على النافذة يميناً", "Focus the window to the right"),
    "focus-window-up": ("التركيز على النافذة أعلى", "Focus the window above"),
    "focus-window-down": ("التركيز على النافذة أسفل", "Focus the window below"),
    "focus-column-left": ("التركيز على العمود يساراً", "Focus the column to the left"),
    "focus-column-right": ("التركيز على العمود يميناً", "Focus the column to the right"),
    "focus-monitor-left": ("التركيز على الشاشة يساراً", "Focus the monitor to the left"),
    "focus-monitor-right": ("التركيز على الشاشة يميناً", "Focus the monitor to the right"),
    "focus-monitor-up": ("التركيز على الشاشة أعلى", "Focus the monitor above"),
    "focus-monitor-down": ("التركيز على الشاشة أسفل", "Focus the monitor below"),
    "focus-workspace-up": ("التركيز على مساحة العمل أعلى", "Focus the workspace above"),
    "focus-workspace-down": ("التركيز على مساحة العمل أسفل", "Focus the workspace below"),
    "move-window-left": ("تحريك النافذة يساراً", "Move the window to the left"),
    "move-window-right": ("تحريك النافذة يميناً", "Move the window to the right"),
    "move-window-up": ("تحريك النافذة أعلى", "Move the window above"),
    "move-window-down": ("تحريك النافذة أسفل", "Move the window below"),
    "move-column-left": ("تحريك العمود يساراً", "Move the column to the left"),
    "move-column-right": ("تحريك العمود يميناً", "Move the column to the right"),
    "move-column-up": ("تحريك العمود أعلى", "Move the column above"),
    "move-column-down": ("تحريك العمود أسفل", "Move the column below"),
    "move-workspace-up": ("تحريك مساحة العمل أعلى", "Move the workspace up"),
    "move-workspace-down": ("تحريك مساحة العمل أسفل", "Move the workspace down"),
    "toggle-window-floating": ("تبديل النافذة إلى عائمة", "Toggle the window floating"),
    "toggle-keyboard-shortcuts-inhibit": ("تجميد اختصارات لوحة المفاتيح", "Toggle the keyboard shortcut inhibit"),
    "switch-focus-between-floating-and-tiling": ("التبديل بين العائمة والمربّعة", "Switch between floating and tiling"),
    "switch-preset-window-height": ("تبديل ارتفاع النافذة", "Cycle the preset window height"),
    "switch-preset-column-width": ("تبديل عرض العمود", "Cycle the preset column width"),
    "switch-preset-column-width-back": ("تبديل عرض العمود بالعكس", "Cycle the preset column width backwards"),
    "toggle-column-tabbed-display": ("تبديل عرض العمود كتبويب", "Toggle the tabbed column display"),
    "close-window": ("إغلاق النافذة", "Close the window"),
    "quit": ("الخروج من niri", "Quit niri"),
    "screenshot": ("لقطة شاشة", "Take a screenshot"),
}


@dataclasses.dataclass(frozen=True)
class KeyBinding:
    """One key combination and what it does."""

    keys: str
    action: str
    description: str


def describe_action(action: str, *, lang: str = "ar") -> str:
    """A human description of a niri action, in Arabic or English."""
    text = action.strip()
    described = ACTION_DESCRIPTIONS.get(text)
    if described is not None:
        return described[0] if lang == "ar" else described[1]
    spawn = re.match(r'^spawn(?:-sh)?\s+"([^"]+)"', text)
    if spawn is not None:
        command = spawn.group(1)
        return f"تشغيل {command}" if lang == "ar" else f"Run {command}"
    return text


def parse_key_bindings(text: str) -> list[KeyBinding]:
    """The binds of a niri config, in file order.

    Every bind of this config is on one line. A bind whose braces do not
    close on the same line is skipped rather than guessed at.
    """
    bindings: list[KeyBinding] = []
    inside = False
    depth = 0
    for line in text.splitlines():
        stripped = line.strip()
        if not inside:
            if stripped == "binds {":
                inside = True
            continue
        if stripped == "}":
            break
        match = BIND_RE.match(line)
        if match is None:
            continue
        action = match.group("action").strip()
        bindings.append(KeyBinding(
            keys=match.group("keys"),
            action=action,
            description=describe_action(action, lang="ar"),
        ))
    return bindings


def render_key_bindings(bindings: list[KeyBinding], *, lang: str = "ar") -> str:
    """The cheat sheet table."""
    width = max((len(binding.keys) for binding in bindings), default=4)
    lines = []
    for binding in bindings:
        description = describe_action(binding.action, lang=lang)
        lines.append(f"  {binding.keys:<{width}}   {description}")
    return "\n".join(lines)


def key_bindings(*, home: str | None = None) -> list[KeyBinding]:
    """The live niri bindings."""
    base = home if home is not None else str(Path.home())
    path = os.path.join(base, NIRI_CONFIG_REL)
    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            text = handle.read()
    except OSError:
        return []
    return parse_key_bindings(text)


def keys_window_text(*, home: str | None = None, lang: str = "ar") -> str:
    """The cheat sheet, ready for a window."""
    bindings = key_bindings(home=home)
    header = "اختصارات niri" if lang == "ar" else "niri shortcuts"
    return f"{header}\n\n" + render_key_bindings(bindings, lang=lang)


def open_keys_window(text: str) -> bool:
    """Show the cheat sheet in a window; returns whether a window was opened."""
    if shutil.which("zenity"):
        subprocess.run(["zenity", "--text-info", "--title=dot keys",
                        "--width=760", "--height=640"], input=text, text=True, check=False)
        return True
    if shutil.which("yad"):
        subprocess.run(["yad", "--text", "--title=dot keys", "--width=760", "--height=640"],
                       input=text, text=True, check=False)
        return True
    return False
```

Register the subcommand and handle it before `build_inventory()`:

```python
    p_keys = sub.add_parser("keys", help="the niri shortcut cheat sheet")
    p_keys.add_argument("--lang", default="ar", choices=["ar", "en"], help="the language of the table")
    p_keys.add_argument("--gui", action="store_true", help="open it in a window")
```

```python
    if args.command == "keys":
        bindings = key_bindings()
        if args.gui:
            text = keys_window_text(lang=args.lang)
            if not open_keys_window(text):
                print(text)
            return 0
        print(render_key_bindings(bindings, lang=args.lang))
        return 0
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `python3 -m unittest discover -s tests -p test_dot.py -v`
Expected: OK — the whole suite passes.

- [ ] **Step 5: Add the niri binding**

In `.config/niri/config.kdl`, inside the `binds {` block, add one line after the
`Mod+Shift+Slash { show-hotkey-overlay; }` line:

```
    Super+Shift+Slash { spawn "/home/zeyad/.local/bin/dot" "keys" "--gui"; }
```

`Mod+Shift+Slash` is niri's own hotkey overlay and is left alone. The absolute path
matches the style already used in this file (for example `/home/zeyad/.local/bin/set-wallpaper`).

- [ ] **Step 6: Publish the niri config**

Run: `home-manager switch --flake ~/dotfiles#zeyad`
Expected: the switch succeeds and `~/.config/niri/config.kdl` still resolves to the repository file.

Run: `~/.local/bin/dot keys | head -20`
Expected: the table, in Arabic, with the real bindings of this machine.

- [ ] **Step 7: Commit**

```bash
git add .local/bin/dot tests/test_dot.py .config/niri/config.kdl
git commit -m "feat(dot): add the niri shortcut cheat sheet"
```

---

### Task 6: the bar — waybar modules, the health dot, the Hijri clock

**Files:**
- Create: `.config/waybar/scripts/dot-health.sh`
- Create: `.config/waybar/scripts/hijri-clock.sh`
- Modify: `.config/waybar/config-niri`
- Modify: `.config/waybar/style.css`
- Modify: `.local/bin/hijri-date.py`
- Modify: `nix/modules/dotfiles.nix`
- Test: `tests/test_dot.py` (new class `BarTests`)

**Interfaces:**
- Consumes: `dot health --json` (Task 1), the Hijri script, `home.file.mkOutOfStoreSymlink`.
- Produces: the two shell scripts, the waybar modules `custom/dot-health`, `custom/hijri`, `cpu`, `memory`, `battery`, and the two new Home Manager links.

- [ ] **Step 1: Write the failing tests**

```python
class BarTests(unittest.TestCase):
    """The bar must never show an empty widget, even when a helper fails."""

    def _script(self, t, name, body):
        path = t.path / name
        path.write_text(body)
        path.chmod(0o755)
        return path

    def test_health_script_is_valid_shell(self):
        path = Path(REPO / ".config" / "waybar" / "scripts" / "dot-health.sh")
        self.assertTrue(path.exists())
        result = subprocess.run(["sh", "-n", str(path)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_hijri_script_is_valid_shell(self):
        path = Path(REPO / ".config" / "waybar" / "scripts" / "hijri-clock.sh")
        self.assertTrue(path.exists())
        result = subprocess.run(["sh", "-n", str(path)], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_health_script_prints_valid_json_even_when_dot_fails(self):
        with TempTree() as t:
            home = t.path / "home"
            (home / ".local" / "bin").mkdir(parents=True)
            broken = home / ".local" / "bin" / "dot"
            broken.write_text("#!/bin/sh\nexit 1\n")
            broken.chmod(0o755)
            script = self._script(t, "dot-health.sh", REPO.joinpath(
                ".config", "waybar", "scripts", "dot-health.sh").read_text())
            env = dict(os.environ, HOME=str(home))
            result = subprocess.run(["sh", str(script)], capture_output=True, text=True, env=env)
            data = json.loads(result.stdout)
            self.assertIn("text", data)
            self.assertIn("tooltip", data)
            self.assertIn("class", data)

    def test_hijri_script_falls_back_to_the_gregorian_date(self):
        with TempTree() as t:
            home = t.path / "home"
            (home / ".local" / "bin").mkdir(parents=True)
            broken = home / ".local" / "bin" / "hijri-date.py"
            broken.write_text("#!/bin/sh\nexit 1\n")
            broken.chmod(0o755)
            script = self._script(t, "hijri-clock.sh", REPO.joinpath(
                ".config", "waybar", "scripts", "hijri-clock.sh").read_text())
            env = dict(os.environ, HOME=str(home))
            result = subprocess.run(["sh", str(script)], capture_output=True, text=True, env=env)
            self.assertRegex(result.stdout.strip(), r"\d{4}-\d{2}-\d{2}")

    def test_hijri_date_script_formats_arabic(self):
        module = self._load_hijri()
        self.assertEqual(module.format_hijri(11, "جمادى الأولى", 1448, lang="ar"),
                         "١١ جمادى الأولى ١٤٤٨ هـ")
        self.assertEqual(module.format_hijri(11, "Jumada al-Ula", 1448, lang="en"),
                         "11 Jumada al-Ula 1448 AH")

    def test_waybar_config_declares_the_new_modules(self):
        config = (REPO / ".config" / "waybar" / "config-niri").read_text()
        for module in ("custom/dot-health", "custom/hijri", "cpu", "memory", "battery"):
            self.assertIn(f'"{module}"', config)

    def test_home_manager_links_the_bar_scripts(self):
        text = (REPO / "nix" / "modules" / "dotfiles.nix").read_text()
        self.assertIn(".config/waybar/scripts/dot-health.sh", text)
        self.assertIn(".config/waybar/scripts/hijri-clock.sh", text)
```

The `_load_hijri` helper loads the standalone script the same way the suite loads `dot`:

```python
    def _load_hijri(self):
        path = REPO / ".local" / "bin" / "hijri-date.py"
        spec = importlib.util.spec_from_loader(
            "hijri_date", importlib.machinery.SourceFileLoader("hijri_date", str(path)))
        module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(module)
        return module
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `python3 -m unittest discover -s tests -p test_dot.py -k Bar -v`
Expected: FAIL — the scripts do not exist yet.

- [ ] **Step 3: Write the two scripts**

`.config/waybar/scripts/dot-health.sh`:

```sh
#!/bin/sh
# The health dot of the bar.
#
# `dot health --json` prints exactly the three keys a waybar json custom
# module reads. When dot is missing or fails, the module still gets valid
# json, so the bar never renders an empty widget.
set -u

dot="$HOME/.local/bin/dot"
if [ -x "$dot" ]; then
    out=$("$dot" health --json 2>/dev/null) && [ -n "$out" ] && {
        printf '%s\n' "$out"
        exit 0
    }
fi
printf '%s\n' '{"text":"○","tooltip":"dot is not available","class":"bad"}'
```

`.config/waybar/scripts/hijri-clock.sh`:

```sh
#!/bin/sh
# The Hijri date next to the clock, in Arabic.
#
# The date comes from the hijri script, which needs uv and a python package.
# When either is missing the module falls back to the Gregorian date, so it
# is never empty.
set -u

script="$HOME/.local/bin/hijri-date.py"
if [ -x "$script" ]; then
    out=$("$script" 2>/dev/null) && [ -n "$out" ] && {
        printf '%s\n' "$out"
        exit 0
    }
fi
date +%F
```

Make both executable: `chmod 755 .config/waybar/scripts/*.sh`

- [ ] **Step 4: Give `hijri-date.py` an Arabic form**

Rewrite `.local/bin/hijri-date.py` so the dependency is imported inside `main` (so the
module can be imported by the tests without it) and the formatting is a pure function:

```python
#!/usr/bin/env -S uv run --quiet --script
# /// script
# dependencies = ["hijri-converter"]
# ///

"""The Hijri date, in Arabic by default."""

ARABIC_DIGITS = str.maketrans("0123456789", "٠١٢٣٤٥٦٧٨٩")


def format_hijri(day: int, month_name: str, year: int, *, lang: str = "ar") -> str:
    """The Hijri date as one line, in Arabic or English."""
    if lang == "ar":
        text = f"{day} {month_name} {year} هـ"
        return text.translate(ARABIC_DIGITS)
    return f"{day} {month_name} {year} AH"


def main(argv: list[str] | None = None) -> int:
    import argparse

    from hijri_converter import Gregorian

    parser = argparse.ArgumentParser(description="the Hijri date")
    parser.add_argument("--english", action="store_true", help="print the English form")
    args = parser.parse_args(argv)

    hijri = Gregorian.today().to_hijri()
    lang = "en" if args.english else "ar"
    print(format_hijri(hijri.day, hijri.month_name(lang), hijri.year, lang=lang))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
```

Note: the Arabic form is **not** reversed. Arabic is written right to left and the
terminal shapes it; reversing the string would break it.

- [ ] **Step 5: Add the modules to the waybar config**

In `.config/waybar/config-niri`:

- `"modules-left"` becomes `["custom/launcher", "niri/workspaces", "niri/window"]` (unchanged).
- `"modules-center"` becomes `["clock", "custom/hijri"]`.
- `"modules-right"` becomes `["niri/language", "network", "pulseaudio", "backlight", "custom/dot-health", "cpu", "memory", "battery", "tray", "custom/power"]`.

Add these module blocks before the closing brace of the file:

```json
  "custom/dot-health": {
    "interval": 10,
    "return-type": "json",
    "exec": "$HOME/.config/waybar/scripts/dot-health.sh",
    "tooltip": true
  },

  "custom/hijri": {
    "interval": 60,
    "exec": "$HOME/.config/waybar/scripts/hijri-clock.sh",
    "tooltip": false
  },

  "cpu": {
    "interval": 5,
    "format": "󰻠 {usage}%",
    "tooltip": true
  },

  "memory": {
    "interval": 10,
    "format": "󰍛 {percentage}%",
    "tooltip": true
  },

  "battery": {
    "format": "{icon} {percentage}%",
    "format-icons": ["", "", "", ""]
  },
```

The glyphs are Nerd Font codepoints that exist in the installed
`JetBrainsMono Nerd Font`: `U+F2DB` for the cpu chip, `U+F0FC` for the memory bars,
`U+F240`–`U+F243` for the battery levels. Write them as the escape sequences
`"\uF2DB"`, `"\uF0FC"`, `"\uF240"`, `"\uF241"`, `"\uF242"`, `"\uF243"` in the config —
the file is parsed as json and an escape survives copying better than a raw glyph.
If a glyph still renders as a box on the owner's screen, replace it with a plain
label such as `"cpu {usage}%"`.

- [ ] **Step 6: Style the new modules**

Append to `.config/waybar/style.css`:

```css
#custom-dot-health {
  color: #a6e3a1;
  font-size: 14px;
  padding: 0 8px;
}

#custom-dot-health.bad {
  color: #f7768e;
}

#custom-hijri {
  color: #f9e2af;
  font-size: 12px;
  padding: 0 8px;
}

#cpu,
#memory {
  color: #94e2d5;
  font-size: 12px;
  padding: 0 8px;
}
```

- [ ] **Step 7: Link the scripts through Home Manager**

In `nix/modules/dotfiles.nix`, inside the `home.file` block, next to the other waybar
entries, add:

```nix
    ".config/waybar/scripts/dot-health.sh" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/waybar/scripts/dot-health.sh";
    };
    ".config/waybar/scripts/hijri-clock.sh" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/waybar/scripts/hijri-clock.sh";
    };
```

- [ ] **Step 8: Run the tests to verify they pass**

Run: `python3 -m unittest discover -s tests -p test_dot.py -v`
Expected: OK — the whole suite passes.

- [ ] **Step 9: Publish and look at the bar**

Run: `home-manager switch --flake ~/dotfiles#zeyad`
Expected: the switch succeeds.

Run: `sh ~/.config/waybar/scripts/dot-health.sh`
Expected: a single JSON line with `text`, `tooltip` and `class`.

Run: `sh ~/.config/waybar/scripts/hijri-clock.sh`
Expected: the Arabic Hijri date, for example `١١ جمادى الأولى ١٤٤٨ هـ`.

Run: `pkill waybar; sleep 1; waybar -c ~/.config/waybar/config-niri &`
Expected: the bar comes back with the new modules. The battery module stays hidden
because this machine exposes no battery.

- [ ] **Step 10: Commit**

```bash
git add .config/waybar/config-niri .config/waybar/style.css .config/waybar/scripts/dot-health.sh .config/waybar/scripts/hijri-clock.sh .local/bin/hijri-date.py nix/modules/dotfiles.nix tests/test_dot.py
git commit -m "feat(bar): add the health dot, the stats and the Hijri clock"
```

---

### Task 7: the documentation and the final verification

**Files:**
- Modify: `README.md`
- Modify: `docs/superpowers/specs/2026-10-22-dot-cli-phase2-design.md`
- Test: `tests/test_dot.py` (no new tests, only the suite must stay green)

**Interfaces:**
- Consumes: everything the previous tasks produced.
- Produces: the README section and the spec status.

- [ ] **Step 1: Write the README section**

Add a section to `README.md` right after the existing `## The dot CLI` section, called
`### The Phase 2 commands`. It must document, each with one command line and one sentence
of what it does:

- `dot health` — the fast health check; `dot health --json` is the waybar document.
- `dot pkg list`, `dot pkg add`, `dot pkg rm`, `dot pkg sync` — the nix profile, edited in
  `nix/modules/packages.nix` and applied with `home-manager switch`. State plainly that
  `dot pkg` is the only command that changes anything, and that it never uses `sudo`.
- `dot browse` — the fzf launcher over the apps, the tools, the scripts and the configs.
- `dot keys` — the niri cheat sheet, Arabic by default, `--lang en` for English,
  `--gui` for the window.
- `dot show <id>` — the details of one item, used by the browser preview.

Also state the exit-code contract: `dot status` and `dot health` return 1 when something
is wrong.

- [ ] **Step 2: Update the spec status**

In `docs/superpowers/specs/2026-10-22-dot-cli-phase2-design.md`, change the status line to:

```
**Status:** Implemented on 2026-10-22 — see
[`../plans/2026-10-22-dot-cli-phase2.md`](../plans/2026-10-22-dot-cli-phase2.md).
```

- [ ] **Step 3: Run the whole suite**

Run: `python3 -m unittest discover -s tests -p test_dot.py -v`
Expected: OK — every test passes, with the Phase 1 tests and the Phase 2 tests together.

- [ ] **Step 4: Smoke test every command on the live machine**

```bash
~/.local/bin/dot list
~/.local/bin/dot status
~/.local/bin/dot health
~/.local/bin/dot health --json
~/.local/bin/dot pkg list
~/.local/bin/dot pkg add fd --dry-run
~/.local/bin/dot keys | head -30
~/.local/bin/dot browse
```

Expected: every command answers; `dot status` reports the machine's real state;
`dot pkg add fd --dry-run` prints a diff and changes nothing; `git status` still shows
only the user's two modified files.

- [ ] **Step 5: Check the working tree is clean of anything unintended**

Run: `git status --short`
Expected: at most the two files the user modified themselves
(`.config/Thunar/accels.scm`, `nix/modules/packages.nix`).

- [ ] **Step 6: Commit**

```bash
git add README.md docs/superpowers/specs/2026-10-22-dot-cli-phase2-design.md
git commit -m "docs: describe the Phase 2 commands"
```
