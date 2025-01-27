#!/bin/bash
# Usage:  dump-to-s3.sh <s3://...dump> [dbname]
# Expects a DATABASE_URL environment variable and optionally SERVER_VERSION exported by the entrypoint.
# Optionally, a dbname can be supplied as the second argument to override the name from DATABASE_URL.

set -euf -o pipefail

cleanup() { rv=$?; if [ -f /tmp/db.dump ]; then shred -u /tmp/db.dump; fi; exit $rv; }
trap cleanup EXIT

# Extract database name from DATABASE_URL if not provided as an argument
DBNAME=${2:-$(echo "$DATABASE_URL" | sed -E 's|.*/([^/?]+).*|\1|')}
CONNECT_DB_URL="${DATABASE_URL%/*}/$DBNAME"

# Default SERVER_VERSION to 17 if not supplied
SERVER_VERSION=${SERVER_VERSION:-17}
PG_DUMP="pg_dump-$SERVER_VERSION"

# Fallback to pg_dump-17 if the specified version is not available
if ! command -v "$PG_DUMP" &>/dev/null; then
  echo "WARNING: pg_dump for version $SERVER_VERSION is not installed. Defaulting to pg_dump-17."
  PG_DUMP="pg_dump-17"
fi

echo "Dumping $CONNECT_DB_URL to $1 using $PG_DUMP..."
set -x
"$PG_DUMP" --no-privileges --no-owner --format=custom "$CONNECT_DB_URL" --file=/tmp/db.dump
aws s3 cp --acl=private --no-progress /tmp/db.dump "$1"
{ set +x; } 2>/dev/null
echo "Done!"
