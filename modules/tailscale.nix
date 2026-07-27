{ config, lib, pkgs, ... }:
{
  # Tailscale: WireGuard-based mesh VPN for secure remote access to this host
  # (and the services running on it, e.g. openHAB) with NO ports forwarded to
  # the internet. Reach the box at its tailnet 100.x IP / MagicDNS name, which
  # never overlaps the 192.168.1.0/24 LAN -- so it behaves identically whether
  # you are home or away (this is what fixed the old full-tunnel WG confusion).
  services.tailscale = {
    enable = true;
    # Enable kernel IP forwarding so this host *can* act as a subnet router or
    # exit node if we later advertise routes. Harmless for plain client use.
    useRoutingFeatures = "server";
  };

  # Let authenticated tailnet peers reach local services through the firewall,
  # and open the UDP port Tailscale uses for direct (non-relayed) connections.
  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
}
