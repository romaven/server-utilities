#!/usr/bin/env bash

read -s -p "Enter MySql password: " ROOTPASS
echo
echo "Enter username for site and database:"
read USERNAME

if grep -c "^$USERNAME:" /etc/passwd > /dev/null 2>&1; then
	echo "User $USERNAME exist"
else
	echo "User $USERNAME doesn't exists"
	echo "Create new user first"
	exit 1
fi

echo "User databases"
Q0="SELECT * FROM mysql.db WHERE User="$USERNAME";"
SQL="${Q0}"

mysql -uroot --password=$ROOTPASS -e "$SQL"

echo "Enter new database"
read DATABASENAME

##############

echo "Creating database"

Q1="CREATE DATABASE IF NOT EXISTS $DATABASENAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
Q2="GRANT ALTER,DELETE,DROP,CREATE,INDEX,INSERT,SELECT,UPDATE,CREATE TEMPORARY TABLES,LOCK TABLES ON $DATABASENAME.* TO '$USERNAME'@'localhost';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"

mysql -uroot --password=$ROOTPASS -e "$SQL"

echo "Done"