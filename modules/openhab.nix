{ config, pkgs, ... }:
{
  users.groups = {
    openhab = { gid = 9001; };
    zwave = { };
  };

  users.users.openhab = {
    uid = 9001;
    isNormalUser = true;
    description = "openhab";
    extraGroups = [ "openhab" "zwave" ];
  };

  systemd.tmpfiles.rules = [
    "d /srv/openhab/conf     0777 openhab openhab"
    "d /srv/openhab/userdata 0777 openhab openhab"
    "d /srv/openhab/addons   0777 openhab openhab"
    # "d /srv/openhab/.java    0777 openhab openhab"
  ];

  networking.firewall = {
    allowedTCPPorts = [ 3000 8080 8091 ];
  };

  # Bus 001 Device 011: ID 0658:0200 Sigma Designs, Inc. Aeotec Z-Stick Gen5 (ZW090) - UZB
  services.udev.extraRules = ''
    SUBSYSTEM=="tty", KERNEL=="ttyACM[0-9]*", \
    ATTRS{idProduct}=="0002", \
    ATTRS{idVendor}=="1d6b", \
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
