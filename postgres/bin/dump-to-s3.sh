#!/bin/bash
# Usage:  dump-to-s3.sh <s3://...dump> [dbname]
# Expects a DATABASE_URL environment variable that is the DB to dump
# Optionally, a dbname can be supplied as the second argument
# to override the name from the DATABASE_URL
set -euf -o pipefail

cleanup() { rv=$?; if [ -f /tmp/db.dump ]; then shred -u /tmp/db.dump; fi; exit $rv; }
trap cleanup EXIT

set-pg-version.sh

NAME=${2:-$NAME}
CONNECT_DB_URL="postgres://$USER@$HOST:$PORT/$NAME"

echo "Dumping $CONNECT_DB_URL to $1..."
set -x
pg_dump --no-privileges --no-owner --format=custom "$CONNECT_DB_URL" --file=/tmp/db.dump
aws s3 cp --acl=private --no-progress /tmp/db.dump "$1"
{ set +x; } 2>/dev/null
echo "Done!"
