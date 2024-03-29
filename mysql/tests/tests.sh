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
mysql -u root --execute 'DROP DATABASE IF EXISTS `test`'
mysql -u root --execute 'DROP DATABASE IF EXISTS `test-clone`'
mysql -u root --execute "DROP USER IF EXISTS 'test'"
mysql -u root --execute 'CREATE DATABASE `test`'
mysql -u root --execute "CREATE USER 'test'@'%' IDENTIFIED BY 'password'"
mysql -u root --execute 'GRANT ALL PRIVILEGES ON `test`.* TO `test`@`%`'
mysql test --execute "CREATE TABLE tbl (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255) NOT NULL)"
mysql test --execute "INSERT INTO tbl (name) VALUES ('name1')"
mysql test --execute "INSERT INTO tbl (name) VALUES ('name2')"

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
