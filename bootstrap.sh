#!/usr/bin/env bash
set -euo pipefail
DRY_RUN=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1; shift ;;
    --id) ID="$2"; shift 2 ;;
    *) shift ;;
  esac
done

echo "env-sync bootstrap"
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
echo "detected os: $OS"

run() {
  if [[ \$DRY_RUN -eq 1 ]]; then
    echo "[dry-run] \$*"
  else
    echo "[run] \$*"
    eval "\$@"
  fi
}

# Example: ensure git present
if command -v git >/dev/null 2>&1; then
  echo "git present"
else
  if [[ \$OS == "darwin" ]]; then
    run "brew install git"
  elif [[ -f /etc/debian_version ]]; then
    run "sudo apt-get update && sudo apt-get install -y git"
  else
    echo "Please install git manually"
    exit 1
  fi
fi

# Template: apply profile (maps to native package manager)
if [[ -f "profiles/web-dev/macos/Brewfile" && \$OS == "darwin" ]]; then
  echo "Found macOS Brewfile for web-dev"
  run "brew bundle --file=profiles/web-dev/macos/Brewfile"
fi

if [[ -f "profiles/web-dev/linux/apt.txt" && -f /etc/debian_version ]]; then
  echo "Found apt list for web-dev"
  if [[ \$DRY_RUN -eq 1 ]]; then
    echo "[dry-run] sudo xargs -a profiles/web-dev/linux/apt.txt apt-get install -y"
  else
    sudo xargs -a profiles/web-dev/linux/apt.txt apt-get install -y
  fi
fi

echo "Bootstrap complete. Run './bootstrap.sh --dry-run' first to inspect."
