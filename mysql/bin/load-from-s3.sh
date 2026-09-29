#!/bin/bash
# Usage:  load-from-s3.sh <s3://...>
# The DATABASE_URL will be dropped and recreated from S3
set -euf -o pipefail

cleanup() { rv=$?; if [ -f /tmp/db.sql.gz ]; then shred -u /tmp/db.sql.gz; fi; exit $rv; }
trap cleanup EXIT

S3_PATH=$1

echo "Downloading $S3_PATH ..."
aws s3 cp --no-progress "$S3_PATH" /tmp/db.sql.gz
echo "Drop/create $NAME..."

# ~/.my.cnf now defaults to $NAME as the database (so a bare `mysql` works
# for interactive use), but $NAME doesn't exist for the moment between the
# DROP and CREATE below, and the app DB user typically has no privileges
# on any other schema to fall back to. Bypass the defaults file for these
# two statements so no default database is selected; MYSQL_PWD still
# supplies the password since it's read directly from the environment.
mysql --no-defaults --host="$HOST" --port="$PORT" --user="$USER" --execute "DROP DATABASE IF EXISTS "'`'"$NAME"'`'
mysql --no-defaults --host="$HOST" --port="$PORT" --user="$USER" --execute "CREATE DATABASE "'`'"$NAME"'`'

echo "Loading $S3_PATH into $NAME..."
set -x
gunzip -c /tmp/db.sql.gz | mysql --compress "$NAME"
{ set +x; } 2>/dev/null
echo "Done!"
