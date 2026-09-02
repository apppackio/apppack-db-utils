#!/bin/sh

set -euf
printf "#!/bin/bash\n/usr/local/bin/aws --endpoint-url %s \"\$@\"\n" "$AWS_ENDPOINT_URL" > /root/bin/aws
chmod +x /root/bin/aws
export "PATH=/root/bin:$PATH"

BUCKET=bucket

until mysqladmin -u root -h "$HOST" -P "$PORT" ping; do
  echo "Waiting for MySQL..."
  sleep 3
done

echo "###### Setup test state"
aws s3api create-bucket --bucket "$BUCKET"
aws s3 rm --recursive "s3://$BUCKET/"
# `test` doesn't exist yet, and ~/.my.cnf now defaults to it (see [mysql]
# section written by entrypoint.sh), so these bootstrap statements target
# the always-present `mysql` system schema explicitly instead of relying
# on that default.
mysql -u root mysql --execute 'DROP DATABASE IF EXISTS `test`'
mysql -u root mysql --execute 'DROP DATABASE IF EXISTS `test-clone`'
mysql -u root mysql --execute "DROP USER IF EXISTS 'test'"
mysql -u root mysql --execute 'CREATE DATABASE `test`'
mysql -u root mysql --execute "CREATE USER 'test'@'%' IDENTIFIED BY 'password'"
mysql -u root mysql --execute 'GRANT ALL PRIVILEGES ON `test`.* TO `test`@`%`'
mysql test --execute "CREATE TABLE tbl (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255) NOT NULL)"
mysql test --execute "INSERT INTO tbl (name) VALUES ('name1')"
mysql test --execute "INSERT INTO tbl (name) VALUES ('name2')"

printf "\n###### Testing bare mysql (no --database) uses database from DATABASE_URL...\n"
mysql --execute "SELECT COUNT(*) FROM tbl" | grep "2" > /dev/null
echo "✅ bare mysql connected to the database named in DATABASE_URL via ~/.my.cnf"

printf "\n###### Testing portless DATABASE_URL defaults PORT to 3306...\n"
PARSED_PORTLESS=$(DATABASE_URL="mysql://test:password@db/test" parse_database_url.py)
echo "$PARSED_PORTLESS" | grep "PORT=3306" > /dev/null
echo "✅ PORT defaulted to 3306 for a portless DATABASE_URL"

printf "\n###### Testing connection succeeds with a portless DATABASE_URL...\n"
eval "$PARSED_PORTLESS"
mysql --host="$HOST" --port="$PORT" --user="$USER" --password="$MYSQL_PWD" "$NAME" --execute "SELECT 1" > /dev/null
echo "✅ mysql connected successfully using the parsed portless DATABASE_URL"

printf "\n###### Starting tests...\n"
dump-to-s3.sh "s3://$BUCKET/dump.sql.gz" test
printf "\n###### Verify dump file exists...\n"
aws s3 ls "s3://$BUCKET/" | grep dump.sql.gz


mysql test --execute "INSERT INTO tbl (name) VALUES ('name3')"
printf "\n###### Verify 3 records exist before load...\n"
mysql test --execute "SELECT COUNT(*) FROM tbl" | grep "3"

load-from-s3.sh "s3://$BUCKET/dump.sql.gz"
printf "\n###### Verify 2 record exists after load...\n"
mysql test --execute "SELECT COUNT(*) FROM tbl" | grep "2"

printf "\n###### Verify dump file does not exist after load...\n"
test ! -f /tmp/db.sql.gz && echo "ok"
