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
  home.packages = [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    #pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
    (pkgs.nerdfonts.override { fonts = [ "Hack" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')

    #pkgs.webcamoid
    pkgs.git
    pkgs.kitty
    #pkgs.zsh
    pkgs.openconnect
    pkgs.starship
    pkgs.tmux
    pkgs.fzf
    pkgs.unzip

    #pkgs.xfce.xfce4-power-manager
    #pkgs.xfce.xfce4-battery-plugin
    pkgs.xfce.xfce4-terminal

    pkgs.python39
    pkgs.python39Packages.pip
    pkgs.python39Packages.pygments
    pkgs.pipenv

    #pkgs.clang
    pkgs.cmake
    #pkgs.glibc
    #pkgs.libclang
    #pkgs.lldb
    pkgs.gcc

    # needed by nvim
    #pkgs.nodePackages.npm
    pkgs.ripgrep
    pkgs.nodejs_21
    pkgs.cargo
    pkgs.nil

    pkgs.k9s
    pkgs.kubernetes
    pkgs.vault
    pkgs.go-task
    pkgs.jq
    pkgs.tree
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
      #nix-direnv.enable = true;
    };

    zsh.enable = true;
  };
}
