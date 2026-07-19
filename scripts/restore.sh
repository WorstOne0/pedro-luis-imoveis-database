#!/bin/sh
# Restore a dump created by backup.sh.
#
#   ./scripts/restore.sh backups/2026-07-18_03-00-00.archive.gz
#
# --drop replaces the existing collections, so this overwrites current data.
set -eu

cd "$(dirname "$0")/.."
. ./.env

ARCHIVE="${1:-}"
CONTAINER="pedro_luis_imoveis_mongo"

if [ -z "$ARCHIVE" ] || [ ! -f "$ARCHIVE" ]; then
  echo "usage: $0 <archive.gz>" >&2
  echo "available:" >&2
  ls -1 backups/*.archive.gz 2>/dev/null >&2 || echo "  (none)" >&2
  exit 1
fi

printf 'This REPLACES the contents of "%s". Continue? [y/N] ' "$MONGO_DATABASE"
read -r reply
case "$reply" in
  [yY]) ;;
  *) echo "aborted"; exit 1 ;;
esac

docker exec -i "$CONTAINER" mongorestore \
  --username "$MONGO_ROOT_USER" \
  --password "$MONGO_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --nsInclude "${MONGO_DATABASE}.*" \
  --drop --archive --gzip < "$ARCHIVE"

echo "restored ${ARCHIVE} into ${MONGO_DATABASE}"
