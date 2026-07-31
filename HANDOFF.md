# Session handoff — 2026-07-31

Transient session state for resuming work after a reboot. **Not** a findings list —
those live on the Trello NUC list. Delete this file once the reboot is done and
work has resumed.

## Resuming the conversation

`claude rc` (Remote Control, what the desktop app drives) has **no `--resume`
flag** — it only spawns fresh sessions. Top-level `claude` does. So:

| Want | Do this |
|---|---|
| **Full conversation context** | SSH in, then `cd ~/flake && claude --resume a6931a77-8641-4050-99fe-dc8e6cd77f62` |
| Pick from a list | `cd ~/flake && claude --resume` (interactive picker) |
| Most recent in this dir | `cd ~/flake && claude -c` |
| **Remote/desktop again** | `tmux new -s claude` then `claude rc`, and tell the fresh session to read this file |

The transcript is at
`~/.claude/projects/-home-alex-flake/a6931a77-8641-4050-99fe-dc8e6cd77f62.jsonl`
(3.4 MB, 1203 lines) on **ext4 `/`** — it survives the reboot. `/tmp/claude-1000`
holds only task outputs and bundled skills; losing it costs nothing.

## Where things stand

**Live on generation 162** (activated, verified with `nuc-verify`: 24/24 pass):

- SSH public key declared in the flake (recovery path proven by moving
  `~/.ssh/authorized_keys` aside and authenticating anyway)
- `programs.nix-ld` enabled
- `nix.gc` + `nix.optimise` armed — **`nix-gc.timer` first fires Mon 2026-08-03
  00:00**, and will delete ~155 generations older than 30d
- claude-code from the flake at 2.1.140 via the `nixpkgs-claude` bridge; both npm
  installs removed; patchelf chore retired
- qBittorrent LAN exposure documented as an accepted risk
- Rebuild-and-verify loop installed at `/usr/local/bin/{nuc-verify,nuc-rebuild}`

**Committed but NOT pushed:** 27 commits ahead of `origin/main`. This is the
biggest gap in the current state — see below.

## Before rebooting

1. **Fix card #5 first — `/mnt/sda` is mounted by `/dev/sda`, not by UUID.**
   `hosts/nuc/hardware.nix:31`. The correct value is
   `/dev/disk/by-uuid/6859dffe-ab1f-4453-abfa-52896857b22a`. Enumeration can shift
   across a reboot, and `services.btrfs.autoScrub` would then scrub whatever
   landed there. This is the one genuinely reboot-shaped risk still open.
2. **Push the 27 commits.** They exist only on this disk. Everything else here is
   recoverable; unpushed history is not.
3. Optional: `nix flake check` still fails on the `plasma5` assertion in
   `modules/home-xfce4-i3.nix` (card #2, affects `work`/`laptop` only).

## What the reboot itself will change

**A kernel jump is already pending, independent of any config change:**

```
running:            6.12.55     (booted 2026-04-18, 103 days ago)
current-system has: 6.12.81
booted-system has:  6.12.55
```

So the reboot moves 6.12.55 → 6.12.81. Boot readiness checked: `grub.cfg` was
regenerated at 10:20:14 and lists `Configuration 162`; `/boot` has 203 MB free of
511 MB; the 6.12.81 kernel is referenced 11 times.

Recovery if boot fails needs **physical access** — GRUB's menu has 100
generations, so an older one is selectable.

## After rebooting

1. `/usr/local/bin/nuc-verify` — **expect it to fail the journal check.** The
   baseline was recorded against a 103-day-old boot, so a fresh boot produces
   startup messages that look like new error signatures. Confirm the box is
   genuinely healthy, then re-baseline:
   `sudo /usr/local/bin/nuc-verify --update-baseline`
2. Confirm the kernel moved: `uname -r` should read 6.12.81.
3. Confirm `/mnt/sda` mounted the intended disk (especially if card #5 is still
   open): `findmnt /mnt/sda` and check the UUID.
4. Restart the agent: `tmux new -s claude` then `claude rc` — nothing
   auto-recovers the session.
5. `claude --version` should print 2.1.140 from
   `/etc/profiles/per-user/alex/bin/claude` (npm copy is gone).

## Next work items (detail on Trello)

- Card #5 — mount `/mnt/sda` by UUID **(do before rebooting)**
- Card #2 — `plasma5` removal breaks `work`/`laptop` eval; unblocks `nix flake check`
- Card [KrJLZhyA] — retire the `nixpkgs-claude` bridge once the main nixpkgs is updated
- Tier 2 leftovers: cards #15, #16, #17, #18, #19, #24 — all no-op-class, safe for
  `nuc-rebuild --detach`
