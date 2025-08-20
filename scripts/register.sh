#!/usr/bin/env bash
set -euo pipefail
usage(){ echo "Usage: $0 [--id ID] [--os OS] [--profile PROFILE]"; exit 1; }

ID=""
OS=""
PROFILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id) ID="$2"; shift 2 ;;
    --os) OS="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

# interactive prompts if missing
if [[ -z "$ID" ]]; then
  read -r -p "Machine id (e.g. laptop-2025): " ID
  [[ -n "$ID" ]] || { echo "id required"; exit 1; }
fi

if [[ -z "$OS" ]]; then
  DETECT="$(uname -s 2>/dev/null || echo unknown)"
  case "$DETECT" in
    Darwin) DEFAULT_OS="macos" ;;
    Linux) DEFAULT_OS="linux" ;;
    CYGWIN*|MINGW*|MSYS*) DEFAULT_OS="windows" ;;
    *) DEFAULT_OS="unknown" ;;
  esac
  read -r -p "OS [${DEFAULT_OS}]: " OS
  OS="${OS:-$DEFAULT_OS}"
  [[ -n "$OS" ]] || { echo "os required"; exit 1; }
fi

if [[ -z "$PROFILE" ]]; then
  read -r -p "Profile [web-dev]: " PROFILE
  PROFILE="${PROFILE:-web-dev}"
fi

mkdir -p inventory

JSON="inventory/${ID}.json"
if [[ -f "$JSON" ]]; then
  echo "Inventory file exists: $JSON"
  read -r -p "Overwrite? [y/N]: " yn
  case "$yn" in
    [Yy]*) : ;;
    *) echo "Aborted"; exit 0 ;;
  esac
fi

TMP="$(mktemp)"
cat > "$TMP" <<JSON
{
  "id": "${ID}",
  "os": "${OS}",
  "profile": "${PROFILE}",
  "registered_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
JSON

mv "$TMP" "$JSON"
chmod 644 "$JSON"
echo "Wrote $JSON"
