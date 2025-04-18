{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    # ../../configuration.nix
    ../../modules/home-xfce4-i3.nix
    ../../modules/bootgrub.nix
    ../../modules/configuration.nix
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };
  networking.networkmanager.enable = true;

  services.xserver.xkb.options = "ctrl:swapcaps";
  services.libinput.enable = true;
  services.libinput.touchpad.disableWhileTyping = true;
  services.xserver.synaptics.enable = false;

  networking.hostName = "laptop";
  networking.networkmanager.wifi.powersave = false;
  networking.nat.enable = true;
  networking.nat.externalInterface = "wlp0s20f3";
  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
  };

  environment.systemPackages = with pkgs; [ brightnessctl ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.alex = {
    isNormalUser = true;
    description = "Alex";
    extraGroups = [ "networkmanager" "wheel" "camera" "video" "audio" "lp" ];
    # shell = pkgs.zsh;
    #packages = with pkgs; [
    #  firefox
    #  kate
    #  thunderbird
    #];
  };


  # networking.wg-quick.interfaces = {
  #   wg0 = {
  #     address = [ "10.0.0.2/24" ];
  #     privateKeyFile = "/home/alex/wireguard/private";
  #
  #     peers = [
  #       { # server
  #         publicKey = "L+Y+B8gYxqonPlNhim+CDnDJipZMBdO/HnNsEqCEcWU=";
  #         presharedKeyFile = "/home/alex/wireguard/private";
  #         allowedIPs = [ "10.0.0.1/32" ];
  #         endpoint = "192.168.1.101:51820";
  #         persistentKeepalive = 25;
  #       }
  #     ];
  #   };
  # };
}
