#!/bin/bash
# Usage:  load-from-s3.sh <s3://...>
# The DATABASE_URL will be dropped and recreated from S3
set -euf -o pipefail

cleanup() { rv=$?; if [ -f /tmp/db.dump ]; then shred -u /tmp/db.dump; fi; exit $rv; }
trap cleanup EXIT

S3_PATH=$1

echo "Downloading $S3_PATH ..."
aws s3 cp --no-progress "$S3_PATH" /tmp/db.dump

echo "Dropping $NAME..."

psql --echo-all -c "DROP OWNED BY \"$NAME\" CASCADE;"

echo "Loading dump from S3..."
set -x
pg_restore --jobs="${PG_RESTORE_JOBS:-2}" --no-owner --no-privileges --schema=public --dbname="$NAME" /tmp/db.dump
{ set +x; } 2>/dev/null
echo "Done!"
