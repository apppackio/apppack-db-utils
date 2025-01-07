#!/bin/bash

set -euf -o pipefail

export PGSSLMODE=require

if [ -z "${DATABASE_URL:-""}" ]; then
  echo "WARNING: DATABASE_URL not found in environment."
else
  # Extract connection details from DATABASE_URL
  # shellcheck disable=SC2046
  export $(parse_database_url.py | xargs)
  # Setup PGSERVICE so `psql` just does the right thing
  /bin/echo -e "[$NAME]\nhost=$HOST\nport=$PORT\ndbname=$NAME\nuser=$USER" > ~/.pg_service.conf
  export PGSERVICE="$NAME"

  # Detect PostgreSQL server version
  SERVER_VERSION=$(psql "$DATABASE_URL" -tAc "SHOW server_version;" | cut -d '.' -f 1 || true)
  if [ -z "$SERVER_VERSION" ]; then
    echo "WARNING: Unable to detect PostgreSQL server version. Defaulting to latest (17)."
    SERVER_VERSION="17"
  else
    echo "Detected PostgreSQL server version: $SERVER_VERSION"
  fi
  export SERVER_VERSION
fi

exec "$@"
