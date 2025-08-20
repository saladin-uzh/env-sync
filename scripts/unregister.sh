#!/usr/bin/env bash
set -euo pipefail
usage(){ echo "Usage: $0 [--id ID] [--force]"; exit 1; }

ID=""
FORCE=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --id) ID="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown arg: $1"; usage ;;
  esac
done

if [[ -z "$ID" ]]; then
  read -r -p "Machine id to unregister: " ID
  [[ -n "$ID" ]] || { echo "id required"; exit 1; }
fi

JSON="inventory/${ID}.json"
if [[ ! -f "$JSON" ]]; then
  echo "No inventory file for id: $ID"
  exit 1
fi

if [[ $FORCE -ne 1 ]]; then
  echo "About to remove: $JSON"
  read -r -p "Confirm delete [y/N]: " yn
  case "$yn" in
    [Yy]*) : ;;
    *) echo "Aborted"; exit 0 ;;
  esac
fi

rm -f "$JSON"
echo "Removed $JSON"
