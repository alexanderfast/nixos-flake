{ config, pkgs, ... }:

{
  # Configure keymap in X11
  services.xserver = {
    enable = true;

    xkb = {
      layout = "se";
      variant = "nodeadkeys";
    };

    displayManager = {
      sddm.enable = true;
      #defaultSession = "none+bspwm";
      defaultSession = "xfce";
    };

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
}
