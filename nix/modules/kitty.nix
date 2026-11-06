{
  config,
  lib,
  dotfilesDir,
  ...
}:
{
  # Whole-directory link: Noctalia's Kitty template writes themes/noctalia.conf
  # next to kitty.conf, and Kitty resolves relative includes against the real
  # path of the config file.
  home.file.".config/kitty" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.config/kitty";
  };
}
