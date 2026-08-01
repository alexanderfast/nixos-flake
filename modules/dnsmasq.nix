{ config, pkgs, ... }:
{
  services.resolved.enable = false;

  networking.resolvconf.enable = true;

  networking.nameservers = [
    "127.0.0.1"
    # "1.1.1.1"
    # "8.8.8.8"
  ];

  services.dnsmasq = {
    enable = true;

    settings = {
      # Run dnsmasq on a non-standard port to avoid systemd-resolved
      port = 53;

      # Ignore /etc/dnsmasq-resolv.conf. resolvconf merges tailscaled's
      # `nameserver 100.100.100.100` fragment into that file, and without this
      # flag dnsmasq picks it up as a *generic* upstream alongside 9.9.9.9. Then
      # tailscaled's own upstream is dnsmasq (127.0.0.1), and generic queries
      # loop between the two until each side times out -- house-wide slow DNS,
      # since every device forwards here. Explicit `server=` lines below are
      # enough; the split-DNS entry keeps tailnet names resolving.
      no-resolv = true;

      # interface = [ "enp86s0" ];
      # bind-interface = "true";

      # Forward everything else to your ISP or preferred DNS
      server = [
        #"192.168.1.1"
        #"8.8.8.8"

        # Tailnet names exist only inside the tailnet -- public resolvers
        # NXDOMAIN them -- so hand that one zone to tailscaled's MagicDNS
        # resolver. Delegated rather than copied into `address` below because
        # the node list belongs to Tailscale's coordination server and changes
        # as devices join or re-auth; a copy would go stale silently.
        # Update this suffix if the tailnet is ever renamed again.
        "/magpie-kochab.ts.net/100.100.100.100"

        "9.9.9.9"
      ];

      # Reverse lookups for the tailnet's 100.64.0.0/10 range, so a 100.x
      # address maps back to a node name instead of hanging.
      rev-server = "100.64.0.0/10,100.100.100.100";

      # This resolver serves the whole house, but dnsmasq's defaults are sized
      # for one machine: a 150-entry cache and 150 in-flight forwarded queries.
      # Exhausting the latter makes dnsmasq *drop* queries rather than queue
      # them, which is what produced 358 "Maximum number of concurrent DNS
      # queries reached" in 7 days and put "DNS unavailable" health warnings on
      # every Tailscale node -- they all forward here. Upstream was healthy
      # throughout, so this is volume, not a slow server.
      cache-size = 10000;
      dns-forward-max = 1000;

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
