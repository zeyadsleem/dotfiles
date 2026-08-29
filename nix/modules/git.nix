{
  pkgs,
  ...
}:
{
  programs.git = {
    enable = true;
    package = pkgs.git;
    settings = {
      user.name = "zeyad sleem";
      user.email = "zeyadsleem1@gmail.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      push.followTags = true;
      diff.algorithm = "histogram";
      diff.colorMoved = "zebra";
      merge.conflictStyle = "zdiff3";
      commit.verbose = true;
      branch.sort = "-committerdate";
      fetch.prune = true;
      core.editor = "$EDITOR";
      core.pager = "delta";
      delta.features = "side-by-side line-numbers";
      delta."syntax-theme" = "Dracula";
      delta.navigate = true;
      rerere.enabled = true;
      rebase.autosquash = true;
      rebase.autoStash = true;
    };
  };
}