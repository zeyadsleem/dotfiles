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
