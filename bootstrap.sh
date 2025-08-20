#!/usr/bin/env bash
set -euo pipefail
DRY_RUN=0
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1; shift
fi

# helper to echo instead of execute in dry-run
run() {
  if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
    echo "+ $*"
  else
    eval "$@"
  fi
}

echo "env-sync bootstrap"
OS="${OS:-$(uname | tr '[:upper:]' '[:lower:]')}"
echo "detected os: $OS"

# DRY RUN-SAFE example (no bare [[ $DRY_RUN … ]])
if [[ "${DRY_RUN:-0}" -eq 1 ]]; then
  echo "git present"
else
  echo "git present"
fi

if [[ "$OS" == "linux" ]]; then
  echo "Found apt list for web-dev"
  run "sudo apt-get update"
  # install only what apt actually provides
  # pnpm is handled below via Corepack
  run "sudo apt-get install -y \$(grep -vE '^#|^$' packages/apt/web-dev.txt | grep -v '^pnpm$' | tr '\n' ' ')"
fi

# Node + pnpm via Corepack (Linux/macOS)
if ! command -v node >/dev/null 2>&1; then
  if [[ "${OS:-$(uname | tr '[:upper:]' '[:lower:]')}" == "linux" ]]; then
    # prefer native package manager
    run "sudo apt-get install -y nodejs npm"
  elif [[ "${OS}" == "darwin" ]]; then
    run "brew install node"
  fi
fi

# ensure Corepack present
if ! command -v corepack >/dev/null 2>&1; then
  if command -v npm >/dev/null 2>&1; then
    run "npm install -g corepack"
  fi
fi

# activate pnpm
if command -v corepack >/dev/null 2>&1; then
  run "corepack enable"
  run "corepack prepare pnpm@latest --activate"
fi

echo "Bootstrap complete. Run './bootstrap.sh --dry-run' first to inspect."
