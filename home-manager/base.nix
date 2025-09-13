# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  config,
  pkgs,
  ...
}:

{
  # You can import other home-manager modules here
  imports = [
    # If you want to use modules your own flake exports (from modules/home-manager):
    # outputs.homeManagerModules.example

    # Or modules exported from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModules.default

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  nixpkgs = {
  #  # You can add overlays here
  #  overlays = [
  #    # Add overlays your own flake exports (from overlays and pkgs dir):
  #    outputs.overlays.additions
  #    outputs.overlays.modifications
  #    outputs.overlays.unstable-packages

  #    # You can also add overlays exported from other flakes:
  #    # neovim-nightly-overlay.overlays.default

  #    # Or define it inline, for example:
  #    # (final: prev: {
  #    #   hi = final.hello.overrideAttrs (oldAttrs: {
  #    #     patches = [ ./change-hello-to-hi.patch ];
  #    #   });
  #    # })
  #  ];
  #  # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  # home = {
  #   username = "alex";
  #   homeDirectory = "/home/alex";
  # };

  # Add stuff for your user as you see fit:
  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [
      # Language server packages (executables)
      # haskell-language-server
      # sumneko-lua-language-server
      # elmPackages.elm-language-server
      # rust-analyzer
      # pyright
    ];
  };

  # home.packages = with pkgs; [ steam ];

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";

  # The home.packages option allows you to install Nix packages into your
  # environment.
  home.packages = with pkgs; [
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
    # (nerdfonts.override { fonts = [ "Hack" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')

    curl
    dos2unix
    fzf
    git
    git-lfs
    home-manager
    htop
    i3
    jq
    killall
    kitty
    # neovim
    nerdfonts
    openconnect
    parted
    ripgrep
    starship
    tmux
    tree
    unzip
    wget
    xclip
    zoxide
    zsh

    xfce.xfce4-terminal

    #python39
    #python39Packages.pip
    #python39Packages.pygments
    #python39Packages.autopep8
    #python39Packages.autoflake
    #pipenv

    # needed by shell
    chroma
    python311Packages.pygments

    # gnumake
    # cmake
    # gcc

    # needed by nvim
    ripgrep
    nodejs
    cargo
    nil
    lua-language-server
    # pyright
    shellcheck
    shfmt
    stylua
    nodePackages.prettier
    prettierd
    jsonfmt
    bat
    vscode-langservers-extracted
    zig
    tree-sitter

    wally-cli
    lazygit

    # TODO: move to desktop module
    firefox
    slack
    rofi
    feh
    dunst
    libnotify
    vlc
    arandr
    autorandr
    scrot
    imagemagick
    shutter
    remmina
    btop
    i3
    keymapp

    docker-compose
  ];

  # fonts.packages = [
  #   nerd-fonts.hack
  # ];

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
    git.enable = true;
    starship.enable = true;
  };
}
