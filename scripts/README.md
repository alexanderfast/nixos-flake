# Rebuild-and-verify loop for `nuc`

Two scripts plus one NixOS module that let a rebuild be attempted unattended
and reverted automatically if the box does not come back healthy.

| file | role | privilege |
|---|---|---|
| `nuc-verify` | 24 read-only health checks; decides "is the box working" | none |
| `nuc-rebuild` | build → arm watchdog → test → verify → switch or revert | root |
| `../modules/nuc-rebuild-sudo.nix` | NOPASSWD sudo for the wrapper only | — |

The scripts are deployed to `/usr/local/bin` **root-owned**, and these copies are
the reviewable source. Promoting a change is an explicit `install` command, so a
change to the repo does not silently change what runs as root.

## Why it is shaped this way

The nuc serves household DNS (dnsmasq), home automation (openHAB) and media
(Jellyfin), so a bad activation affects people other than the operator.

It can also remove the access needed to undo itself, but **not via SSH**. The
agent that drives this loop is a `claude rc` process in a detached tmux session
on the nuc, reached from the desktop app through Anthropic's servers. Its
dependency chain is:

```
claude.exe  in  user.slice/user-1000.slice/user@1000.service/tmux-spawn-….scope
   ├── resolves api.anthropic.com via dnsmasq on 127.0.0.1
   └── outbound tcp/443
```

Three consequences:

* **dnsmasq is inside the control path.** The box's own DNS server is one of the
  services under management, so breaking it severs the agent's ability to
  reconnect and therefore to revert.
* **`user@1000.service` is inside the control path.** If an activation restarts
  it, the agent session dies and does **not** come back by itself — someone has
  to start `claude rc` on the nuc again. Note `home-manager/base.nix` sets
  `systemd.user.startServices = "sd-switch"`, so user units are touched on switch.
* **sshd is not the agent's lifeline.** It remains the *operator's* recovery path
  from the desktop, which is why it is still asserted, but breaking it does not
  cut the agent off.

Because the agent's own recovery is less automatic than an SSH session's — a
dropped SSH can simply be redialled, a dead tmux scope cannot — the dead-man's
switch matters more here, not less.

So `nuc-rebuild` never activates without first arming a **dead-man's switch**: a
transient systemd timer, owned by PID 1 and independent of the calling session,
that restores the previous generation if the script dies, hangs, or the box stops
responding.
Activation is done with `nixos-rebuild test`, which does **not** touch the boot
default, so the previous generation stays the one that boots until verification
has passed.

Recovery does not rely on rebooting. That matters here: uptime is over 100 days
and the boot path is unproven — `/mnt/sda` is still mounted by `/dev/sda` rather
than by UUID (see the NUC board, card #5).

## Install

1. **Review both scripts.** They run as root; read them rather than trusting this
   README.

2. **Install them root-owned.** `/usr/local` does not exist on NixOS yet; creating
   it as root is what keeps `alex` from being able to rewrite the wrapper.

   ```bash
   sudo install -d -m 0755 -o root -g root /usr/local/bin
   sudo install -m 0755 -o root -g root scripts/nuc-verify  /usr/local/bin/nuc-verify
   sudo install -m 0755 -o root -g root scripts/nuc-rebuild /usr/local/bin/nuc-rebuild
   ```

3. **Record the journal baseline.** Without this, `nuc-verify` fails on the
   baseline check by design (fail-closed rather than silently skipping).

   ```bash
   sudo /usr/local/bin/nuc-verify --update-baseline
   ```

   This accepts the ~100 current error signatures — mostly `podman-openhab`
   writing ordinary shell trace to stderr, which journald tags as `err`. Re-run
   it whenever a change legitimately introduces new error output.

4. **Enable the sudo rule.** Add to the `imports` list in `nixos/nuc.nix`:

   ```nix
   ../modules/nuc-rebuild-sudo.nix
   ```

   then do one manual, password-required rebuild:

   ```bash
   sudo nixos-rebuild switch --flake '.#nuc'
   ```

5. **Confirm.** Should print the plan and exit 0 without prompting for a password:

   ```bash
   sudo -n /usr/local/bin/nuc-rebuild --dry-run
   ```

## Use

```bash
sudo -n nuc-rebuild                 # build, test, verify, switch if green
sudo -n nuc-rebuild --dry-run       # build + verify only, never activates
sudo -n nuc-rebuild --watchdog 20   # longer auto-revert deadline
nuc-verify                          # health check on demand, no privilege
nuc-verify --since '5 min ago'      # only consider recent journal entries
```

Every run appends to `/var/log/nuc-rebuild.log`.

## Recovery ladder

If a rebuild goes wrong, in order:

1. **Do nothing for `--watchdog` minutes.** The timer is a transient systemd unit
   and does not depend on the agent, the tmux session, or any network path. It
   restores the previous generation on its own. Confirm it is armed with
   `systemctl list-timers nuc-rebuild-watchdog.timer`.
2. **SSH in from the desktop** and revert by hand:
   `sudo nixos-rebuild switch --rollback`. This is the operator's path, and it
   works even when the agent is cut off.
3. **Tailscale**, if the LAN path is broken but the tailnet is up — this is why
   `nuc-verify` asserts `BackendState=Running`, so the out-of-band path is known
   good *before* anything is activated.
4. **Physical console.** The boot default is only changed after verification
   passes, so a power-cycle returns to the last known-good generation.

If the agent goes silent but the box is healthy, the likely cause is
`user@1000.service` or the tmux scope being restarted. Nothing auto-recovers
that: SSH in and start `claude rc` again.

## Threat model, stated plainly

The NOPASSWD rule is **not** a security boundary against deliberate misuse:
`nuc-rebuild` activates a flake that `alex` can edit, and activation runs
arbitrary scripts as root. It constrains *accidents* and forces every activation
through one audited path.

It also grants no new capability: `alex` is in `wheel`, which the generated
sudoers already gives `ALL=(ALL:ALL) SETENV: ALL`. The rule removes a password
prompt for one command; it does not widen what is reachable.

The controls that actually matter are that the flake is git-tracked and
reviewable, the wrapper is fixed and root-owned, and every run is logged.

## Recommended prerequisite

Card #6 on the NUC board — no SSH keys are declared in the flake while
`PasswordAuthentication = false`, so authorised keys are un-versioned local
state. This is not the agent's lifeline, but it *is* recovery step 2 above, so
it is worth making reproducible before leaning on unattended rebuilds.

## What `nuc-verify` checks

1. `systemctl is-system-running` is `running`
2. no failed units
3. these are active: `sshd`, `NetworkManager`, `dnsmasq`, `jellyfin`,
   `qbittorrent`, `tailscaled`, `podman-openhab`
4. TCP 22, 53, 8080, 8081, 8096 are listening
5. UDP 53 is listening
6. `nuc.lan` resolves to `192.168.1.101` via `127.0.0.1` (dnsmasq authoritative)
7. an external name resolves via `127.0.0.1` (upstream forwarding works)
8. `/mnt/sda` is a mountpoint and is readable
9. the journal is readable and emits parseable JSON
10. no journal error *signatures* absent from the baseline (numbers, hex, UUIDs
    and store hashes are normalised, so varying values are not false positives)
11. sshd accepts a TCP connection
12. `tailscale status` reports `BackendState=Running`
13. the agent control path works: `api.anthropic.com` resolves via dnsmasq and
    accepts a tcp/443 connection (fail-closed by design)
14. `user@1000.service` is active -- the slice the agent session lives in

Verified to have teeth: requiring a nonexistent unit, an unlistened port, a
wrong DNS answer, and an injected `logger -p user.err` entry were each caught.
