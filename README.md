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
