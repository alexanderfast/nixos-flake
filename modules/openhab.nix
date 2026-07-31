{ config, pkgs, ... }:
{
  users.groups = {
    openhab = { gid = 9001; };
    zwave = { };
  };

  # uid 9001 must stay: it is the uid the openhab/openhab image runs its JVM as,
  # and the bind mounts below are owned by it. A service account for a container
  # needs no login shell or home, hence isSystemUser.
  #
  # /home/openhab was already created by the earlier isNormalUser declaration and
  # is NOT removed by this change -- NixOS never deletes home directories. It is
  # inert (nothing in the flake references it, and the container has its own mount
  # namespace so it cannot see it), but it is still there to be cleaned up by hand.
  users.users.openhab = {
    uid = 9001;
    isSystemUser = true;
    group = "openhab";
    description = "openhab";
    extraGroups = [ "zwave" ];
  };

  # 0770, not 0777: the container's JVM runs as uid 9001 = openhab, so owner
  # permissions are sufficient and world-write was never needed.
  #
  # The parent is declared too because it had drifted to uid 1001 -- a uid that no
  # longer exists on this system -- with mode 0774. Nothing runs as 1001, and the
  # container is unaffected either way since podman resolves the bind mounts as
  # root before dropping privileges, so the container never traverses this path.
  systemd.tmpfiles.rules = [
    "d /srv/openhab          0750 openhab openhab"
    "d /srv/openhab/conf     0770 openhab openhab"
    "d /srv/openhab/userdata 0770 openhab openhab"
    "d /srv/openhab/addons   0770 openhab openhab"
  ];

  # 3000 and 8091 were opened for the zwave-js-ui container that is commented out
  # below, so they were surface for nothing -- confirmed with `ss`: unbound.
  #
  # 8080 is deliberately still open on the LAN, but note it is only partly
  # authenticated: /rest/things and /rest/inbox return 401 while /rest/items
  # returns 200 and leaks live item state. See the "[C] openHAB firewall" card.
  networking.firewall = {
    allowedTCPPorts = [ 8080 ];
  };

  # Bus 001 Device 011: ID 0658:0200 Sigma Designs, Inc. Aeotec Z-Stick Gen5 (ZW090) - UZB
  #
  # These ATTRS must be the stick's own ids. They were 1d6b:0002 -- the xHCI root
  # hub the stick hangs off, not the stick -- so the rule matched any ttyACM device
  # on that controller. A second CDC-ACM device would also have claimed SYMLINK
  # "zwave" (priority 0, so the winner was undefined) and been given MODE 0666.
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", KERNEL=="ttyACM[0-9]*", \
    ATTRS{idVendor}=="0658", \
    ATTRS{idProduct}=="0200", \
    MODE="0666", GROUP="zwave", SYMLINK+="zwave"
  '';

  virtualisation.podman.enable = true;
  # virtualisation.docker.enable = true;
  virtualisation.oci-containers = {
    backend = "podman";

    containers.openhab = {
      image = "openhab/openhab:5.0.1";
      autoStart = true; # equivalent to restart: unless-stopped

      # Expose ports
      # ports = [ "8080:8080" ];

      # Devices to pass through
      extraOptions = [
        "--device=/dev/zwave:/dev/zwave"
        "--group-add=tty" # adds container to tty group
        # "--group-add=zwave"
        "--network=host" # uncomment if you want host networking instead of port mapping
      ];

      # Mount volumes
      volumes = [
        "/etc/localtime:/etc/localtime:ro"
        # "openhab_addons:/openhab/addons"
        # "openhab_conf:/openhab/conf"
        # "openhab_userdata:/openhab/userdata"
        "/srv/openhab/addons:/openhab/addons"
        "/srv/openhab/conf:/openhab/conf"
        "/srv/openhab/userdata:/openhab/userdata"
      ];
    };
  };
  
  # systemd.services.openhab = {
  #   #enable = true;
  #   serviceConfig = {
  #     Restart = "always";
  #     ExecStart = ''
  #       docker run --name=%n --net=host \
  #       -v /etc/localtime:/etc/localtime:ro \
  #       -v /srv/openhab/conf:/openhab/conf \
  #       -v /srv/openhab/userdata:/openhab/userdata \
  #       -v /srv/openhab/addons:/openhab/addons \
  #       -v /srv/openhab/.java:/openhab/.java \
  #       --device=/dev/serial/by-id/usb-0658_0200-if00 \
  #       -e USER_ID=9001 \
  #       -e GROUP_ID=9001 \
  #       -e CRYPTO_POLICY=unlimited \
  #       openhab/openhab:5.0.1
  #       '';
  #     ExecStop = "docker stop -t 2 %n ; docker rm -f %n";
  #   };
  # };

}
