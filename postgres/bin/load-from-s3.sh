#!/bin/bash
# Usage:  load-from-s3.sh <s3://...>
set -euf -o pipefail

cleanup() { rv=$?; if [ -f /tmp/db.dump ]; then shred -u /tmp/db.dump; fi; exit $rv; }
trap cleanup EXIT

S3_PATH=$1

echo "Downloading $S3_PATH ..."
aws s3 cp --no-progress "$S3_PATH" /tmp/db.dump

# Detect server version if not already available
if [ -z "${SERVER_VERSION:-}" ]; then
  echo "SERVER_VERSION not set. Trying to detect using psql..."
  SERVER_VERSION=$(psql "$DATABASE_URL" -tAc "SHOW server_version;" | cut -d '.' -f 1 || true)
fi

if [ -z "$SERVER_VERSION" ]; then
  echo "Warning: SERVER_VERSION not detected. Defaulting to version 17 (latest)."
  SERVER_VERSION="17"
fi

PG_RESTORE="pg_restore-$SERVER_VERSION"

if ! command -v "$PG_RESTORE" &>/dev/null; then
  echo "Error: $PG_RESTORE not found in PATH." >&2
  exit 1
fi

echo "Dropping all objects owned by \"$USER\" in the database..."
psql --echo-all -c "DROP OWNED BY \"$USER\" CASCADE;"

echo "Loading dump from S3 using $PG_RESTORE..."
set -x
"$PG_RESTORE" --jobs="${PG_RESTORE_JOBS:-2}" --no-owner --no-privileges --dbname="$NAME" /tmp/db.dump
{ set +x; } 2>/dev/null
echo "Done!"
