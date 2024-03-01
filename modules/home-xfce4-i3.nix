{ config, pkgs, lib, ... }:

{
  environment = { systemPackages = with pkgs; [ zuki-themes picom ]; };

  #gtk = {
  #  enable = true;
  #  iconTheme = {
  #    name = "elementary-Xfce-dark";
  #    package = pkgs.elementary-xfce-icon-theme;
  #  };
  #  theme = {
  #    name = "zukitre-dark";
  #    package = pkgs.zuki-themes;
  #  };
  #  gtk3.extraConfig = {
  #    Settings = ''
  #      gtk-application-prefer-dark-theme=1
  #    '';
  #  };
  #  gtk4.extraConfig = {
  #    Settings = ''
  #      gtk-application-prefer-dark-theme=1
  #    '';
  #  };
  #};

  hardware = { bluetooth.enable = true; };

  #programs.gpg.enable = true;

  #services.gpg-agent.enable = true;

  programs = {
    dconf.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-media-tags-plugin
        thunar-volman
      ];
    };
  };

  security.pam.services.gdm.enableGnomeKeyring = true;

  services = {
    blueman.enable = true;
    gnome.gnome-keyring.enable = true;
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
    };
    xserver = {
      enable = true;
      excludePackages = with pkgs; [ xterm ];
      xkb = {
        layout = "se";
        variant = "nodeadkeys";
      };
      displayManager = {
        lightdm = {
          enable = true;
          greeters.slick = {
            enable = true;
            theme.name = "Zukitre-dark";
          };
        };
      };
      #desktopManager.xfce.enable = true;
      desktopManager = {
        plasma5.enable = false;
        xterm.enable = false;
        xfce = {
          enable = true;
          noDesktop = true;
          enableXfwm = false;
        };
      };
      windowManager = {
        #  bspwm.enable = true;
        i3.enable = true;
      };
    };
  };

}
