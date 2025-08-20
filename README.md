# env-sync
Environment manager and sync (multi-machine, cross-OS)

Purpose: keep working environments consistent and reproducible across machines.
See docs in /docs and profiles in /profiles.

Bootstrap:
  ./bootstrap.sh --dry-run
  ./bootstrap.sh        # apply (if required)

Register:
  ./scripts/register.sh --id "laptop-2025" --os "macos" --profile "web-dev"
