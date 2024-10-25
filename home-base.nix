{ config, pkgs, ... }:

{
  imports = [
    #./home-xfce4-i3.nix
    #./home-xfce.nix
  ];

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "alex";
  home.homeDirectory = "/home/alex";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
    (nerdfonts.override { fonts = [ "Hack" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')

    git
    git-lfs
    kitty
    openconnect
    starship
    tmux
    fzf
    unzip
    dos2unix
    xclip
    zoxide

    xfce.xfce4-terminal

    #python39
    #python39Packages.pip
    #python39Packages.pygments
    #python39Packages.autopep8
    #python39Packages.autoflake
    #pipenv
    chroma

    # gnumake
    # cmake
    # gcc

    # needed by nvim
    ripgrep
    nodejs
    cargo
    nil
    lua-language-server
    pyright
    shellcheck
    shfmt
    stylua
    nodePackages.prettier
    prettierd
    jsonfmt
    bat
    vscode-langservers-extracted

    wally-cli
    lazygit
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';

    ".config/dunst".source = config.lib.file.mkOutOfStoreSymlink
      "/home/${config.home.username}/.dotfiles/dunst";
    ".config/i3".source = config.lib.file.mkOutOfStoreSymlink
      "/home/${config.home.username}/.dotfiles/i3";
    ".config/kitty".source = config.lib.file.mkOutOfStoreSymlink
      "/home/${config.home.username}/.dotfiles/kitty";
    ".config/nvim".source = config.lib.file.mkOutOfStoreSymlink
      "/home/${config.home.username}/.dotfiles/nvim";
    ".config/picom".source = config.lib.file.mkOutOfStoreSymlink
      "/home/${config.home.username}/.dotfiles/picom";
    ".config/rofi".source = config.lib.file.mkOutOfStoreSymlink
      "/home/${config.home.username}/.dotfiles/rofi";
    ".tmux.conf".source = config.lib.file.mkOutOfStoreSymlink
      "/home/${config.home.username}/.dotfiles/tmux/tmux.conf";
    ".tmux".source = config.lib.file.mkOutOfStoreSymlink
      "/home/${config.home.username}/.dotfiles/tmux";
    ".oh-my-zsh".source = config.lib.file.mkOutOfStoreSymlink
      "/home/${config.home.username}/.dotfiles/ohmyzsh";
    ".zshenv".source = config.lib.file.mkOutOfStoreSymlink
      "/home/${config.home.username}/.dotfiles/zsh/zshenv";
    ".zshrc".source = config.lib.file.mkOutOfStoreSymlink
      "/home/${config.home.username}/.dotfiles/zsh/zshrc";
  };

  #xdg.configFile."i3".source = ./.dotfiles/i3;

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. If you don't want to manage your shell through Home
  # Manager then you have to manually source 'hm-session-vars.sh' located at
  # either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/alex/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    EDITOR = "nvim";
    NIX_BUILD_SHELL = "zsh";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  programs = {
    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

    zsh.enable = true;
  };
}
