#!/bin/bash

set -euf -o pipefail

export PGSSLMODE=require

wait_for_db() {
  local retries=30
  local sleep_time=2

  echo "Waiting for PostgreSQL server to be ready..."
  until psql "$DATABASE_URL" -c '\q' 2>/dev/null || [ "$retries" -eq 0 ]; do
    echo "PostgreSQL is unavailable - ($((retries--)) retries left)..."
    sleep "$sleep_time"
  done

  if [ "$retries" -eq 0 ]; then
    echo "ERROR: PostgreSQL server did not respond."
    exit 1
  fi
}

if [ -z "${DATABASE_URL:-""}" ]; then
  echo "WARNING: DATABASE_URL not found in environment."
else

  # Extract connection details from DATABASE_URL
  # shellcheck disable=SC2046
  export $(parse_database_url.py | xargs)

  # Setup PGSERVICE so `psql` just does the right thing
  /bin/echo -e "[$NAME]\nhost=$HOST\nport=$PORT\ndbname=$NAME\nuser=$USER" > ~/.pg_service.conf
  export PGSERVICE="$NAME"

  # Wait for PostgreSQL to be ready
  wait_for_db

  # Detect PostgreSQL server version
  if [ -z "${SERVER_VERSION:-}" ]; then
    echo "Attempting to detect PostgreSQL server version..."
    SERVER_VERSION=$(psql "$DATABASE_URL" -tAc "SHOW server_version;" | cut -d '.' -f 1 || true)
  fi

  if [ -z "$SERVER_VERSION" ]; then
    echo "WARNING: Unable to detect PostgreSQL version. Defaulting to latest (17)."
    SERVER_VERSION="17"
  else
    echo "Detected PostgreSQL version: $SERVER_VERSION"
  fi

  export SERVER_VERSION

fi

exec "$@"
