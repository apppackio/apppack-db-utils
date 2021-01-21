#!/bin/sh

set -euf

if [ -z "${DATABASE_URL:-""}" ]; then
  echo "WARNING: DATABASE_URL not found in environment."
else
  # Extract connection details from DATABASE_URL
  export $(parse_database_url.py | xargs)
  # Setup .my.cnf so `mysql` just does the right thing
  /bin/echo -e "[client]\nhost=$HOST\nport=$PORT\nuser=$USER" > ~/.my.cnf
fi

exec "$@"
