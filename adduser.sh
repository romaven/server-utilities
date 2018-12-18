#!/bin/bash

TIMEZONE='Europe/Moscow'

MYSQLPASS=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12`
PASSWORD=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c12`

##############

echo "Enter username for site and database:"
read USERNAME

read -s -p "Enter MySql password: " ROOTPASS

if grep -c "^$USERNAME:" /etc/passwd > /dev/null 2>&1; then
	echo "User already exists"
	exit 1
fi

##############

echo "Creating user and home directory..."
useradd $USERNAME -m -s "/bin/false" -d "/var/www/$USERNAME"
if [ "$?" -ne 0 ]; then
	echo "Can't add user"
	exit 1
fi
echo $PASSWORD > ./tmp
echo $PASSWORD >> ./tmp
cat ./tmp | passwd $USERNAME
rm ./tmp

##############

mkdir /var/www/$USERNAME/www
mkdir /var/www/$USERNAME/tmp
chmod -R 755 /var/www/$USERNAME/
chown -R $USERNAME:$USERNAME /var/www/$USERNAME/
chown root:root /var/www/$USERNAME

##############

echo "Creating php7.2-fpm config"

echo "[$USERNAME]
listen = /var/run/php7.2-$USERNAME.sock
listen.mode = 0666
user = $USERNAME
group = $USERNAME
chdir = /var/www/$USERNAME
php_admin_value[upload_tmp_dir] = /var/www/$USERNAME/tmp
php_admin_value[soap.wsdl_cache_dir] = /var/www/$USERNAME/tmp
php_admin_value[upload_max_filesize] = 100M
php_admin_value[post_max_size] = 100M
php_admin_value[open_basedir] = /var/www/$USERNAME/
php_admin_value[cgi.fix_pathinfo] = 0
php_admin_value[date.timezone] = $TIMEZONE
php_admin_value[session.gc_probability] = 1
php_admin_value[session.gc_divisor] = 100
pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 2
pm.max_spare_servers = 4
" > /etc/php/7.2/fpm/pool.d/$USERNAME.conf

echo "Reloading php7.2-fpm"
service php7.2-fpm reload

##############

echo "Creating database"

Q1="CREATE USER '$USERNAME'@'localhost' IDENTIFIED BY '$MYSQLPASS';"
Q2="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}"

mysql -uroot --password=$ROOTPASS -e "$SQL"

##############

echo "#!/bin/bash
echo \"Set permissions for /var/www/$USERNAME/www...\";
echo \"CHOWN files...\";
chown -R $USERNAME:$USERNAME \"/var/www/$USERNAME/www\";
echo \"CHMOD directories...\";
find \"/var/www/$USERNAME/www\" -type d -exec chmod 0755 '{}' \;
echo \"CHMOD files...\";
find \"/var/www/$USERNAME/www\" -type f -exec chmod 0644 '{}' \;
" > /var/www/$USERNAME/chmod
chmod +x /var/www/$USERNAME/chmod

##############

echo "Done.
User: $USERNAME
Password: $PASSWORD" > /var/www/$USERNAME/pass.txt

cat /var/www/$USERNAME/pass.txt