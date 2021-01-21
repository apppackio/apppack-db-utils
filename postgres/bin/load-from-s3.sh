#!/bin/sh
# Usage:  load-from-s3.sh <s3://...>
# The DATABASE_URL will be dropped and recreated from S3
set -euf

if echo "$HOST" | grep -q "prod"; then
  echo "This looks like the production database. Refusing to run destructive operation."
  exit 1
fi

S3_PATH=$1
echo "Verifying $S3_PATH exists..."
aws s3 ls $S3_PATH

echo "Dropping $NAME..."

psql --echo-all -c "DROP OWNED BY \"$NAME\" CASCADE;"

echo "Loading dump from S3..."
set -x
aws s3 cp $S3_PATH - | pg_restore --no-owner --no-privileges --dbname="$NAME"
set +x
echo "Done!"
