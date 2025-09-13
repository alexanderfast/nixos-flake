{ config, pkgs, ... }:
{
  services.dnsmasq = {
    enable = true;

    settings = {
      # interface = [ "enp86s0" ];
      # bind-interface = "true";

      # Forward everything else to your ISP or preferred DNS
      server = [ "1.1.1.1" "8.8.8.8" ];

      # Add your custom names here
      address = [
        "/router.lan/192.168.1.1"
        "/nuc.lan/192.168.1.101"
      ];

      # Optional: serve DHCP too (if you want dnsmasq as your DHCP server)
      # dhcp-range = "192.168.1.100,192.168.1.200,12h";
    };
  };

  networking.firewall.allowedTCPPorts = [ 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
