#!/bin/sh
# Usage:  clone-db.sh <source> <destination>
# Create a new database with the <source> used as a template.
set -euf

SOURCE_DB_NAME=$1
WORKING_DB_NAME=$2

echo "Drop/create $WORKING_DB_NAME..."
mysql --execute "DROP DATABASE IF EXISTS "'`'$WORKING_DB_NAME'`'
mysql --execute "CREATE DATABASE "'`'$WORKING_DB_NAME'`'
echo "Loading $SOURCE_DB_NAME into $WORKING_DB_NAME"
mysqldump --compress "$SOURCE_DB_NAME" | mysql --compress "$WORKING_DB_NAME"
echo "Done!"
