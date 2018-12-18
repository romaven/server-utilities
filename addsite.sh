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

echo "Enter domain without www"
read DOMAIN

echo "Enter database"
read DATABASENAME

##############

echo "Creating vhost file"
echo "
server {
        listen 80;

        root /var/www/$USERNAME/www;
        index index.php index.html index.htm index.nginx-debian.html;
        server_name $DOMAIN www.$DOMAIN;

        access_log /var/log/nginx/$USERNAME-access.log;
		error_log /var/log/nginx/$USERNAME-error.log;
		rewrite_log on;

        location / {
                try_files $uri $uri/ /index.php?$query_string;
        }

        location ~ \.php$ {
               include snippets/fastcgi-php.conf;
               fastcgi_pass unix:/var/run/php7.2-$USERNAME.sock;
        }

        location ~ /\.ht {
               deny all;
        }
}
" > /etc/nginx/sites-available/$USERNAME.conf
ln -s /etc/nginx/sites-available/$USERNAME.conf /etc/nginx/sites-enabled/$USERNAME.conf

#############

echo "Reloading nginx"
service nginx reload
echo "Reloading php7.2-fpm"
service php7.2-fpm reload

##############

echo "Creating database"

Q1="CREATE DATABASE IF NOT EXISTS $DATABASENAME DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
Q2="GRANT ALTER,DELETE,DROP,CREATE,INDEX,INSERT,SELECT,UPDATE,CREATE TEMPORARY TABLES,LOCK TABLES ON $DATABASENAME.* TO '$USERNAME'@'localhost';"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"

mysql -uroot --password=$ROOTPASS -e "$SQL"

##############

echo "Done.
Manager user: $USERNAME
Mysql database: $DATABASENAME" > /var/www/$USERNAME/$DOMAIN.txt

cat /var/www/$USERNAME/$DOMAIN.txt