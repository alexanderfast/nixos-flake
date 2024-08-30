{ config, pkgs, ... }:

{
  imports = [
    ./hardware.nix
    ../../configuration.nix
    #../../xfc4.nix
    ../../modules/plasma.nix
    #../../modules/nvidia.nix
    ../../modules/bootsystemd.nix
  ];

  networking.hostName = "nuc";

  environment.systemPackages = [
    pkgs.jellyfin
    pkgs.jellyfin-web
    pkgs.jellyfin-ffmpeg
    pkgs.wireguard-tools
    # pkgs.mosh
  ];

  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };

  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager = "startplasma-x11";
  services.xrdp.openFirewall = true;

  #services.qbittorrent = {
  #  enable = true;
  #  dataDir = "/var/lib/qbittorrent";
  #  openFirewall = true;
  #  port = 8080;
  #};

  # enable NAT
  networking.nat.enable = true;
  networking.nat.externalInterface = "enp86s0";
  # networking.nat.internalInterfaces = [ "wg0" ];
  networking.firewall = {
    allowedUDPPorts = [ 51820 ];
  };

  networking.wg-quick.interfaces = {
    # "wg0" is the network interface name. You can name the interface arbitrarily.
    wg0 = {
      # Determines the IP/IPv6 address and subnet of the client's end of the tunnel interface
      address = [ "10.0.0.1/24" ];
      # The port that WireGuard listens to - recommended that this be changed from default
      listenPort = 51820;
      # Path to the server's private key
      privateKeyFile = "/srv/wireguard/private";

      # This allows the wireguard server to route your traffic to the internet and hence be like a VPN
      postUp = ''
        ${pkgs.iptables}/bin/iptables -A FORWARD -i wg0 -o wg0 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -A POSTROUTING -o enp86s0 -j MASQUERADE
      '';

      # Undo the above
      preDown = ''
        ${pkgs.iptables}/bin/iptables -D FORWARD -i wg0 -o wg0 -j ACCEPT
        ${pkgs.iptables}/bin/iptables -t nat -D POSTROUTING -o enp86s0 -j MASQUERADE
      '';

      peers = [
        { # peer0
          publicKey = "wMYARVyMbiPjBqpXR6L+d0UEYl+T0yPo2yPeo4r4TDg=";
          presharedKeyFile = "/srv/wireguard/peer0/private";
          allowedIPs = [ "10.0.0.2/32" ];
        }
        # More peers can be added here.
      ];
    };
  };
}
