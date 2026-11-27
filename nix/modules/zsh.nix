{ config, dotfilesDir, ... }:
{
  # .zshrc is the single source of truth for interactive shell config
  # (aliases, functions, plugins, prompt, keybindings). .p10k.zsh remains
  # separate because it is a large generated Powerlevel10k config.
  home.file.".zshrc" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.zshrc";
  };
  home.file.".p10k.zsh" = {
    source = config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/.p10k.zsh";
  };
}
