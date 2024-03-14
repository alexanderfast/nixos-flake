{ config, pkgs, ... }:

{
  imports = [ ../../home-base.nix ../../home-desktop.nix ];

  # Ctrl-q 	Quit application
  # Ctrl-s 	Start download. Runs hash first unless already done.
  # Ctrl-d 	Stop an active download or remove a stopped download
  # Ctrl-k 	Stop and close the files of an active download.
  # Ctrl-r 	Initiate hash check of torrent. Starts downloading if file is not available.
  # Ctrl-o 	Specify the download directory for a added, but not started torrent.
  # Left 	Returns to the previous screen
  # Right 	Goes to the next screen
  # Backspace 	Adds and starts the specified *.torrent
  # Return 	Adds and does not start the specified *.torrent
  # a|s|d 	Increase global upload throttle about 1|5|50 KB/s
  # A|S|D 	Increase global download throttle about 1|5|50 KB/s
  # z|x|c 	Decrease global upload throttle about 1|5|50 KB/s
  # Z|X|C 	Decrease global download throttle about 1|5|50 KB/s
  programs.rtorrent = {
    enable = true;

    extraConfig = ''
      # https://wiki.archlinux.org/title/RTorrent
      throttle.min_peers.normal.set = 40
      throttle.max_peers.normal.set = 52

      throttle.min_peers.seed.set = 10
      throttle.max_peers.seed.set = 52

      throttle.max_uploads.set = 8

      throttle.global_down.max_rate.set = 200
      throttle.global_up.max_rate.set = 28

      pieces.hash.on_completion.set = yes

      directory.default.set = ~/torrents

      session.path.set = ~/.rtorrent.session

      # automatically starts torrents in the watch folder
      schedule2 = watch_directory,5,5,load.start=/home/alex/torrent_watch/*.torrent
      schedule2 = untied_directory,5,5,stop_untied=
      schedule2 = tied_directory,5,5,start_tied=

      schedule2 = low_diskspace,5,60,((close_low_diskspace,100M))

      network.port_range.set = 49164-49164

      #protocol.encryption.set = allow_incoming,try_outgoing,enable_retry
      protocol.encryption.set = require,require_RC4,allow_incoming,try_outgoing
    '';
  };
}
