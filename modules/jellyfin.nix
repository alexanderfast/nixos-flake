{ config, pkgs, ... }:
{
  services.jellyfin = {
    enable = true;
    openFirewall = true;

    # Point Jellyfin at a known working ffmpeg binary from Nixpkgs
    package = pkgs.jellyfin;
  };

  users.users.jellyfin.extraGroups = [ "render" ];

  systemd.services.jellyfin.environment = {
    JELLYFIN_FFMPEG = "${pkgs.ffmpeg}/bin/ffmpeg";
    LIBVA_DRIVER_NAME = "iHD";
    LIBVA_DRIVERS_PATH = "/run/opengl-driver/lib/dri";
    # Optional: sometimes helps on headless systems
    DISPLAY = ":0";
  };

  environment.systemPackages = with pkgs; [
    intel-media-driver
    libva-utils
  ];

  hardware.graphics = {
    enable = true;

    extraPackages = with pkgs; [
      intel-media-driver
      libva-utils
    ];
  };
}
