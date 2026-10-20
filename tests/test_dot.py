import contextlib
import importlib.machinery
import importlib.util
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
