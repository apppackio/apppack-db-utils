#!/bin/bash
# Usage:  dump-to-s3.sh <s3://...sql.gz> [dbname]
# Expects a DATABASE_URL environment variable that is the DB to dump
# Optionally, a dbname can be supplied as the second argument
# to override the name from the DATABASE_URL
set -euf -o pipefail

NAME=${2:-$NAME}
echo "Dumping $NAME to $1..."
set -x
mysqldump --compress --no-tablespaces "$NAME" | gzip -c | aws s3 cp --acl=private - $1
{ set +x; } 2>/dev/null
echo "Done!"
