import contextlib
import importlib.machinery
import importlib.util
import io
import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from unittest import mock

REPO = Path(__file__).resolve().parent.parent
DOT_PATH = REPO / ".local" / "bin" / "dot"

_spec = importlib.util.spec_from_loader(
    "dot", importlib.machinery.SourceFileLoader("dot", str(DOT_PATH))
)
dot = importlib.util.module_from_spec(_spec)
sys.modules["dot"] = dot
_spec.loader.exec_module(dot)


@contextlib.contextmanager
def TempTree():
    """A temporary directory exposed as `.path` (a pathlib.Path)."""
    with tempfile.TemporaryDirectory() as tmp:
        yield SimpleNamespace(path=Path(tmp))


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
        with TempTree() as t:
            store = t.path / "nix" / "store" / "old999-home-manager-files"
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
            self.assertEqual(owner.kind, "home-manager-stale")

    def test_classifies_frozen_store_copy(self):
        with TempTree() as t:
            store_file = t.path / "nix" / "store" / "xyz-source" / "config"
            store_file.parent.mkdir(parents=True)
            store_file.write_text("x")
            link = t.path / "frozen"
            link.symlink_to(store_file)
            owner = dot.classify(str(link), current_generation=None, repo_dir=str(t.path / "dotfiles"))
            self.assertEqual(owner.kind, "frozen-store")

    def test_classifies_repo_symlink(self):
        with TempTree() as t:
            repo = t.path / "dotfiles"
            (repo / ".config").mkdir(parents=True)
            target = repo / ".config" / "niri"
            target.write_text("x")
            link = t.path / "niri"
            link.symlink_to(target)
            owner = dot.classify(str(link), current_generation=None, repo_dir=str(repo))
            self.assertEqual(owner.kind, "dotfiles")

    def test_classifies_runtime_directory(self):
        with TempTree() as t:
            d = t.path / "niri"
            d.mkdir()
            owner = dot.classify(str(d), current_generation=None, repo_dir=str(t.path))
            self.assertEqual(owner.kind, "runtime")

    def test_classifies_user_local_symlink(self):
        with TempTree() as t:
            fake_home = t.path / "home"
            fake_home.mkdir()
            target = fake_home / "notes.txt"
            target.write_text("x")
            link = t.path / "home-link"
            link.symlink_to(target)
            owner = dot.classify(
                str(link),
                current_generation=None,
                repo_dir=str(t.path / "dotfiles"),
                home=str(fake_home),
            )
            self.assertEqual(owner.kind, "local:user")

    def test_resolves_multi_hop_chain_without_hanging(self):
        with TempTree() as t:
            repo = t.path / "dotfiles"
            repo.mkdir()
            real = repo / "config.kdl"
            real.write_text("x")
            b = t.path / "b"
            b.symlink_to(real)
            a = t.path / "a"
            a.symlink_to(b)
            owner = dot.classify(str(a), current_generation=None, repo_dir=str(repo))
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


class RepoHygieneTests(unittest.TestCase):
    def test_dot_script_is_not_git_ignored(self):
        result = subprocess.run(
            ["git", "check-ignore", "-q", ".local/bin/dot"],
            cwd=REPO, capture_output=True,
        )
        self.assertNotEqual(result.returncode, 0, ".local/bin/dot is git-ignored")


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

    def test_records_absolute_path_token(self):
        text = 'spawn-at-startup "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1";'
        self.assertEqual([r.token for r in dot.extract_spawns(text)],
                         ["/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"])

    def test_records_path_argument_of_a_spawn(self):
        # `spawn-at-startup "bash" "/home/zeyad/.local/bin/headset-popup-daemon"`
        # first token is the program, the path argument is checked too
        refs = dot.extract_spawns('spawn-at-startup "bash" "/home/zeyad/.local/bin/headset-popup-daemon";')
        self.assertEqual([r.token for r in refs], ["bash", "/home/zeyad/.local/bin/headset-popup-daemon"])

    def test_startup_spawns_are_not_labelled_with_a_stale_block_header(self):
        text = 'window-rule {\n    match app-id="x"\n}\n\nspawn-at-startup "kanshi";'
        refs = dot.extract_spawns(text)
        self.assertEqual([r.context for r in refs], ["startup"])

    def test_records_the_keybind_that_owns_a_spawn(self):
        refs = dot.extract_spawns('Mod+Shift+S allow-when-locked=true { spawn "kitty"; }')
        self.assertEqual([r.context for r in refs], ["Mod+Shift+S"])


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
        if os.geteuid() == 0:
            self.skipTest("root reads a directory whatever its permission bits say")
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
            self.assertFalse(any(e.path.endswith("secret") for e in entries),
                             "the unreadable directory was scanned anyway")

    def test_findings_from_entries_marks_broken_and_stale(self):
        with TempTree() as t:
            entries = [dot.Entry("/x/ghostty/config", dot.Owner("broken", "/x/missing", "target missing")),
                       dot.Entry("/x/lazygit", dot.Owner("frozen-store", "/nix/store/abc-source/.config/lazygit", "frozen store copy"))]
            findings = dot.findings_from_entries(entries)
            self.assertEqual([f.severity for f in findings], ["broken", "stale"])
            self.assertTrue(all(f.fix for f in findings))

    def test_user_exclusion_file_removes_a_directory(self):
        with TempTree() as t:
            cfg = t.path / "config"
            (cfg / "skipme").mkdir(parents=True)
            (cfg / "skipme" / "inner").symlink_to(t.path / "nope")
            (cfg / "keep").mkdir()
            exclude = t.path / "exclude"
            exclude.write_text("# comment\n\nskipme\n")
            entries = dot.scan_configs([str(cfg)], current_generation=None, repo_dir=str(t.path),
                                       exclude_file=str(exclude))
            self.assertFalse(any("skipme" in e.path for e in entries))
            self.assertTrue(any("keep" in e.path for e in entries))

    def test_reports_a_broken_link_three_levels_deep(self):
        with TempTree() as t:
            cfg = t.path / "config"
            (cfg / "sway" / "scripts").mkdir(parents=True)
            (cfg / "sway" / "scripts" / "power_menu.sh").symlink_to(
                t.path / "dotfiles" / ".config" / "sway" / "scripts" / "power_menu.sh"
            )
            entries = dot.scan_configs([str(cfg)], current_generation=None,
                                       repo_dir=str(t.path / "dotfiles"))
            broken = [e.path for e in entries if e.owner.kind == "broken"]
            self.assertTrue(any(path.endswith("power_menu.sh") for path in broken))

    def test_shallow_root_is_not_scanned_deep(self):
        # `~/.local/share` holds application state: a broken link there is
        # noise, not a configuration mistake.
        with TempTree() as t:
            share = t.path / "share"
            (share / "mise" / "shims").mkdir(parents=True)
            (share / "mise" / "shims" / "node").symlink_to(t.path / "missing")
            entries = dot.scan_configs([str(share)], current_generation=None,
                                       repo_dir=str(t.path), shallow_roots={str(share)})
            self.assertFalse(any(e.owner.kind == "broken" for e in entries))

    def test_deep_entries_are_not_counted_as_managed_configs(self):
        inventory = dot.Inventory(
            apps=[],
            cli=[],
            scripts={},
            configs=[
                dot.Entry("/x/niri", dot.Owner("home-manager", "/repo/.config/niri", "HM"), 1),
                dot.Entry("/x/niri/scripts", dot.Owner("dotfiles", "/repo/.config/niri/scripts", "repo"), 2),
                dot.Entry("/x/niri/scripts/broken", dot.Owner("broken", "/x/missing", "missing"), 3),
            ],
            findings=[],
            meta={},
        )
        managed = dot._managed_configs(inventory)
        self.assertEqual([entry.path for entry in managed], ["/x/niri", "/x/niri/scripts"])


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

    def test_expands_home_environment_prefix(self):
        with TempTree() as t:
            target = t.path / "bin" / "tool"
            target.parent.mkdir()
            target.write_text("x")
            with mock.patch.dict(os.environ, {"HOME": str(t.path)}):
                self.assertEqual(dot.resolve_token("$HOME/bin/tool"), str(target))


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

    def test_collect_scripts_separates_git_tracked_from_untracked(self):
        with TempTree() as t:
            repo = t.path / "dotfiles"
            (repo / ".local" / "bin").mkdir(parents=True)
            (repo / ".local" / "bin" / "tracked-tool").write_text("x")
            subprocess.run(["git", "init", "-q", str(repo)], check=True, capture_output=True)
            subprocess.run(["git", "-C", str(repo), "add", ".local/bin/tracked-tool"],
                           check=True, capture_output=True)
            (repo / ".local" / "bin" / "loose-tool").write_text("x")
            result = dot.collect_scripts(str(repo / ".local" / "bin"), repo_dir=str(repo))
            self.assertEqual(result["repo"], ["tracked-tool"])
            self.assertEqual(result["local"], ["loose-tool"])

    def test_collect_desktop_entries_reads_name(self):
        with TempTree() as t:
            (t.path / "Brave.desktop").write_text("[Desktop Entry]\nName=Brave Browser\nExec=brave\n")
            entries = dot.collect_desktop_entries([str(t.path)])
            self.assertEqual(entries[0]["name"], "Brave Browser")

    def test_collect_desktop_entries_skips_entries_without_a_name(self):
        with TempTree() as t:
            (t.path / "Nameless.desktop").write_text("[Desktop Entry]\nExec=x\n")
            (t.path / "Named.desktop").write_text("[Desktop Entry]\nName=Named\nExec=x\n")
            entries = dot.collect_desktop_entries([str(t.path)])
            self.assertEqual([e["name"] for e in entries], ["Named"])

    def test_collect_desktop_entries_marks_user_source(self):
        with TempTree() as t:
            home = t.path / "home"
            applications = home / ".local" / "share" / "applications"
            applications.mkdir(parents=True)
            (applications / "A.desktop").write_text("[Desktop Entry]\nName=App A\nExec=a\n")
            entries = dot.collect_desktop_entries([str(applications)], home=str(home))
            self.assertEqual(entries[0]["source"], "user")
            self.assertEqual(sorted(entries[0]), ["desktop_file", "name", "source"])

    def test_collect_outdated_is_empty_when_command_missing(self):
        def fake_runner(cmd, **kwargs):
            raise FileNotFoundError("checkupdates")
        self.assertEqual(dot.collect_outdated(runner=fake_runner), [])

    def test_collect_outdated_keeps_only_the_package_name(self):
        def fake_runner(cmd, **kwargs):
            return subprocess.CompletedProcess(cmd, 0, "linux 6.9.1-1 -> 6.9.2-1\n", "")
        self.assertEqual(dot.collect_outdated(runner=fake_runner), ["linux"])

    def test_collect_outdated_gives_up_when_the_check_hangs(self):
        def hanging_runner(cmd, **kwargs):
            raise subprocess.TimeoutExpired(cmd, kwargs.get("timeout", 0))
        self.assertEqual(dot.collect_outdated(runner=hanging_runner), [])

    def test_collect_repo_state_missing_repo_is_empty(self):
        self.assertEqual(dot.collect_repo_state("/nonexistent/repo"),
                         {"modified": [], "untracked": []})

    def test_collect_repo_state_splits_modified_and_untracked(self):
        with TempTree() as t:
            repo = t.path / "dotfiles"
            repo.mkdir()
            tracked = repo / "file.txt"
            tracked.write_text("one\n")
            subprocess.run(["git", "init", "-q", str(repo)], check=True, capture_output=True)
            subprocess.run(["git", "-C", str(repo), "add", "file.txt"], check=True, capture_output=True)
            tracked.write_text("two\n")
            (repo / "loose.txt").write_text("x")
            state = dot.collect_repo_state(str(repo))
            self.assertIn("file.txt", state["modified"])
            self.assertIn("loose.txt", state["untracked"])

    def test_collect_repo_state_keeps_dotted_paths_intact(self):
        with TempTree() as t:
            repo = t.path / "dotfiles"
            repo.mkdir()
            tracked = repo / ".config"
            tracked.mkdir()
            (tracked / "accels.scm").write_text("x")
            subprocess.run(["git", "init", "-q", str(repo)], check=True, capture_output=True)
            subprocess.run(["git", "-C", str(repo), "add", ".config/accels.scm"],
                           check=True, capture_output=True)
            subprocess.run(
                ["git", "-C", str(repo), "-c", "user.email=dot@example.com",
                 "-c", "user.name=dot", "commit", "-q", "-m", "init"],
                check=True, capture_output=True,
            )
            (tracked / "accels.scm").write_text("y")
            state = dot.collect_repo_state(str(repo))
            self.assertIn(".config/accels.scm", state["modified"])

    def test_collect_tool_dirs_omits_missing_and_labels_existing(self):
        with TempTree() as t:
            shims = t.path / ".local" / "share" / "mise" / "shims"
            shims.mkdir(parents=True)
            (shims / "node").write_text("x")
            result = dot.collect_tool_dirs(dot.tool_dir_paths(home=str(t.path)))
            self.assertEqual(result["mise"], ["node"])
            self.assertNotIn("uv", result)


class NixDriftTests(unittest.TestCase):
    def test_parses_declared_names(self):
        text = "{\n  home.packages = with pkgs; [\n    git\n    ripgrep\n    traceroute\n  ];\n}\n"
        self.assertEqual(dot.parse_declared_packages(text), {"git", "ripgrep", "traceroute"})

    def test_keeps_the_package_name_of_a_derivation_block(self):
        text = (
            "{\n  home.packages = with pkgs; [\n"
            "    git\n"
            "    (stdenvNoCC.mkDerivation {\n"
            "      pname = \"workmux\";\n"
            "      version = \"0.1.269\";\n"
            "    })\n"
            "    ripgrep\n"
            "  ];\n}\n"
        )
        self.assertEqual(dot.parse_declared_packages(text), {"git", "workmux", "ripgrep"})

    def test_detects_declared_but_not_installed(self):
        findings = dot.nix_drift(
            {"traceroute", "neovim", "git"},
            {"nvim", "git"},
            {"neovim": ["nvim"], "git": ["git"]},
        )
        self.assertEqual([f.severity for f in findings], ["drift"])
        self.assertIn("traceroute", findings[0].detail)

    def test_detects_installed_but_not_declared(self):
        findings = dot.nix_drift(
            {"git"},
            {"git", "mandb"},
            {"git": ["git"], "man-db": ["mandb"]},
            profile_entries=[{
                "name": "man-db",
                "path": "/nix/store/" + "a" * 32 + "-man-db-2.13.1",
                "package": "man-db",
            }],
        )
        self.assertEqual([f.severity for f in findings], ["drift"])
        self.assertIn("man-db", findings[0].detail)

    def test_home_manager_entry_is_not_reported_as_undeclared(self):
        # Home Manager installs its own packages as one profile entry; that
        # entry is not something the declarations have to mention.
        findings = dot.nix_drift(
            {"git"},
            {"git", "man", "home-manager"},
            {"git": ["git"]},
            profile_entries=[{
                "name": "home-manager-path",
                "path": "/nix/store/" + "b" * 32 + "-home-manager-path",
                "package": "home-manager-path",
            }],
        )
        self.assertEqual(findings, [])

    def test_declared_package_satisfies_a_profile_entry(self):
        findings = dot.nix_drift(
            {"ripgrep"},
            {"rg"},
            {"ripgrep": ["rg"]},
            profile_entries=[{
                "name": "ripgrep",
                "path": "/nix/store/" + "c" * 32 + "-ripgrep-15.2.0",
                "package": "ripgrep",
            }],
        )
        self.assertEqual(findings, [])

    def test_no_undeclared_finding_without_the_profile_entries(self):
        # Without the profile entries the tool cannot tell an extra package
        # from a dependency, so it claims nothing.
        findings = dot.nix_drift({"git"}, {"git", "man"}, {"git": ["git"]})
        self.assertEqual(findings, [])

    def test_no_findings_when_all_declared_are_installed(self):
        findings = dot.nix_drift({"git"}, {"git"}, {"git": ["git"]})
        self.assertEqual(findings, [])

    def test_declared_package_is_satisfied_by_a_renamed_binary(self):
        # nixpkgs ships `antigravity` as the package `antigravity-ide`.
        findings = dot.nix_drift({"antigravity"}, {"antigravity-ide"}, {"antigravity-ide": ["antigravity-ide"]})
        self.assertEqual(findings, [])

    def test_declared_package_is_satisfied_by_a_shorter_package_name(self):
        # the attribute `nixfmt-rfc-style` provides the package `nixfmt`.
        findings = dot.nix_drift({"nixfmt-rfc-style"}, {"nixfmt"}, {"nixfmt": ["nixfmt"]})
        self.assertEqual(findings, [])

    def test_reports_an_undeclared_package_once(self):
        findings = dot.nix_drift(
            {"git"},
            {"git", "man", "mandb"},
            {"git": ["git"], "man-db": ["man", "mandb"]},
            profile_entries=[{
                "name": "man-db",
                "path": "/nix/store/" + "d" * 32 + "-man-db-2.13.1",
                "package": "man-db",
            }],
        )
        self.assertEqual(len(findings), 1)
        self.assertIn("man-db", findings[0].detail)
        self.assertIn("mandb", findings[0].detail)

    def test_collect_profile_entries_parses_the_nix_output(self):
        payload = json.dumps({
            "elements": {
                "home-manager-path": {
                    "active": True,
                    "storePaths": ["/nix/store/" + "e" * 32 + "-home-manager-path"],
                },
            },
            "version": 3,
        })

        def fake_runner(cmd, **kwargs):
            return subprocess.CompletedProcess(cmd, 0, payload, "")

        entries = dot.collect_profile_entries(runner=fake_runner)
        self.assertEqual(len(entries), 1)
        self.assertEqual(entries[0]["name"], "home-manager-path")
        self.assertEqual(entries[0]["package"], "home-manager-path")

    def test_collect_profile_entries_is_empty_without_nix(self):
        def fake_runner(cmd, **kwargs):
            raise FileNotFoundError("nix")
        self.assertEqual(dot.collect_profile_entries(runner=fake_runner), [])

    def test_home_manager_entry_is_recognised(self):
        entry = {
            "name": "home-manager-path",
            "path": "/nix/store/" + "f" * 32 + "-home-manager-path",
            "package": "home-manager-path",
        }
        self.assertTrue(dot._is_home_manager_entry(entry))
        self.assertFalse(dot._is_home_manager_entry({"name": "ripgrep", "package": "ripgrep"}))

    def test_does_not_report_drift_without_a_package_map(self):
        # Without the nix CLI a package's binary may carry another name
        # (`neovim` ships `nvim`), so the declarations cannot be checked —
        # reporting drift here would be a lie.
        findings = dot.nix_drift({"neovim", "traceroute"}, {"nvim", "git"}, {})
        self.assertEqual(findings, [])

    def test_package_binary_map_is_empty_without_nix(self):
        def fake_runner(cmd, **kwargs):
            raise FileNotFoundError("nix")
        self.assertEqual(dot.package_binary_map(runner=fake_runner), {})

    def test_package_binary_map_maps_binaries_to_their_package(self):
        with TempTree() as t:
            store = t.path / "nix" / "store" / ("a" * 32 + "-neovim-0.12.5") / "bin"
            store.mkdir(parents=True)
            (store / "nvim").write_text("x")
            profile = t.path / "profile" / "bin"
            profile.mkdir(parents=True)
            (profile / "nvim").symlink_to(store / "nvim")

            def fake_runner(cmd, **kwargs):
                payload = json.dumps({path: {} for path in cmd[3:]})
                return subprocess.CompletedProcess(cmd, 0, payload, "")

            result = dot.package_binary_map(str(profile), runner=fake_runner)
            self.assertEqual(result, {"neovim": ["nvim"]})


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
        self.assertIn("BROKEN (1)", out)
        self.assertIn("/home/z/.config/ghostty/config", out)
        self.assertIn("fix:", out)

    def test_render_status_states_no_findings(self):
        inv = self._inventory()
        empty = dot.Inventory(apps=inv.apps, cli=inv.cli, scripts=inv.scripts,
                              configs=inv.configs, findings=[], meta=inv.meta)
        self.assertIn("no findings", dot.render_status(empty).lower())

    def test_inventory_json_matches_frozen_schema(self):
        data = dot.inventory_json(self._inventory(), command="list")
        self.assertEqual(set(data), {"tool", "version", "command", "generated_at", "summary", "sections"})
        self.assertEqual(data["tool"], "dot")
        self.assertEqual(data["version"], "1")
        self.assertEqual(set(data["sections"]), {"apps", "cli", "scripts", "configs"})

    def test_status_json_has_counts_and_findings(self):
        data = dot.inventory_json(self._inventory(), command="status")
        self.assertEqual(data["ok"], False)
        self.assertEqual(data["counts"]["broken"], 1)
        self.assertEqual(data["findings"][0]["severity"], "broken")

    def test_render_list_shows_the_source_breakdown(self):
        out = dot.render_list(self._inventory())
        self.assertIn("system 1", out)
        self.assertIn("pacman 2", out)
        self.assertIn("EndeavourOS", out)

    def test_render_list_leaves_runtime_configs_out_of_the_count(self):
        inv = dot.Inventory(
            apps=[], cli=[], scripts={},
            configs=[
                dot.Entry("/home/z/.config/niri", dot.Owner("home-manager", "/repo/.config/niri", "HM")),
                dot.Entry("/home/z/.config/app", dot.Owner("runtime", "/home/z/.config/app", "local file")),
            ],
            findings=[], meta={},
        )
        out = dot.render_list(inv)
        self.assertIn("Managed configs      1", out)

    def test_inventory_json_uses_the_frozen_item_shapes(self):
        data = dot.inventory_json(self._inventory(), command="list")
        self.assertEqual(set(data["sections"]["apps"]["items"][0]), {"name", "desktop_file", "source"})
        self.assertEqual(set(data["sections"]["cli"]["items"][0]), {"source", "name"})
        self.assertEqual(set(data["sections"]["scripts"]["items"][0]), {"group", "name"})
        self.assertEqual(set(data["sections"]["configs"]["items"][0]), {"path", "owner", "target"})

    def test_status_json_counts_have_the_frozen_keys(self):
        data = dot.inventory_json(self._inventory(), command="status")
        self.assertEqual(set(data["counts"]), {"broken", "stale", "missing", "drift", "info"})

    def test_status_json_is_ok_without_findings(self):
        inv = self._inventory()
        empty = dot.Inventory(apps=inv.apps, cli=inv.cli, scripts=inv.scripts,
                              configs=inv.configs, findings=[], meta=inv.meta)
        data = dot.inventory_json(empty, command="status")
        self.assertEqual(data["ok"], True)
        self.assertEqual(data["findings"], [])


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
        import io
        from contextlib import redirect_stdout
        buf = io.StringIO()
        with redirect_stdout(buf):
            with self.assertRaises(SystemExit) as ctx:
                dot.main(["--help"])
        self.assertEqual(ctx.exception.code, 0)
        self.assertIn("usage: dot", buf.getvalue())

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
        with TempTree() as t:
            with redirect_stdout(io.StringIO()):
                dot.build_inventory(home=str(t.path))
        self.assertTrue(recorded, "the inventory ran no command at all, so nothing was checked")
        for cmd in recorded:
            program = os.path.basename(cmd[0])
            self.assertNotEqual(program, "sudo")
            if program == "pacman":
                self.assertNotIn(cmd[1], ("-S", "-R", "-U", "-Sy", "-Rns"))

    def test_build_inventory_survives_missing_repo(self):
        inv = dot.build_inventory(home="/tmp", repo_dir="/nonexistent/repo")
        self.assertIsInstance(inv, dot.Inventory)

    def test_list_outdated_prints_the_list_before_the_update_check(self):
        import io
        inv = dot.Inventory(apps=[], cli=[], scripts={}, configs=[], findings=[],
                            meta={"distro": "TestOS", "host": "testhost"})
        self._stub(inv)

        def boom(*args, **kwargs):
            raise RuntimeError("the update check hung")

        original = dot.collect_outdated
        dot.collect_outdated = boom
        self.addCleanup(setattr, dot, "collect_outdated", original)
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            with self.assertRaises(RuntimeError):
                dot.main(["list", "--outdated"])
        self.assertIn("System inventory", buf.getvalue())


class NixDegradationTests(unittest.TestCase):
    """The nix layer must degrade instead of inventing findings."""

    def _repo(self, t, text):
        repo = t.path / "dotfiles"
        (repo / "nix" / "modules").mkdir(parents=True)
        (repo / "nix" / "modules" / "packages.nix").write_text(text)
        return str(repo)

    def test_nix_findings_report_nix_not_present_without_a_profile(self):
        with TempTree() as t:
            repo = self._repo(t, "{\n  home.packages = with pkgs; [\n    git\n  ];\n}\n")
            findings = dot._nix_findings(repo, str(t.path / "profile" / "bin"), [])
            self.assertEqual([f.severity for f in findings], ["info"])
            self.assertIn("not present", findings[0].detail)

    def test_nix_findings_report_unverified_packages_when_the_profile_cannot_be_mapped(self):
        with TempTree() as t:
            repo = self._repo(t, "{\n  home.packages = with pkgs; [\n    git\n  ];\n}\n")
            profile = t.path / "profile" / "bin"
            profile.mkdir(parents=True)
            (profile / "git").write_text("x")
            findings = dot._nix_findings(repo, str(profile), ["git"])
            self.assertEqual([f.severity for f in findings], ["info"])
            self.assertIn("could not be verified", findings[0].detail)

    def test_nix_findings_report_a_drift_when_the_packages_are_mapped(self):
        with TempTree() as t:
            repo = self._repo(t, "{\n  home.packages = with pkgs; [\n    git\n    traceroute\n  ];\n}\n")
            profile = t.path / "profile" / "bin"
            profile.mkdir(parents=True)
            (profile / "git").write_text("x")
            findings = dot._nix_findings(repo, str(profile), ["git"], package_bins={"git": ["git"]})
            self.assertEqual([f.severity for f in findings], ["drift"])
            self.assertIn("traceroute", findings[0].detail)

    def test_declarations_state_reports_a_missing_list(self):
        text = "{ pkgs, ... }:\n{\n  home.stateVersion = \"24.11\";\n}\n"
        self.assertEqual(dot.declarations_state(text), "no-list")

    def test_declarations_state_reports_an_empty_list(self):
        text = "{\n  home.packages = with pkgs; [\n  ];\n}\n"
        self.assertEqual(dot.declarations_state(text), "empty")

    def test_declarations_state_reports_a_readable_list(self):
        text = "{\n  home.packages = with pkgs; [\n    git\n  ];\n}\n"
        self.assertEqual(dot.declarations_state(text), "ok")

    def test_parses_declared_names_with_any_indentation(self):
        text = "{\n  home.packages = with pkgs; [\n  git\n  ripgrep\n  ];\n}\n"
        self.assertEqual(dot.parse_declared_packages(text), {"git", "ripgrep"})


class SpawnFixHintTests(unittest.TestCase):
    def test_package_for_binary_names_the_package_that_provides_it(self):
        def fake_runner(cmd, **kwargs):
            return SimpleNamespace(returncode=0, stdout="extra/libnotify 4.0-1 (base)\n    usr/bin/notify-send\n")
        self.assertEqual(dot._package_for_binary("notify-send", runner=fake_runner), "libnotify")

    def test_package_for_binary_falls_back_to_the_binary_name(self):
        def fake_runner(cmd, **kwargs):
            return SimpleNamespace(returncode=1, stdout="")
        self.assertEqual(dot._package_for_binary("mystery", runner=fake_runner), "mystery")

    def test_missing_spawn_path_suggests_restoring_the_file(self):
        with TempTree() as t:
            config = t.path / "config.kdl"
            config.write_text('spawn-at-startup "/nope/missing.sh"\n')
            findings = dot._spawn_findings(str(config))
            self.assertEqual([f.severity for f in findings], ["missing"])
            self.assertIn("does not exist", findings[0].detail)
            self.assertIn("create or restore", findings[0].fix)


class ReviewRegressionTests(unittest.TestCase):
    def test_top_cli_prefers_the_curated_tools(self):
        inv = dot.Inventory(
            apps=[],
            cli=[dot.Source("nix", ["accessdb", "apropos", "btop", "git", "nvim", "rg", "zoxide"], "cli")],
            scripts={}, configs=[], findings=[], meta={},
        )
        out = dot.render_list(inv)
        top = out.split("Top CLI:")[1].split("\n")[0]
        self.assertLess(top.index("git"), top.index("accessdb"))

    def test_render_status_says_no_problems_when_only_info_findings(self):
        inv = dot.Inventory(apps=[], cli=[], scripts={}, configs=[],
                            findings=[dot.Finding("repo-dirty", "info", "/repo", "2 modified", "", "")],
                            meta={})
        out = dot.render_status(inv)
        self.assertIn("no problems", out.lower())
        self.assertNotIn("no findings", out.lower())

    def test_build_inventory_does_not_report_drift_without_a_nix_profile(self):
        with TempTree() as t:
            inv = dot.build_inventory(home=str(t.path), repo_dir=str(REPO))
            drift = [f for f in inv.findings if f.severity == "drift"]
            self.assertEqual(drift, [])

    def test_build_inventory_classifies_links_against_the_given_home(self):
        with TempTree() as t:
            home = t.path / "home"
            (home / ".config" / "tool").mkdir(parents=True)
            (home / "bin").mkdir()
            (home / "bin" / "thing").write_text("x")
            (home / ".config" / "tool" / "config").symlink_to(home / "bin" / "thing")
            inv = dot.build_inventory(home=str(home), repo_dir="")
            kinds = {e.path.split("/")[-1]: e.owner.kind for e in inv.configs}
            self.assertEqual(kinds.get("config"), "local:user")

    def test_list_ownership_prints_the_config_ownership_map(self):
        inv = dot.Inventory(
            apps=[], cli=[], scripts={},
            configs=[dot.Entry("/home/z/.config/niri", dot.Owner("home-manager", "/repo/.config/niri", "Home Manager (live repo)"))],
            findings=[], meta={},
        )
        original = dot.build_inventory
        dot.build_inventory = lambda **kwargs: inv
        self.addCleanup(setattr, dot, "build_inventory", original)
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            code = dot.main(["list", "--ownership"])
        out = buf.getvalue()
        self.assertEqual(code, 0)
        self.assertIn("Config ownership", out)
        self.assertIn("/home/z/.config/niri", out)

    def test_list_section_flag_prints_only_that_section(self):
        inv = dot.Inventory(
            apps=[{"name": "Brave", "desktop_file": "/x.desktop", "source": "system"}],
            cli=[dot.Source("pacman", ["git"], "package")],
            scripts={"repo": ["set-theme"]}, configs=[], findings=[], meta={},
        )
        original = dot.build_inventory
        dot.build_inventory = lambda **kwargs: inv
        self.addCleanup(setattr, dot, "build_inventory", original)
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            code = dot.main(["list", "--apps"])
        out = buf.getvalue()
        self.assertEqual(code, 0)
        self.assertIn("Brave", out)
        self.assertNotIn("pacman", out)

    def test_list_wide_shows_more_cli_names(self):
        names = [f"tool{index:02d}" for index in range(20)]
        inv = dot.Inventory(apps=[], cli=[dot.Source("nix", names, "cli")], scripts={},
                            configs=[], findings=[], meta={})
        original = dot.build_inventory
        dot.build_inventory = lambda **kwargs: inv
        self.addCleanup(setattr, dot, "build_inventory", original)
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            dot.main(["list", "--wide"])
        top = buf.getvalue().split("Top CLI:")[1].split("\n")[0]
        self.assertGreater(len(top.split()), 12)


class HealthTests(unittest.TestCase):
    """The health probe is the cheap one: no pacman, no nix, no git."""

    def _home(self, t):
        home = t.path / "home"
        (home / ".config").mkdir(parents=True)
        return home

    def _capture(self, argv):
        import io
        from contextlib import redirect_stdout
        buf = io.StringIO()
        with redirect_stdout(buf):
            code = dot.main(argv)
        return code, buf.getvalue()

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

    def test_health_command_json_prints_the_three_keys(self):
        original = dot.collect_health
        dot.collect_health = lambda **kwargs: dot.Health(
            ok=True, counts={"broken": 0, "stale": 0, "missing": 0}, findings=[],
            text="●", tooltip="dot: no problems", style="ok")
        self.addCleanup(setattr, dot, "collect_health", original)
        code, out = self._capture(["health", "--json"])
        self.assertEqual(code, 0)
        self.assertEqual(sorted(json.loads(out).keys()), ["class", "text", "tooltip"])

    def test_health_probe_runs_no_command_at_all(self):
        """The bar calls this every ten seconds: pacman, nix and git are too slow."""
        recorded = []
        real_run = subprocess.run

        def spy(cmd, *args, **kwargs):
            recorded.append(cmd if isinstance(cmd, list) else [cmd])
            return real_run(cmd, *args, **kwargs)

        subprocess.run = spy
        self.addCleanup(setattr, subprocess, "run", real_run)
        with TempTree() as t:
            home = self._home(t)
            niri = home / ".config" / "niri"
            niri.mkdir(parents=True)
            (niri / "config.kdl").write_text('binds {\n    Mod+T { spawn "definitely-not-installed-xyz"; }\n}\n')
            health = dot.collect_health(home=str(home), repo_dir=str(t.path / "dotfiles"))
        self.assertEqual(health.counts["missing"], 1)
        self.assertEqual(recorded, [])


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

    def _capture(self, argv, repo=None, assume_yes=False):
        buf = io.StringIO()
        original_repo = dot.default_repo_dir
        original_confirm = dot.confirm
        if repo is not None:
            dot.default_repo_dir = lambda: repo
        dot.confirm = lambda question, **kwargs: assume_yes or kwargs.get("assume_yes", False)
        self.addCleanup(setattr, dot, "default_repo_dir", original_repo)
        self.addCleanup(setattr, dot, "confirm", original_confirm)
        with contextlib.redirect_stdout(buf):
            code = dot.main(argv)
        return code, buf.getvalue()

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
            # ripgrep must not be declared yet, or the test would pass without
            # ever exercising the binary→package mapping.
            repo = self._repo(t, PACKAGES_NIX.replace("    ripgrep\n", ""))
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
