#!/usr/bin/env bash
set -euo pipefail
usage() { echo "Usage: $0 --id <id> --os <os> --profile <profile>"; exit 1; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --id) ID="$2"; shift 2 ;;
    --os) OS="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    *) usage ;;
  esac
done
if [[ -z "${ID:-}" || -z "${OS:-}" || -z "${PROFILE:-}" ]]; then usage; fi
JSON="inventory/${ID}.json"
cat > "\$JSON" <<JSON
{ "id": "\$ID", "os": "\$OS", "profile": "\$PROFILE", "registered_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")" }
JSON
echo "Wrote \$JSON"
