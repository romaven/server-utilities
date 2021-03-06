#!/usr/bin/env bash

read -s -p "Enter MySql password: " ROOTPASS
echo
echo "Enter username to delete:"
read USERNAME
echo
echo "You must drop all user databases manualy"
mysql -uroot --password=$ROOTPASS -e "DROP USER $USERNAME@localhost"
rm -f /etc/nginx/sites-enabled/$USERNAME.conf
rm -f /etc/nginx/sites-available/$USERNAME.conf
rm -f /etc/php/7.2/fpm/pool.d/$USERNAME.conf
find /var/log/nginx/ -type f -name "$USERNAME-*" -exec rm '{}' \;

service nginx reload
service php7.2-fpm reload

userdel -rf $USERNAME