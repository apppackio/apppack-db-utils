#!/bin/sh
# Usage:  load-from-s3.sh <s3://...>
# The DATABASE_URL will be dropped and recreated from S3
set -euf

export $(parse_database_url.py | xargs)

if echo "$HOST" | grep -q "prod"; then
  echo "This looks like the production database. Refusing to run destructive operation."
  exit 1
fi

S3_PATH=$1
CONNECT_DB_URL="postgres://$USER@$HOST:$PORT/postgres"
WORKING_DB_URL="postgres://$USER@$HOST:$PORT/$NAME"
echo "Verifying $S3_PATH exists..."
aws s3 ls $S3_PATH

echo "Dropping $NAME..."
psql $CONNECT_DB_URL --echo-all -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$NAME';"
psql $CONNECT_DB_URL --echo-all -c "DROP DATABASE IF EXISTS \"$NAME\";"
psql $CONNECT_DB_URL --echo-all -c "CREATE DATABASE \"$NAME\";"

echo "Loading dump from S3..."
set -x
aws s3 cp $S3_PATH - | zcat | psql $WORKING_DB_URL