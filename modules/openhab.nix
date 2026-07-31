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
  # ACCEPTED RISK -- deliberate, do not "fix" this in a panic later.
  # 8080 is open on the LAN and openHAB's REST API is only partly authenticated:
  # /rest/things and /rest/inbox return 401, but /rest/ and /rest/items return
  # 200 to an unauthenticated caller and leak live item state -- Z-Wave sensor
  # readings and light/dimmer states, named per device. So anything on the home
  # network can enumerate what the house has and what it is doing right now.
  # (Only the read path was tested; whether item *commands* are equally open was
  # deliberately not probed, because doing so actuates real hardware. Assume it
  # may be until someone checks.)
  #
  # We accept that for the same reason as qBittorrent on 8081: trusted home LAN,
  # and the router does not forward ports. See the ACCEPTED RISK note above
  # `services.qbittorrent` in nixos/nuc.nix.
  #
  # If this should change, the knob is to drop 8080 from this list. That closes
  # the LAN only -- tailscale0 is a trusted interface, so it stays reachable over
  # Tailscale, which is the intended resting place for something like this. Do
  # NOT instead bind openHAB to 127.0.0.1: that locks out the tailnet too. The
  # "Network exposure on nuc" section of README.md works this through.
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

      # The JVM does not take its zone from the bind-mounted /etc/localtime
      # below, so without this openhab.log is written in UTC while the host runs
      # CEST -- log lines look two hours older than the journal entries you are
      # comparing them against. Sourced from time.timeZone so it cannot drift.
      environment.TZ = config.time.timeZone;

      # Expose ports
      # ports = [ "8080:8080" ];

      # Devices to pass through
      extraOptions = [
        "--device=/dev/zwave:/dev/zwave"
        "--group-add=tty" # adds container to tty group

        # The image ships a HEALTHCHECK, and podman registers a transient
        # timer+service per container to run it. On recreation that timer fires
        # within ~2s, while the JVM is still booting: the probe reports
        # health_status=starting and `podman healthcheck run` exits 1, the
        # transient unit fails, and switch-to-configuration counts ANY failed
        # unit and exits 4. So every change that recreates this container had a
        # race against openHAB's own startup, and losing it aborted activation
        # and rolled the whole generation back -- see the 2026-07-31 22:54 run.
        #
        # Dropping the healthcheck rather than teaching nuc-rebuild to ignore
        # those units, deliberately: nothing consumes the health status (no
        # --health-on-failure action is set), and nuc-verify already proves
        # liveness better by requiring podman-openhab.service active AND 8080
        # listening. The alternative would mean loosening the revert path, which
        # should keep treating a failed unit as a failure.
        "--no-healthcheck"
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
