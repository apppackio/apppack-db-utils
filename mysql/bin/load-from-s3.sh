#!/bin/bash
# Usage:  load-from-s3.sh <s3://...>
# The DATABASE_URL will be dropped and recreated from S3
set -euf -o pipefail

cleanup() { rv=$?; if [ -f /tmp/db.sql.gz ]; then shred -u /tmp/db.sql.gz; fi; exit $rv; }
trap cleanup EXIT

S3_PATH=$1

echo "Downloading $S3_PATH ..."
aws s3 cp "$S3_PATH" /tmp/db.sql.gz

echo "Drop/create $NAME..."

mysql --execute "DROP DATABASE IF EXISTS "'`'$NAME'`'
mysql --execute "CREATE DATABASE "'`'$NAME'`'

echo "Loading $S3_PATH into $NAME..."
set -x
gunzip -c /tmp/db.sql.gz | mysql --compress "$NAME"
{ set +x; } 2>/dev/null
echo "Done!"
