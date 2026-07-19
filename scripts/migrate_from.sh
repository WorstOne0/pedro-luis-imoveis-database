#!/bin/sh
# One-shot copy from an existing MongoDB (local install or Atlas) into this
# container.
#
#   ./scripts/migrate_from.sh "mongodb://127.0.0.1:27017/pedro_luis_imoveis"
#   ./scripts/migrate_from.sh "mongodb+srv://user:pass@cluster.mongodb.net/pedro_luis_imoveis"
#
# Reads only from the source; it is safe to run while the old database stays up,
# and safe to re-run.
set -eu

cd "$(dirname "$0")/.."
. ./.env

SOURCE_URI="${1:-}"
CONTAINER="pedro_luis_imoveis_mongo"
TMP="backups/migration_$(date +%Y-%m-%d_%H-%M-%S).archive.gz"

if [ -z "$SOURCE_URI" ]; then
  echo "usage: $0 <source-mongodb-uri>" >&2
  exit 1
fi

mkdir -p backups

# mongodump runs inside the mongo image so nothing extra is needed on the host.
# --network=host lets it reach a database running on the VPS itself; for Atlas
# it just goes out to the internet as usual.
echo "dumping from source..."
docker run --rm --network=host mongo:7.0 \
  mongodump --uri "$SOURCE_URI" --archive --gzip > "$TMP"

if [ ! -s "$TMP" ]; then
  echo "ERROR: dump is empty - check the source URI" >&2
  rm -f "$TMP"
  exit 1
fi

echo "dumped $(du -h "$TMP" | cut -f1), restoring into container..."

docker exec -i "$CONTAINER" mongorestore \
  --username "$MONGO_ROOT_USER" \
  --password "$MONGO_ROOT_PASSWORD" \
  --authenticationDatabase admin \
  --drop --archive --gzip < "$TMP"

echo "done. Dump kept at ${TMP}"
