# Grant alex password-less sudo for the rebuild wrapper ONLY.
#
# This exists so an agent (or a script, or you when half-awake) can run the
# vetted build -> test -> verify -> switch-or-revert sequence without a
# password, while still not having blanket root.
#
# NOT imported by default. Add to nixos/nuc.nix imports to enable:
#     ../modules/nuc-rebuild-sudo.nix
#
# Why the rule is declarative rather than a file in /etc/sudoers.d:
# the NixOS sudo module does not emit an `#includedir /etc/sudoers.d`
# directive, so drop-in files there are never read. It has to live here.
#
# READ THIS BEFORE ENABLING -- the honest threat model:
#   * /usr/local/bin/nuc-rebuild must be root-owned and not writable by alex,
#     or this rule is a trivial root escalation. Install it with
#     `install -m 0755 -o root -g root`, and never chown it to alex.
#   * This rule is NOT a security boundary against a deliberate actor. The
#     wrapper activates a flake that alex can edit, and activation runs
#     arbitrary activation scripts as root -- including a rule that grants
#     broader sudo. It limits *accidents* and makes every activation follow the
#     same audited path; it does not contain intent.
#   * The real controls are: the flake is git-tracked and reviewable, the
#     wrapper is fixed and root-owned, and every run is logged to
#     /var/log/nuc-rebuild.log.
{ ... }:
{
  security.sudo.extraRules = [
    {
      users = [ "alex" ];
      commands = [
        {
          command = "/usr/local/bin/nuc-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
