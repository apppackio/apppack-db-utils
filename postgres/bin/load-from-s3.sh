#!/bin/bash
# Usage:  load-from-s3.sh <s3://...>
# The DATABASE_URL will be dropped and recreated from S3
set -euf -o pipefail

cleanup() { rv=$?; if [ -f /tmp/db.dump ]; then shred -u /tmp/db.dump; fi; exit $rv; }
trap cleanup EXIT

S3_PATH=$1

echo "Downloading $S3_PATH ..."
aws s3 cp --no-progress "$S3_PATH" /tmp/db.dump

# Get the PostgreSQL server version
SERVER_VERSION=$(psql -tAc "SHOW server_version;" | cut -d '.' -f 1)
PG_RESTORE="pg_restore-$SERVER_VERSION"

if ! command -v "$PG_RESTORE" &>/dev/null; then
  echo "Error: pg_restore for version $SERVER_VERSION is not installed." >&2
  exit 1
fi

echo "Dropping $NAME..."

psql --echo-all -c "DROP OWNED BY \"$USER\" CASCADE;"

echo "Loading dump from S3 using $PG_RESTORE..."
set -x
"$PG_RESTORE" --jobs="${PG_RESTORE_JOBS:-2}" --no-owner --no-privileges --dbname="$NAME" /tmp/db.dump
{ set +x; } 2>/dev/null
echo "Done!"
