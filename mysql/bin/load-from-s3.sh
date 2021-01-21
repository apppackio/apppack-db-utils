#!/bin/sh
# Usage:  load-from-s3.sh <s3://...>
# The DATABASE_URL will be dropped and recreated from S3
set -euf

S3_PATH=$1
echo "Verifying $S3_PATH exists..."
aws s3 ls $S3_PATH

echo "Drop/create $NAME..."

mysql --execute "DROP DATABASE IF EXISTS "'`'$NAME'`'
mysql --execute "CREATE DATABASE "'`'$NAME'`'

echo "Loading $S3_PATH into $NAME..."
set -x
aws s3 cp "$S3_PATH" - | gunzip -c | mysql --compress "$NAME"
{ set +x; } 2>/dev/null
echo "Done!"
