#!/bin/bash

set -euf -o pipefail

if [ -z "${DATABASE_URL:-""}" ]; then
  echo "WARNING: DATABASE_URL not found in environment."
else
  # Extract connection details from DATABASE_URL
  # shellcheck disable=SC2046
  export $(parse_database_url.py | xargs)
  # Setup .my.cnf so `mysql` just does the right thing
  # `database` only goes in [mysql] (read by the interactive mysql client);
  # putting it in [client] breaks mysqladmin/mysqldump, which also read
  # [client] but reject `database` as an unknown option.
  /bin/echo -e "[client]\nhost=$HOST\nport=$PORT\nuser=$USER\n\n[mysql]\ndatabase=$NAME" > ~/.my.cnf
fi

exec "$@"
