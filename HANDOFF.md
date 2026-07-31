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

**Pushed:** `origin/main` is in sync at `ec7058b` — all 28 commits are on GitHub.

## Before rebooting

1. **ACTIVATE — this is the blocking step.** Card #5 is *committed* (`ec7058b`,
   `/mnt/sda` now mounted by UUID) but **not live**. The running `/etc/fstab`
   still reads `/dev/sda`. Rebooting without activating means the fix does not
   apply and the risk it removes is still present:

   ```bash
   cd ~/flake && sudo nixos-rebuild switch --flake '.#nuc'
   grep /mnt/sda /etc/fstab      # must show by-uuid/6859dffe-... before you reboot
   ```

   Note this creates a new generation and regenerates `grub.cfg`; re-check that
   the newest `Configuration N` entry matches the new generation afterwards.
2. Optional: `nix flake check` still fails on the `plasma5` assertion in
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

### ⚠️ Expect `nuc-verify` to FAIL its journal check. This is not a regression.

The journal baseline was recorded against a boot that was 103 days old, so it
contains none of the messages a *fresh* boot emits. Every startup message will
therefore look like a new error signature, and check 10 will fail — while the
other 23 pass. Read it as "the baseline is stale", not "the reboot broke
something".

```bash
/usr/local/bin/nuc-verify                              # expect: FAIL (1 failed, 23 passed)
#   -> confirm the failure is ONLY "new journal error signatures"
#   -> confirm the listed signatures are boot-time noise, not real faults
sudo /usr/local/bin/nuc-verify --update-baseline        # accept the new boot's baseline
/usr/local/bin/nuc-verify                              # now expect: PASS (24 checks)
```

Do **not** re-baseline before reading what the new signatures are — that is the
one step that would hide a genuine post-reboot fault. Note the sudo/PAM ignore
list only covers auth noise; boot messages are not ignored by design.

Also expect the `[C] qBittorrent` WebUI to have generated a *new* temporary
password into the journal (`journalctl -u qbittorrent`), since no password is
persisted — see the ACCEPTED RISK comment in `nixos/nuc.nix`.

### Then, in order

1. Confirm the kernel moved: `uname -r` should read **6.12.81** (was 6.12.55).
2. Confirm `/mnt/sda` mounted the *intended* disk:
   `findmnt -no SOURCE,UUID /mnt/sda` → UUID must be
   `6859dffe-ab1f-4453-abfa-52896857b22a`. This is the whole point of card #5.
3. Confirm `current-system == booted-system` now:
   `[ "$(readlink -f /run/current-system)" = "$(readlink -f /run/booted-system)" ]`
4. Restart the agent: `tmux new -s claude` then `claude rc` — **nothing
   auto-recovers the session.**
5. `claude --version` should print **2.1.140** from
   `/etc/profiles/per-user/alex/bin/claude` (npm copy is gone).
6. Check no watchdog was left armed from a `nuc-rebuild` run:
   `systemctl list-timers 'nuc-rebuild*'` should be empty.
7. `nix-gc.timer` — confirm it is still scheduled for Mon 2026-08-03 and did not
   fire early: `systemctl list-timers 'nix-*'`.

## Next work items (detail on Trello)

- Card #2 — `plasma5` removal breaks `work`/`laptop` eval; unblocks `nix flake check`
- Card [KrJLZhyA] — retire the `nixpkgs-claude` bridge once the main nixpkgs is updated
- Tier 2 leftovers: cards #15, #16, #17, #18, #19, #24 — all no-op-class, safe for
  `nuc-rebuild --detach`
