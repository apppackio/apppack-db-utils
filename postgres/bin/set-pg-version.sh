#!/bin/bash

set -euf -o pipefail

PG_VERSION=$(psql -Atc "SELECT version()" | cut -f2 -d" " | cut -f1 -d.)

# match client version with server version if supported
if [[ "$PG_VERSION" == 13 || "$PG_VERSION" == 14 || "$PG_VERSION" == 15 || "$PG_VERSION" == 16 ]]; then
    echo "Setting PostgreSQL version $PG_VERSION as default."
    pg_versions set-default "$PG_VERSION"
else
    echo "PostgreSQL version $PG_VERSION is unsupported. Using v$(pg_versions get-default) client."
fi
