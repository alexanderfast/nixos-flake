# README

My Nix OS flake.

### Cheat sheet

Common commands

```
nix flake update nixpkgs home-manager
sudo nixos-rebuild switch --flake '.#nuc'
```

home-manager is wired in as a NixOS module (see `home-manager.users.alex`
in `flake.nix`), so there is no separate `home-manager switch` step and no
`homeConfigurations` output -- `nixos-rebuild switch` applies both.

To check a change without activating it:

```
nix flake check
nixos-rebuild build --flake '.#nuc'   # builds ./result, activates nothing
```

## The Z-Wave stick and openHAB — how the device reaches the container

Home automation depends on this chain. Every link is load-bearing and two of them
are easy to break by "tidying up", so the whole path is written out here.

```
Aeotec Z-Stick Gen5 (ZW090)      USB 0658:0200, plugged into port 3-3
  └─ kernel enumerates it        /dev/ttyACM0        ← number is NOT stable
      └─ udev rule               modules/openhab.nix → /etc/udev/rules.d/99-local.rules
          ├─ SYMLINK+="zwave"    /dev/zwave -> ttyACM0   ← the stable name
          ├─ GROUP="zwave"       group 987
          └─ MODE="0666"
              └─ podman          --device=/dev/zwave:/dev/zwave  (extraOptions)
                  └─ openHAB     Z-Wave binding opens the serial port
```

**Why the symlink exists.** `ttyACM` numbering depends on enumeration order, so
`/dev/ttyACM0` is not a name anything should be configured against. The udev rule
mints `/dev/zwave` as a stable alias, and that is what podman is pointed at.

**The ATTRS must be the stick's own ids, not the hub's.** `ATTRS{}` walks *up* the
parent chain, so a rule can match an ancestor and still fire. Until `f23b675` the
rule matched `1d6b:0002` — the xHCI root hub (`usb3`) that the stick hangs off, not
the stick (`0658:0200`, at `3-3`). It worked, but it meant "any `ttyACM` device on
that controller": a second CDC-ACM device (Arduino, printer, UPS) would also have
claimed `SYMLINK+="zwave"` at priority 0, where the winner is undefined, and been
given `MODE="0666"`. Verify which parent a rule actually matches with:

```
udevadm info -a -n /dev/ttyACM0 | grep -E 'looking at|idVendor|idProduct'
```

**`MODE="0666"` is probably load-bearing — do not tighten it casually.** The device
is `root:zwave`, but `--group-add=zwave` is commented out in the container's
`extraOptions` (it only gets `tty`), so the host `zwave` group does not help the
uid inside the namespace. World-writable may be the only thing granting openHAB
access. Fixing the group membership and tightening the mode is one change, not two,
and it can take out home automation.

**The device is resolved at container start, not continuously.** Two consequences,
both useful:

* A missing or wrong `/dev/zwave` makes `podman-openhab.service` **fail at
  startup** — so a clean start with `NRestarts=0` is real evidence the symlink
  resolved.
* A running container holds its open fd, so changing the udev rule does not
  disturb it. Activation alone proves nothing; you must re-run the rules.

**Verifying a change to the rule**, in the order that keeps openHAB safe:

```
udevadm test /sys/class/tty/ttyACM0 2>&1 | grep 99-local   # dry run, no side effects
sudo udevadm trigger /dev/zwave                            # re-runs rules like a replug
ls -l /dev/zwave && stat -L -c '%a %U:%G' /dev/zwave        # expect 666 root:zwave
sudo systemctl restart podman-openhab.service              # only once the above is green
sudo grep -i zwave /srv/openhab/userdata/logs/openhab.log | tail
```

Expect `Starting ZWave controller`, then traffic from real nodes. Frames arriving
from a node prove the stick is *talking*, not merely present.

Two traps when reading that log:

* **It is in UTC while the host is CEST**, despite `/etc/localtime` being
  bind-mounted — so timestamps look two hours behind. Convert before concluding a
  log line predates a restart.
* **`/srv/openhab/userdata/logs/` is container-owned and needs `sudo`.** The `0777`
  from `systemd.tmpfiles.rules` applies to the parent directory only; `logs/` was
  created by the container.

**`stat /dev/zwave` reports `777`, and that is normal.** It is the symlink's own
mode, which Linux always reports as `lrwxrwxrwx` and never enforces. Use
`stat -L` to see the device the access check actually uses.

Note there is also `/dev/serial/by-id/usb-0658_0200-if00`, created by udev's own
`60-serial.rules`, which is already unique and stable and needs no custom rule.
`docker-compose.yml` uses that form. The custom rule is still what sets the mode
and group, which is why it has not simply been replaced by the `by-id` path.

## Network exposure on nuc — three zones, not two

There are three ways to reach a service on the nuc, and they are governed by
different things. This trips people up, so:

| zone | address | governed by |
|---|---|---|
| localhost | `127.0.0.1` (`lo`) | always allowed — `lo` is a trusted interface |
| LAN | `192.168.1.101` (`enp86s0`) | `networking.firewall.allowedTCPPorts` / `openFirewall` |
| tailnet | `100.89.199.23` (`tailscale0`) | always allowed — `tailscale0` is a trusted interface |

`modules/tailscale.nix` sets `networking.firewall.trustedInterfaces =
[ "tailscale0" ]` (and `lo` is trusted by default). **All traffic on a trusted
interface is accepted regardless of the port rules.** So `allowedTCPPorts` and
every `openFirewall = true` only ever govern the LAN interface.

Two consequences that are easy to get backwards:

| change | LAN | tailnet | localhost |
|---|---|---|---|
| *(current: `openFirewall = true`)* | open | open | open |
| `openFirewall = false` | **blocked** | open | open |
| `Address = "127.0.0.1"` | blocked | **also blocked** | open |

* **`openFirewall = false` does NOT hide a service from you when you are away.**
  It closes the LAN only; the tailnet still reaches it. This is the useful knob.
* **Binding a service to `127.0.0.1` DOES hide it from the tailnet.** Tailnet
  traffic arrives on `tailscale0` at `100.89.199.23`, not on loopback, so
  loopback-only binding locks out Tailscale as well and leaves you needing an
  SSH port-forward. Usually not what you want.

### The intended policy

Services should be **open on the LAN, open on the tailnet, and always open from
localhost**. The tailnet is meant to behave exactly like being at home, so that
reachability does not change depending on whether you are in the house — that is
the whole reason Tailscale is here rather than a full-tunnel WireGuard setup (see
the comment in `modules/tailscale.nix`).

All three zones are generally open, but they are **not equally trusted**:

```
localhost  >  tailnet  >  LAN          (most trusted to least)
```

* **localhost** — requires a shell on the box already.
* **tailnet** — every peer is a device you explicitly enrolled and authenticated
  with Tailscale. Nothing joins by accident.
* **LAN** — admits anything that gets onto the home network: a guest's phone, a
  smart TV, an IoT gadget with poor firmware. Least trusted of the three despite
  feeling the most "inside".

The practical consequence: when something should not be fully open, move it *up*
the gradient rather than closing it outright. Tailnet-only is a legitimate resting
place, not a half-measure — so a service that answers over Tailscale but not the
LAN is correctly configured, not broken. openHAB's 8443 and 5007 are in exactly
that state, and only need changing if LAN convenience is wanted.

Corollary: a service with weak or default credentials belongs at localhost or
tailnet, never on the LAN. openHAB's Karaf console (8101) is the example — it
ships with well-known default credentials and is bound to `127.0.0.1`; leave it
there.

In practice that means `openFirewall = true` / listing the port in
`allowedTCPPorts` is the normal, intended state, and LAN exposure of a service is
a deliberate choice rather than an oversight. See the `ACCEPTED RISK` note above
`services.qbittorrent` in `nixos/nuc.nix` for a worked example.

It does **not** mean every port should be listed: only ports something actually
listens on. `modules/openhab.nix` opens 3000 and 8091 for a `zwave-js-ui`
container that is commented out, which is surface for nothing.

Given that policy, a listed port is open in all three zones at once — so for
those the three-zone distinction collapses and "open everywhere" is simply true.
What still differs:

* **Unlisted ports are LAN-refused but tailnet-reachable.** Currently openHAB's
  HTTPS (8443) and its LSP (5007) bind to `*` but are not in `allowedTCPPorts`,
  so they answer over Tailscale and not from the LAN. If they should follow the
  policy, list them.
* **The bind address is a separate gate the firewall cannot override.** 8101
  (openHAB Karaf console) and 631 (CUPS) bind to `127.0.0.1`, so they are
  localhost-only regardless of `allowedTCPPorts`.
* **The internet is excluded by the router not forwarding ports**, not by any of
  this.

### Do not test LAN blocking from the nuc itself

Connecting to `192.168.1.101` *from* the nuc goes over `lo`, not `enp86s0`,
because Linux routes traffic for a local address through loopback — and `lo` is
trusted, so everything answers. That makes it look like the firewall is open when
it is not. Test from another machine, or read the rules directly:

```
grep -E 'dport|-i (lo|tailscale0)' \
  $(grep -oE '/nix/store/\S*firewall-start\S*' /etc/systemd/system/firewall.service)
```
