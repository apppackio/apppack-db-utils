#!/bin/sh
# Usage:  dump-to-s3.sh <s3://...sql.gz> [dbname]
# Expects a DATABASE_URL environment variable that is the DB to dump
# Optionally, a dbname can be supplied as the second argument
# to override the name from the DATABASE_URL
set -euf

NAME=${2:-$NAME}
CONNECT_DB_URL="postgres://$USER@$HOST:$PORT/$NAME"
echo "Dumping $CONNECT_DB_URL to $1..."
set -x
pg_dump --no-privileges --no-owner --compress=6 $CONNECT_DB_URL | aws s3 cp --acl=private - $1
