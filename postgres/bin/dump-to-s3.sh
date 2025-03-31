#!/bin/bash
# Usage:  dump-to-s3.sh <s3://...dump> [dbname]
# Expects a DATABASE_URL environment variable that is the DB to dump and optionally SERVER_VERSION exported by the entrypoint.
# Optionally, a dbname can be supplied as the second argument to override the name from DATABASE_URL.

set -euf -o pipefail

cleanup() { rv=$?; if [ -f /tmp/db.dump ]; then shred -u /tmp/db.dump; fi; exit $rv; }
trap cleanup EXIT

# Extract database name from DATABASE_URL if not provided as an argument
NAME=${2:-$NAME}
CONNECT_DB_URL="postgres://$USER@$HOST:$PORT/$NAME"

# Try to detect server version if not provided
if [ -z "${SERVER_VERSION:-}" ]; then
  echo "SERVER_VERSION not set. Trying to detect using psql..."
  SERVER_VERSION=$(psql "$CONNECT_DB_URL" -tAc "SHOW server_version;" | cut -d '.' -f 1 || true)
fi

if [ -z "$SERVER_VERSION" ]; then
  echo "Warning: SERVER_VERSION not detected. Defaulting to version 17 (latest)."
  SERVER_VERSION="17"
fi

PG_DUMP="pg_dump-$SERVER_VERSION"

if ! command -v "$PG_DUMP" &>/dev/null; then
  echo "ERROR: $PG_DUMP not found in PATH. You must install it or override SERVER_VERSION." >&2
  exit 1
fi

echo "Dumping $CONNECT_DB_URL to $1 using $PG_DUMP..."
set -x
"$PG_DUMP" --no-privileges --no-owner --format=custom "$CONNECT_DB_URL" --file=/tmp/db.dump
aws s3 cp --acl=private --no-progress /tmp/db.dump "$1"
{ set +x; } 2>/dev/null
echo "Done!"
