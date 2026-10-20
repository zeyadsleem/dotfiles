import contextlib
import importlib.machinery
import importlib.util
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

    def test_declared_package_is_satisfied_by_a_renamed_binary(self):
        # nixpkgs ships `antigravity` as the package `antigravity-ide`.
        findings = dot.nix_drift({"antigravity"}, {"antigravity-ide"}, {})
        self.assertEqual(findings, [])

    def test_declared_package_is_satisfied_by_a_shorter_package_name(self):
        # the attribute `nixfmt-rfc-style` provides the package `nixfmt`.
        findings = dot.nix_drift({"nixfmt-rfc-style"}, {"nixfmt"}, {})
        self.assertEqual(findings, [])

    def test_reports_an_undeclared_package_once(self):
        findings = dot.nix_drift(
            {"git"}, {"git", "man", "mandb"}, {"git": ["git"], "man-db": ["man", "mandb"]}
        )
        self.assertEqual(len(findings), 1)
        self.assertIn("man-db", findings[0].detail)

    def test_reports_unattributed_binaries_when_nix_is_unavailable(self):
        findings = dot.nix_drift({"git"}, {"git", "mystery"}, {})
        self.assertEqual(len(findings), 1)
        self.assertEqual(findings[0].id, "nix-unattributed")
        self.assertIn("mystery", findings[0].detail)

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
