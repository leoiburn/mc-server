#!/usr/bin/env bash
# Restore the world from a backup snapshot.
# Usage:  ./scripts/restore.sh [path-to-backup.tgz]
# With no argument it uses the most recent backup in ./backups.
set -euo pipefail

cd "$(dirname "$0")/.."   # repo root

BACKUP="${1:-$(ls -t backups/*.tgz 2>/dev/null | head -1)}"
if [[ -z "${BACKUP}" || ! -f "${BACKUP}" ]]; then
  echo "No backup found. Pass a path, e.g. ./scripts/restore.sh backups/world-2026....tgz"
  exit 1
fi

echo ">> Restoring from: ${BACKUP}"
echo ">> This will OVERWRITE the current world in ./data. Ctrl-C to abort."
read -r -p "Type 'yes' to continue: " ok
[[ "${ok}" == "yes" ]] || { echo "Aborted."; exit 1; }

echo ">> Stopping server..."
docker compose stop mc

echo ">> Extracting backup into ./data ..."
tar -xzf "${BACKUP}" -C data

echo ">> Starting server..."
docker compose start mc
echo ">> Done. Watch logs with:  docker compose logs -f mc"
