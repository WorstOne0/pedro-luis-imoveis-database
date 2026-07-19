#!/bin/sh
# Dump the database to ./backups/<timestamp>.archive.gz and prune old dumps.
#
# Cron it daily on the VPS:
#   0 3 * * * cd /srv/pedro_luis_imoveis_database && ./scripts/backup.sh >> backup.log 2>&1
set -eu

cd "$(dirname "$0")/.."
. ./.env

RETENTION_DAYS="${RETENTION_DAYS:-14}"
CONTAINER="pedro_luis_imoveis_mongo"
STAMP="$(date +%Y-%m-%d_%H-%M-%S)"
OUT="backups/${STAMP}.archive.gz"

mkdir -p backups

echo "[$(date)] backing up ${MONGO_DATABASE} -> ${OUT}"

# --archive streams a single file out of the container, so no temp copy is
# left inside it.
docker exec "$CONTAINER" mongodump \
  --username "$MONGO_ROOT_USER" \
  --password "$MONGO_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --db "$MONGO_DATABASE" \
  --archive --gzip > "$OUT"

# A zero-byte archive means the dump failed but the redirect still created the
# file; catching it here stops a broken backup from rotating out a good one.
if [ ! -s "$OUT" ]; then
  echo "ERROR: backup is empty, removing" >&2
  rm -f "$OUT"
  exit 1
fi

echo "[$(date)] wrote $(du -h "$OUT" | cut -f1)"

find backups -name '*.archive.gz' -type f -mtime "+${RETENTION_DAYS}" -delete
echo "[$(date)] pruned backups older than ${RETENTION_DAYS} days"
