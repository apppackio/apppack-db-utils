#!/bin/sh

set -euf
printf "#!/bin/sh\n/usr/local/bin/aws --endpoint-url %s \"\$@\"\n" "$AWS_ENDPOINT_URL" > /root/bin/aws
chmod +x /root/bin/aws
export PATH="/root/bin:$PATH"

BUCKET=bucket

until pg_isready; do
  echo "Waiting for Postgres..."
  sleep 3
done

echo "###### Setup test state"
aws s3api create-bucket --bucket "$BUCKET"
aws s3 rm --recursive "s3://$BUCKET/"
psql postgres -U postgres -c "DROP DATABASE IF EXISTS test"
psql postgres -U postgres -c "DROP DATABASE IF EXISTS \"test-clone\""
psql postgres -U postgres -c "DROP ROLE IF EXISTS test"

psql postgres -U postgres -c "CREATE ROLE test WITH LOGIN PASSWORD 'password'"
psql postgres -U postgres -c "CREATE DATABASE test OWNER test"
psql test -c "CREATE TABLE tbl (id SERIAL PRIMARY KEY, name CHAR(255) NOT NULL)"
psql test -c "INSERT INTO tbl (name) VALUES ('name1')"
psql test -c "INSERT INTO tbl (name) VALUES ('name2')"

printf "\n###### Testing SERVER_VERSION override...\n"
export SERVER_VERSION=17
dump-to-s3.sh "s3://$BUCKET/explicit.dump" test
aws s3 ls "s3://$BUCKET/" | grep explicit.dump

printf "\n###### Testing fallback with unset SERVER_VERSION...\n"
unset SERVER_VERSION
dump-to-s3.sh "s3://$BUCKET/default.dump" test
aws s3 ls "s3://$BUCKET/" | grep default.dump

printf "\n###### Starting tests...\n"
dump-to-s3.sh "s3://$BUCKET/dump.dump" test
printf "\n###### Verify dump file exists...\n"
aws s3 ls "s3://$BUCKET/" | grep dump.dump

psql test -c "INSERT INTO tbl (name) VALUES ('name3')"
printf "\n###### Verify 3 records exist before load...\n"
psql test -c "SELECT COUNT(*) FROM tbl" | grep "3"

load-from-s3.sh "s3://$BUCKET/dump.dump"
printf "\n###### Verify 2 records exist after load...\n"
psql test -c "SELECT COUNT(*) FROM tbl" | grep "2"

printf "\n###### Verify dump file does not exist after load...\n"
test ! -f /tmp/db.dump && echo "ok"
