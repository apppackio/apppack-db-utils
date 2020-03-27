#!/bin/sh
# Usage:  clone-db.sh <source> <destination>
# Create a new database with the <source> used as a template.
set -euf

export $(parse_database_url.py | xargs)

if echo "$HOST" | grep -q "prod"; then
  echo "This looks like the production database. Refusing to run destructive operation."
  exit 1
fi

SOURCE_DB_NAME=$1
WORKING_DB_NAME=$2
CONNECT_DB_URL="postgres://$USER@$HOST:$PORT/$NAME"
WORKING_DB_URL="postgres://$USER@$HOST:$PORT/$WORKING_DB_NAME"

echo "Dropping $WORKING_DB_NAME..."
psql $CONNECT_DB_URL --echo-all -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$WORKING_DB_NAME';"
psql $CONNECT_DB_URL --echo-all -c "DROP DATABASE IF EXISTS \"$WORKING_DB_NAME\";"
psql $CONNECT_DB_URL --echo-all -c "CREATE DATABASE \"$WORKING_DB_NAME\" TEMPLATE \"$1\";"
