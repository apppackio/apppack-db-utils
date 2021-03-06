#!/bin/bash
# Usage:  load-from-s3.sh <s3://...>
# The DATABASE_URL will be dropped and recreated from S3
set -euf -o pipefail

S3_PATH=$1
echo "Verifying $S3_PATH exists..."
aws s3 ls $S3_PATH

echo "Dropping $NAME..."

psql --echo-all -c "DROP OWNED BY \"$NAME\" CASCADE;"

echo "Loading dump from S3..."
set -x
aws s3 cp $S3_PATH - | pg_restore --no-owner --no-privileges --schema=public --dbname="$NAME"
{ set +x; } 2>/dev/null
echo "Done!"
