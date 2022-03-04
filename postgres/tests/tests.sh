#!/bin/sh

set -euf -o pipefail
echo -e "/usr/local/bin/aws --endpoint-url $AWS_ENDPOINT_URL "'"$@"' > /root/bin/aws
chmod +x /root/bin/aws
export PATH=/root/bin:$PATH

BUCKET=bucket

until pg_isready; do
  echo "Waiting for Postgres..."
  sleep 3
done

echo "###### Setup test state"
aws s3api create-bucket --bucket "$BUCKET"
aws s3 rm --recursive "s3://$BUCKET/"
psql postgres -U postgres -c "DROP DATABASE IF EXISTS test"
psql postgres -U postgres  -c "DROP DATABASE IF EXISTS \"test-clone\""
psql postgres -U postgres -c "DROP ROLE IF EXISTS test"

psql postgres -U postgres -c "CREATE ROLE test WITH LOGIN PASSWORD 'password'"
psql postgres -U postgres -c "CREATE DATABASE test OWNER test"
psql test -c "CREATE TABLE tbl (id SERIAL PRIMARY KEY, name CHAR(255) NOT NULL)"
psql test -c "INSERT INTO tbl (name) VALUES ('name1')"
psql test -c "INSERT INTO tbl (name) VALUES ('name2')"

echo -e "\n###### Starting tests..."
dump-to-s3.sh "s3://$BUCKET/dump.dump" test
echo -e "\n###### Verify dump file exists..."
aws s3 ls "s3://$BUCKET/" | grep dump.dump


psql test -c "INSERT INTO tbl (name) VALUES ('name3')"
echo -e "\n###### Verify 3 records exist before load..."
psql test -c "SELECT COUNT(*) FROM tbl" | grep "3"

load-from-s3.sh "s3://$BUCKET/dump.dump"
echo -e "\n###### Verify 2 record exists after load..."
psql test -c "SELECT COUNT(*) FROM tbl" | grep "2"

printf "\n###### Verify dump file does not exist after load...\n"
test ! -f /tmp/db.dump && echo "ok"
