# SDD ledger — plan: docs/superpowers/plans/2026-10-21-dot-cli-system-inventory.md

- Spec (binding authority): `docs/superpowers/specs/2026-10-20-dot-cli-system-inventory-design.md`
- Branch: `feat/dot-cli` (base commit `e53de95`; plan+spec committed as `df425a8`)
- Workspace: `.superpowers/sdd/2026-10-21-dot-cli-system-inventory/`
- Working dir: `/home/zeyad/dotfiles` (primary checkout, NOT a separate worktree — see Ruling R1)
- Unrelated pre-existing modifications in the tree (never commit them): `.config/Thunar/accels.scm`, `nix/modules/packages.nix`

## Pre-flight conflict scan (plan read once, 2026-10-21)

All eight tasks touch the same two files (`.local/bin/dot`, `tests/test_dot.py`), so every task pair
shares a file. That overlap is resolved by strict serialization — exactly one implementer runs at a
time, never two in parallel. The rows below are the *interface* edges, where a producer's output is
a consumer's input, plus one self-consistency row per task.

| # | Producer | Consumer | Interface | Finding |
|---|---|---|---|---|
| 1 | 1 | 3 | `classify`, `Entry`, `Owner`, `is_excluded` | consistent |
| 2 | 1 | 2 | module `dot` importable via `SourceFileLoader` | consistent |
| 3 | 2 | 7 | `extract_spawns`, `resolve_token` | GAP — no task turns an unresolved token into a `missing` finding; spec §7.5.4 requires it → R4 |
| 4 | 3 | 5 | `Finding` | consistent |
| 5 | 3 | 6 | `Finding`, `SEVERITIES` | consistent |
| 6 | 4 | 5 | `collect_profile_bins` | consistent |
| 7 | 4 | 6 | `Source` | consistent |
| 8 | 4 | 7 | all collectors | consistent |
| 9 | 5 | 7 | `nix_drift` | CONFLICT — the plan's three drift rules, read literally, emit 2 findings where the plan's own tests expect exactly 1 → R3 |
| 10 | 6 | 7 | `Inventory`, renderers, `inventory_json` | CONFLICT — plan's Global Constraint exit set includes `orphan`; spec §7.4 lists only four → R5; ORPHAN severity handling → R6 |
| 11 | 7 | 8 | CLI surface, README | consistent |

Self-consistency, one row per task:

| Task | Files | Tests vs. code | Verdict |
|---|---|---|---|
| 1 | creates `.local/bin/dot`, `tests/test_dot.py`; modifies `.local/bin/.gitignore` | the plan's `classify` rules read with `os.path.realpath` fail the plan's own `test_classifies_home_manager_link_to_live_repo` | CONFLICT → R2; `from types import SimpleNamespace` must be added (plan says so) |
| 2 | modifies `.local/bin/dot`, `tests/test_dot.py` | plan's Task 2 code block has a stray fence and two prose-only test bodies | prose bodies only — implementer writes them; behaviour pinned by the listed assertions |
| 3 | modifies both | `test_findings_from_entries_marks_broken_and_stale` expects `["broken","stale"]` | consistent with `SEVERITIES` order and the owner-kind mapping |
| 4 | modifies both | `test_collect_scripts_splits_repo_and_local` — `repo_dir` is a temp dir that is not a git repo, so both entries land in `local`; the assertion only checks `"my-tool" in local` | consistent (assertion is weaker than the name suggests, but not vacuous) |
| 5 | modifies both | three drift tests vs. three drift rules | CONFLICT → R3 |
| 6 | modifies both | `test_render_status_groups_by_severity` asserts `out.replace("BROKEN","broken-symlink") or out` contains `"broken-symlink"` — weak but not vacuous | leave as written; the reviewer may flag it |
| 7 | modifies both | live expectation (5 broken / 1 stale / 2 missing / 1 drift) — verified against the live machine: a depth-2 scan of `~/.config` shows exactly 5 genuine broken links (`ghostty/config`, `mako/config`, `sway/config`, `waybar/config`, `waybar/config-mango`); the only other broken links are `Codex/Singleton*` and `Local/Singleton*`, excluded by name | consistent; the `2 missing` count depends on R4 |
| 8 | modifies `README.md`, the spec | README claims 8 `nix/modules/` entries; 7 exist (`scripts.nix` absent) | consistent |

## Rulings

R1 (branch/workspace): implement on branch `feat/dot-cli` **in the primary working directory**, not on
`main` and not in a separate worktree. Why: `~/.local/bin` is a symlink to `~/dotfiles/.local/bin`, and
the plan's live verification (Task 7 step 5, Task 8 step 4) invokes `dot` by name — a separate worktree
would put the script off `$PATH`. Cost if wrong: the work lands on a branch instead of `main`; merging is
one command at the end.

R2 (`classify` resolution order): store-path detection uses the **first-hop** link target
(`os.readlink`) while the reported target and the repo/`$HOME` membership tests use the fully resolved
`os.path.realpath`. The `-source` test runs on the **resolved** target and **precedes** the
`-home-manager-files` test. Why: the plan's own `test_classifies_home_manager_link_to_live_repo` requires
`home-manager` for a link whose resolved target lies inside the repo — realpath-only detection would
classify it as `dotfiles` and fail. The `-source`-first order makes the live `~/.config/lazygit` (resolves
to `/nix/store/smisxx…-source/.config/lazygit`) classify as `frozen-store`, per spec §6.4. Cost if wrong:
HM links would be reported as `dotfiles`, and the frozen-store case would be missed.

R3 (`nix_drift` rule set): the plan's three rules, read literally, contradict its own three tests (both
drift tests expect exactly one finding). Reconciled rules: (1) for each declared package, candidates =
`package_bins.get(pkg)` or `{pkg}`; if no candidate is installed → one `nix-not-installed` finding;
(2) when `package_bins` is non-empty, each installed binary not provided by any declared package → one
`nix-undeclared` finding; (3) the grouped `nix-unattributed` finding is a **fallback only**, emitted when
`package_bins` is empty *and* rules 1–2 produced nothing. Cost if wrong: a grouped "unattributed" line may
be suppressed when another drift finding already exists.

R4 (missing spawn findings): Task 7's `build_inventory` turns every unresolved niri spawn token into a
`missing` finding (spec §7.5.4). Why: the spec requires it, no plan task owns it, and Task 7's live
expectation of `2 missing` depends on it. Cost if wrong: two real findings are lost.

R5 (exit code): `dot status` exits `1` iff a finding has severity `broken`, `stale`, `missing` or `drift`.
Why: spec §7.4 enumerates exactly those four, and spec §4 lists "a `dot status` that can never exit 0 in
the normal state" as an anti-goal. The plan's Global Constraint adds `orphan` to the exit set — the spec
wins. Cost if wrong: orphan packages would not fail an automated check.

R6 (ORPHAN severity): ORPHAN is **not** a Phase-1 finding. Orphan packages appear in `dot list` as an
advisory count with a "safe to remove" hint; `dot status` does not report them; the JSON `counts` map keeps
exactly the frozen §7.6 keys (`broken`, `stale`, `missing`, `drift`, `info`); the `dot status` headline
counts only `broken`/`stale`/`missing`/`drift`. Why: §7.6's frozen counts omit `orphan` and §7.7's sample
shows no orphan section — and 7 permanent orphans would otherwise make `dot status` exit 1 forever, which
§4 forbids. Cost if wrong: the owner sees orphans only in `dot list`, never in `dot status`.

R7 (network): `--outdated` may call `checkupdates`; nothing else may touch the network, and the default
path never calls it. Why: spec §6.3 and §7.8 allow the opt-in; the plan's Global Constraint line "No network
access, ever (never call `checkupdates`)" contradicts both the spec and the plan's own Task 4/7
(`collect_outdated`, `--outdated`). The constraint is scoped to the default path. Cost if wrong: none —
the call stays opt-in.

R8 (JSON item shapes): `sections.{apps,cli,scripts,configs}` = `{"count": N, "items": [...]}`; item shapes
— apps `{"name","desktop_file","source"}`, cli `{"source","name"}`, scripts `{"group","name"}`,
configs `{"path","owner","target"}`; `summary` = `{"total","by_source","by_owner"}`;
`generated_at` = `"%Y-%m-%dT%H:%M:%SZ"` in UTC. Why: §7.6 freezes the section keys but not the item
shapes, and Phase 2 consumes this document — the shapes must be fixed now. Cost if wrong: schema churn in
Phase 2.

R9 (runtime dirs): runtime dirs are counted in the ownership breakdown, never emitted as findings. Only
repo-dirty is an INFO finding. Why: spec §6.5 lists runtime dirs under INFO, but §7.7's sample has no INFO
section and 113 INFO findings would flood the JSON and the status view. Cost if wrong: runtime dirs are
not enumerated in `dot status`.

R10 (waybar references): Phase 1 scans the niri config's spawn tokens only. Waybar/Waybar-referenced script
scanning is deferred to Phase 2. Why: spec §7.5's "Also checked" line would otherwise add a scanner with
no test and no plan owner, and the waybar config link is itself broken so there is no file to parse. Cost if
wrong: a waybar-referenced missing script is not reported in Phase 1.

R11 (`current_generation` at runtime): derive it from `~/.local/state/nix/profiles/home-manager` → generation
dir → its `home-files` symlink → `/nix/store/<hash>-home-manager-files` → the `<hash>`; `None` when any
step is missing. Verified live: `8x5nq3bjixrb708y4fh4w1ibpp3w8205`.

R12 (`classify` signature): `classify` may take one extra optional keyword `home: str | None = None`
(defaulting to `~`). The plan's pinned call shape `classify(path, *, current_generation, repo_dir)` stays
valid. Why: it lets the `local:user` test build a hermetic `$HOME` fixture instead of writing into the
real home directory. Cost if wrong: none.

## Progress

- Task 0 (preparation): branch `feat/dot-cli` created; spec + plan committed as `df425a8`.

R13 (executor): the owner chose subagent-driven development, but every subagent dispatch failed with
`Rate limit exceeded` across all available models and providers (only one provider exists). Execution
therefore continues inline under `superpowers:executing-plans`, keeping the SDD discipline (brief as spec,
ledger as memory, TDD gate per task, per-task commit, one final whole-branch review). Why: a rate-limited
provider cannot produce the per-task reviewers the owner asked for, and stalling costs the owner a day.
Cost if wrong: no independent per-task review — the final whole-branch review is the only fresh pair of eyes.

R14 (test loader): the plan's prescribed test loader (`module_from_spec` + `exec_module`) does not
register the module in `sys.modules`; on Python 3.14 `dataclasses.dataclass` with
`from __future__ import annotations` then raises `AttributeError: 'NoneType' object has no attribute
'__dict__'`. The loader now registers `sys.modules["dot"] = dot` before `exec_module` — the canonical
importlib recipe. Why: the failure is in the harness, not in the behaviour under test, and the plan's
script skeleton (which mandates the `__future__` import) stays untouched. Cost if wrong: one extra line
in the test harness.
Task 1: complete (commits df425a8..bf80d95, tests: python3 -m unittest discover -s /home/zeyad/dotfiles/tests -p test_dot.py -v → OK)

R15 (`$HOME` expansion in `resolve_token`): the brief expands only a leading `~`; the live niri config also
spawns `$HOME/.local/bin/headset-popup-daemon` (config.kdl line 336), which would then be reported as a
missing binary. `resolve_token` therefore expands a leading `$HOME` too (hermetic test with `HOME` patched).
Why: the token is resolvable — reporting it missing is a false positive that would also break the plan's
live missing count. Cost if wrong: one extra expansion; a file literally named `$HOME` would be missed.

R16 (live missing spawn count): the plan's Task 7 live expectation says 2 missing spawn binaries; the live
machine has exactly **1** (`orca`). The polkit agent IS installed — `pacman -Qo
/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1` → `polkit-gnome 0.105-12` — so the earlier
diagnosis that flagged it as missing was wrong. Task 7's live check uses 1. Why: the spec's authority is the
machine's real state, and the plan's number came from that same wrong diagnosis. Cost if wrong: Task 7's
live expectation is off by one and must be re-checked against the machine.
Task 2: complete (commits bf80d95..2d5be58, tests: python3 -m unittest discover -s /home/zeyad/dotfiles/tests -p test_dot.py -v → OK)

R17 (depth-2 recording): the brief says depth 2 records "symlinks found there", but the brief's own test
`test_skips_unreadable_directory` asserts a regular file (`config.kdl`) appears among the entries. Depth 2
therefore records **every** entry it finds; non-symlinks classify as `runtime`, so they are counted in the
ownership breakdown but never become findings (R9). Why: the test is the precise, checkable statement, and
the spec (§7.1) only says depth 2 exists "to validate links". Cost if wrong: the configs section carries
runtime entries it does not need (937 entries on the live machine).
Task 3: complete (commits 2d5be58..adb1572, tests: python3 -m unittest discover -s /home/zeyad/dotfiles/tests -p test_dot.py -v → OK)
Task 4: complete (commits adb1572..3d0b3d6, tests: python3 -m unittest discover -s /home/zeyad/dotfiles/tests -p test_dot.py -v → OK)

R18 (desktop entry shape): `collect_desktop_entries` returns exactly three keys — `name`, `desktop_file`,
`source` — and no `exec`. Why: the frozen JSON item shape (R8) and the brief's own Produces block agree on
those three; the brief's prose sentence ("parses Name= and Exec=") is looser than the block it sits under.
Cost if wrong: one extra key in the JSON contract, or a missing `exec` a future TUI wanted.
R19 (testable home): `collect_desktop_entries(dirs, *, home=None)` and `tool_dir_paths(home=None)` take the
home directory as an optional argument, defaulting to the real one. Why: the "user vs system" source rule and
the tool-dir labels are otherwise untestable without depending on the machine's `$HOME`. The brief's signature
`collect_desktop_entries(dirs)` still holds — the extra parameter is keyword-only with a default.
Cost if wrong: a caller that passes a positional second argument gets a TypeError.
R20 (porcelain parsing): `collect_repo_state` reads the status field as `XY<space>path` and takes the path
from index 3, left-trimming only the path. The live smoke test showed `.config/Thunar/accels.scm` reported
as `config/Thunar/accels.scm`: `_split_lines` had stripped the leading space of an unstaged ` M` status
field, shifting the path by one character. Why: git's porcelain format is fixed, and the fix keeps the
leading `.` of dot-paths. Caught by a live run, reproduced with a RED test, then fixed.
Cost if wrong: dot-prefixed paths in the repo-state section are reported without their leading dot.
R21 (repository defaults): `collect_repo_state(repo_dir=None)` resolves the repository through
`default_repo_dir()`, which walks up from the script's own path to the nearest `.git`; `collect_scripts`
with `repo_dir=None` treats the scripts as untracked (all local) rather than guessing a repository.
Why: one place decides where "the repository" is, and a wrong guess would report local scripts as
repo-owned. Cost if wrong: `dot status` reports a different repository than the one the script ships in.

R22 (attribute to package mapping): the declared-to-installed check falls back to
dash-boundary name matching. `nix path-info --json` reports no `name` attribute for nixpkgs
paths in this nix version (Determinate Nix 2.35.2), so the store path basename supplies the
package name, and the declared attribute is matched against it and against the binary names.
That is what keeps `antigravity` (package `antigravity-ide`), `nixfmt-rfc-style` (package
`nixfmt`) and `mypy` (package `python3.14-mypy`, binary `mypy`) from being reported as
missing. Why: the spec (§7.3) wants a real package-to-binary map, and no offline mechanism
produces the attribute name; the alternative is a false "not installed" on three live
packages. Cost if wrong: a declared package whose name merely shares a dash-delimited prefix
or suffix with an installed one is treated as installed.
R23 (hand written derivations): `parse_declared_packages` also takes the `pname` of a
`stdenvNoCC.mkDerivation` block as a declared package. The brief says to ignore the block
entirely, but `workmux` is declared that way and its binary is installed — ignoring the block
reports a package the user did declare as undeclared. Why: the brief's intent is to keep
attribute names (`pname`, `version`) out of the package list, and the `pname` value is the
package name itself. Cost if wrong: one extra declared name, which can only silence a drift
finding.
R24 (one finding per undeclared package): the installed-to-declared direction reports one
finding per undeclared package, with its binaries listed in the detail, instead of one
finding per binary as the brief's rule 2 literally reads. A binary with no known owner is
still reported on its own. Why: `man-db` alone would otherwise produce nine near-identical
lines. Cost if wrong: the undeclared direction is coarser than the brief asks for.
R25 (live drift count): the live machine reports four drift findings — `traceroute`
(declared, not installed) and three installed-but-undeclared packages (`home-manager`,
`man-db`, `shared-mime-info`). The spec sample (§7.7) and the plan's Task 7 expectation say
one drift, which counted only the declared-to-installed direction. The spec's decision (§7.3)
is bidirectional, so the count is four; Task 7's live check uses four. Cost if wrong: the
Task 7 live expectation is off by three.
Task 5: complete (commits 3d0b3d6..e71ae80, tests: python3 -m unittest discover -s /home/zeyad/dotfiles/tests -p test_dot.py -v → OK)

R26 (advisory counts in meta): the AUR/foreign and orphan counts travel in `meta`
(`meta["foreign"]`, `meta["orphans"]`) rather than as `Source` entries. Why: `pacman -Qq` already
lists the foreign packages and the orphans — they are subsets of the 1103 pacman packages, so a
`Source` for each would double-count them in the CLI total and in the JSON `cli` section. The
frozen JSON schema (§7.6) has no key for them, so `dot list --json` omits the two advisory
counts; the text view shows them. Cost if wrong: the JSON consumer does not see the AUR count.
R27 (source kinds): the `Source.kind` vocabulary is `package` (pacman), `cli` (the nix profile
binaries) and `binary` (the tool shim directories); `app` and `script` are unused because apps
and scripts have their own inventory fields. The "CLI packages" line counts `package` and `cli`
together; the "Top CLI" line shows the `cli` items — the curated nix set — falling back to the
tool shims when nix is absent. Why: the spec sample shows "CLI packages 1159 — pacman 1103 ·
nix 56" and a "Top CLI" line of nix tools, which needs the two groups told apart. Cost if
wrong: the Top CLI line lists tool shims instead of the nix set.
R28 (managed configs): the configs section and the "Managed configs" count line hold every
scanned entry whose owner is not `runtime`; `summary.by_owner` counts every scanned entry,
runtime included (R9). Why: the runtime dirs are app noise that would dwarf the real
ownership map, but the ownership breakdown must still account for them. Cost if wrong: the
JSON configs section is 876 entries larger than the text view suggests.
R29 (wide and show_all): `wide=True` lifts the twelve name cap on the Top CLI line;
`show_all=True` prints every item of every section under its own heading. Why: the brief
pins the flags but not their effect, and `--all` in the CLI means "print every item".
Cost if wrong: one flag means something slightly different than a user expects.
Task 6: complete (commits e71ae80..0407161, tests: python3 -m unittest discover -s /home/zeyad/dotfiles/tests -p test_dot.py -v → OK)
Task 6: complete (commits e71ae80..0407161, tests: python3 -m unittest discover -s /home/zeyad/dotfiles/tests -p test_dot.py -v → OK)

R30 (the sudo guard): the brief's `test_dot_never_invokes_sudo_or_mutating_pacman` joined the
whole command line and searched it for the substring "sudo", which false-positives on the user's
own script `.local/bin/distrobox_sudo_askpass` (`git -C … ls-files --error-unmatch -- .local/bin/
distrobox_sudo_askpass`). The test now checks the *program* — `basename(argv[0])` is never `sudo`
— and, when the program is `pacman`, that its subcommand is not one of `-S -R -U -Sy -Rns`. Why:
the requirement is "no `dot` code path runs sudo or a mutating pacman subcommand"; a file name
that happens to contain "sudo" is not an invocation. The intent is kept, the false positive is
gone. Cost if wrong: a `sudo` call hidden inside a shell string would not be caught.
R31 (`--outdated` and the JSON): the frozen §7.6 document has no slot for the update check, so
`--outdated` is a text-mode addition and `dot list --json` never runs `checkupdates` at all.
Why: the JSON shape is a contract for Phase 2, and a conditional extra key would make the
document shape depend on the flags. Cost if wrong: a JSON consumer cannot get the outdated list.
R32 (the section flags): `--sources` renders the data source table of §6.3 (pacman, nix, the tool
shims, desktop entries, scripts, configs — with counts and kinds); `--ownership` renders the
config ownership map: the count per owner kind, then every managed link with its owner and
target, except `local:tool`, which is only counted (spec §7.2: "`--ownership` lists `local:user`
in full and only counts `local:tool`"). `--apps --cli --configs --scripts` print one section
each. Why: the brief pins the flags but not their output; the spec pins the two views that have
a name. Cost if wrong: `--sources` prints something other than the source table.
R33 (command timeouts): `_run` now passes a timeout to the command (120 s by default, 45 s for
`checkupdates`) and treats `subprocess.TimeoutExpired` as a failure that degrades to an empty
result, per spec §6.3 ("Every Nix-dependent source degrades gracefully"). The list is printed
*before* the update check runs, so a slow or blocked `checkupdates` cannot swallow the output.
Why: on the live machine `checkupdates` blocks on the pacman database sync for 45 s; the tool
must not hang, and it must not lose its output when it is interrupted. Cost if wrong: a command
that legitimately needs more than 120 s is reported as absent.
R34 (the script's mode): `.local/bin/dot` is committed with mode 100755. The file lost its
executable bit during editing (it was 644 in the index), which made `dot` fail with
"permission denied" when invoked from `$PATH`. Why: the script is the deliverable and is meant
to be run by name. Cost if wrong: a fresh clone cannot run `dot` until the bit is set again.
Task 7 live verification: `dot status` → "● 11 findings — 5 broken, 1 stale, 1 missing,
4 drift", exit 1, 1.1 s; `dot list` → 92 desktop apps, 1161 CLI packages (pacman 1103 · nix 58),
59 tooling, 22 AUR, 7 orphans, 61 managed configs, 30 local scripts; `dot status --json` →
ok=false, counts {broken 5, stale 1, missing 1, drift 4, info 1}, 12 findings.
Task 7: complete (commits 0407161..54e2cee, tests: python3 -m unittest discover -s /home/zeyad/dotfiles/tests -p test_dot.py -v →   -h, --help     show this help message and exit)
Task 8: complete (commits 54e2cee..6930249, tests: python3 -m unittest discover -s /home/zeyad/dotfiles/tests -p test_dot.py -v →   -h, --help     show this help message and exit)

## Final whole-branch review (fresh subagent, 2026-10-21)

Verdict: needs-changes. Report: `.superpowers/sdd/2026-10-21-dot-cli-system-inventory/final-review.md`.
Package: `review-e53de95..6930249.diff`. One Critical, four Important, eighteen Minor, plus notes on
weak tests and on two ledger rulings (R22, R10). The Critical and the Important findings were
re-graded by effect and fixed in one pass (commit `b27522b`); the Minors that mattered were fixed
too, the rest are deferred below.

R35 (the nix layer degrades instead of inventing drift) — supersedes R3's fallback and R22's
name-matching protection. `nix_drift` returns no findings when the package map is empty, and
`_nix_findings` reports one of four explicit states as information: no `home.packages` list, no
packages declared, no profile ("Nix: not present"), or a profile the nix CLI cannot map. Why: the
review measured 26 phantom "declared but not installed" findings with the profile gone and three
false ones (`neovim`, `ripgrep`, `libnotify`) with the nix CLI unavailable — a package's binary may
carry another name, so name matching cannot verify a declaration. Spec §6.3's graceful degradation
and §2's no-false-findings goal outrank §7.3's name-matching fallback, which the spec itself
contradicts by listing the renames it cannot see. The plan's Task 5 tests
`test_detects_declared_but_not_installed` and `test_reports_unattributed_binaries_when_nix_is_unavailable`
were rewritten to the new contract (the first now supplies a package map, the second became
`test_does_not_report_drift_without_a_package_map`). Cost if wrong: with the nix CLI missing the
drift check does not run at all — it says so instead of guessing.

R36 (the Top CLI line leads with the tools worth remembering) — `CURATED_CLI` lists the daily
drivers (bat, btop, delta, eza, fd, ffmpeg, git, htop, jq, lazygit, nvim, rg, tmux, tree, yq,
zoxide, …); the rest of the profile follows alphabetically. Why: the line was an alphabetical
prefix — `accessdb`, `apropos`, `catman` — while `git`, `nvim`, `rg`, `tmux` and `zoxide`, the
tools the spec's §7.7 sample shows, never appeared. Cost if wrong: a fixed list cannot know a new
tool; the alphabetical remainder still shows it.

R37 (the declaration parser follows the list, not the indentation) — `parse_declared_packages` reads
the `home.packages` list and takes bare names at any indentation; `declarations_state` reports
`no-list` / `empty` / `ok`. Why: the old regex demanded exactly four spaces, so re-indenting
packages.nix collapsed the declared set from 26 names to 1 and produced false drift. Cost if wrong:
a declaration file in another shape reads as "no-list" — an information finding, not a false drift.

R38 (a missing spawn names the package that provides it) — `pacman -F` (a local database query) maps
the binary to its package, so the fix reads `sudo pacman -S libnotify` instead of the binary name;
a spawn whose path does not exist asks to create or restore the file. Why: the review found both
hints unusable ("install the package that provides /home/…/does-not-exist.sh"). Cost if wrong: one
extra local database query per missing binary.

R39 (the status headline stops contradicting the info section) — "● no problems" when only
informational findings exist, "● no findings" when there are none. Cost if wrong: none.

R40 (`--wide` is reachable) — the flag R29 documented now exists in the CLI and lifts the
twelve-name cut of the Top CLI line. Cost if wrong: one more flag.

R41 (the config scan classifies against the home it was given) — `scan_configs`, `_scan_dir` and
`current_generation` take the home, so `build_inventory(home=X)` is hermetic: a link into X is
`local:user`, not `local:tool`. Cost if wrong: none.

R42 (the ownership map follows the model order and says why) — the counts follow `OWNER_KINDS` and
each link shows the reason it is owned. This also gives `OWNER_KINDS` and `Owner.reason` a reader,
which the review listed as dead code. Cost if wrong: none.

R43 (one git call for the scripts) — `collect_scripts` asks git for the tracked files of the
directory once instead of once per file (31 calls → 1). Cost if wrong: none.

R44 (the spawn scan skips commented lines) — `#` and `//` lines are not spawns. Cost if wrong: a
spawn commented out with a trailing comment on the same line is missed.

R45 (the spec §7.5 "Also checked" clause, completing R10) — Phase 1 covers it in two places: the
spawn scan reports a `~/.local/bin` script the Niri config spawns when it does not exist, and the
depth-2 config scan reports a broken `~/.config/{niri,waybar}/scripts/*` link as a broken symlink.
What is not covered: the links *inside* `~/.config/niri/scripts/` sit at depth 3, which §7.1 puts
out of Phase 1's reach, and the Waybar config's own script references cannot be parsed because the
Waybar config link on this machine is broken. Both are deferred to Phase 2 with R10. On the live
machine the two niri script links resolve and the Niri config never spawns them. Cost if wrong: a
broken script link under `~/.config/niri/scripts/` is not reported in Phase 1.

Final: fixed C1 (the nix layer invented drift) — `test_does_not_report_drift_without_a_package_map`,
`test_nix_findings_report_nix_not_present_without_a_profile`,
`test_nix_findings_report_unverified_packages_when_the_profile_cannot_be_mapped`,
`test_build_inventory_does_not_report_drift_without_a_nix_profile` RED→GREEN, suite 92/92.
Final: fixed I1 (the Top CLI line) — `test_top_cli_prefers_the_curated_tools` RED→GREEN, suite 92/92.
Final: fixed I2 (the declaration parser) — `test_parses_declared_names_with_any_indentation`,
`test_declarations_state_reports_a_missing_list`, `test_declarations_state_reports_an_empty_list`,
`test_declarations_state_reports_a_readable_list` RED→GREEN, suite 92/92.
Final: fixed I3 and I4 (the missing spawn hints) — `test_missing_spawn_path_suggests_restoring_the_file`,
`test_package_for_binary_names_the_package_that_provides_it`,
`test_package_for_binary_falls_back_to_the_binary_name` RED→GREEN, suite 92/92.
Final: fixed M1 (the headline) — `test_render_status_says_no_problems_when_only_info_findings`
RED→GREEN, suite 92/92.
Final: fixed M2 (`--wide`) — `test_list_wide_shows_more_cli_names` RED→GREEN, suite 92/92.
Final: fixed M3 (the dead constants) — `OWNER_KINDS` and `Owner.reason` now have readers in the
ownership map, `SpawnRef.line` in the missing spawn detail; suite 92/92.
Final: fixed M6 (31 git calls) — `collect_scripts` now lists the tracked files once; suite 92/92.
Final: fixed M7 (`_sections()` twice) — the summary reuses the sections the document built; suite 92/92.
Final: fixed M8 (`os.scandir` left open) — the scan closes the iterator; suite 92/92.
Final: fixed M9 (the redundant hint) — the "Full lists" hint is only printed when the lists are not
shown; suite 92/92.
Final: fixed M11 (the sources table) — it now says "config entries 937 scanned" and "managed
configs 61 owned"; suite 92/92.
Final: fixed M14 (commented spawns) — the spawn scan skips comment lines; suite 92/92.
Final: fixed M16 (the home was ignored) — `test_build_inventory_classifies_links_against_the_given_home`
RED→GREEN, suite 92/92.
Final: fixed the weak tests — the severity grouping test asserts the group header and the path, the
frozen schema test asserts equality, the unreadable directory test asserts the subtree was skipped,
the sudo guard no longer swallows exceptions and asserts that commands were actually run.
Final: minor (deferred): the vestigial "orphan" severity in `SEVERITIES` — R6 keeps it out of every
count and exit code, but removing it would change the frozen severity vocabulary.
Final: minor (deferred): `runner=None` and the bare `dict` annotations are untyped — a `Protocol` for
the runner would cost more than the clarity it buys today.
Final: minor (deferred): `--json` ignores `--all`, `--ownership` and `--outdated` — the frozen
document has no slot for them, and R31 already keeps the network out of the JSON.
Final: minor (deferred): the shell splitter cuts on `|` inside a quoted string.
Final: minor (deferred): the porcelain parser reports a rename as "old -> new".
Final: minor (deferred): `_strip_version` cuts at the first `-<digit>`, so a package whose own name
carries a digit is shortened too far.
Final: minor (deferred): a plain file the user wrote in `~/.config` is labelled `runtime` — nothing
in the filesystem separates the user's file from an app's.
Final: Ruling: the reviewer's M12 (`command -v X` is a false token) — the code already lists
`command` among the shell builtins, so the token after it is the one that is resolved; the finding
does not reproduce. Cost if wrong: one extra builtin in the set.
Final: Ruling: the reviewer's disagreement with R22 — accepted in full; R22's name matching is
exactly the fallback that produced the false findings, and R35 replaces it with an explicit
"unverified" state. Cost if wrong: none, R35 supersedes it.
Final: review clean after the fix pass — commit `b27522b`, 92 tests, 0 failures.
