#!/bin/bash

# Konfigurasi database
DB_NAME="hendra"
DB_USER="wpamirulr"
DB_PASS="wppaswword"
WP_DOMAIN="hendra56.my.id"

# Konfigurasi PHPMyAdmin
PHPMYADMIN_DOMAIN="phpmyadmin.hendra56.my.id"

# Langkah 1: Instalasi Nginx, MySQL, PHP-FPM
# Update and upgrade Ubuntu
apt-get update; apt-get upgrade -y; apt-get install -y fail2ban ufw;
# Langkah 2: Instalasi PHPMyAdmin
apt install -y phpmyadmin
# Konfigurasi PHPMyAdmin
echo "Include /etc/nginx/phpmyadmin.conf;" | tee -a /etc/nginx/sites-available/${PHPMYADMIN_DOMAIN}
ln -s /usr/share/phpmyadmin /var/www/html/${PHPMYADMIN_DOMAIN}

# Install NGINX
sudo apt install nginx -y
sudo systemctl enable nginx
sudo systemctl start nginx
# Add hardening commands here

#Install PHP7.4 and common PHP packages
echo "Install PHP 7.4"
sudo apt install -y software-properties-common ca-certificates lsb-release apt-transport-https 
LC_ALL=C.UTF-8 sudo add-apt-repository ppa:ondrej/php -y
sudo apt install -y php7.4 php7.4-fpm php7.4-mysql php-common php7.4-cli php7.4-common php7.4-json php7.4-opcache php7.4-readline php7.4-mbstring php7.4-xml php7.4-gd php7.4-curl


sudo systemctl enable php7.4-fpm
sudo systemctl start php7.4-fpm

#Update PHP CLI configuration
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.4/cli/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.4/cli/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.4/cli/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.4/cli/php.ini

#Configure sessions directory permissions
chmod 733 /var/lib/php/sessions
chmod +t /var/lib/php/sessions


#Tweak PHP-FPM settings
sed -i "s/error_reporting = .*/error_reporting = E_ALL \& ~E_NOTICE \& ~E_STRICT \& ~E_DEPRECATED/" /etc/php/7.4/fpm/php.ini
sed -i "s/display_errors = .*/display_errors = Off/" /etc/php/7.4/fpm/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php/7.4/fpm/php.ini
sed -i "s/upload_max_filesize = .*/upload_max_filesize = 256M/" /etc/php/7.4/fpm/php.ini
sed -i "s/post_max_size = .*/post_max_size = 256M/" /etc/php/7.4/fpm/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php/7.4/fpm/php.ini

#Tune PHP-FPM pool settings

sed -i "s/;listen\.mode =.*/listen.mode = 0666/" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s/;request_terminate_timeout =.*/request_terminate_timeout = 60/" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s/pm\.max_children =.*/pm.max_children = 70/" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s/pm\.start_servers =.*/pm.start_servers = 20/" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s/pm\.min_spare_servers =.*/pm.min_spare_servers = 20/" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s/pm\.max_spare_servers =.*/pm.max_spare_servers = 35/" /etc/php/7.4/fpm/pool.d/www.conf
sed -i "s/;pm\.max_requests =.*/pm.max_requests = 500/" /etc/php/7.4/fpm/pool.d/www.conf

#Install MariaDB (MySQL) and set a strong root passworD#
# Install MariaDB and harden it

#Install MariaDB (MySQL) and set a strong root password

apt-get install -y mariadb-server;

#Secure your MariaDB installation

# Langkah 2: Konfigurasi database MySQL
mysql -e "CREATE DATABASE ${DB_NAME} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Langkah 3: Unduh dan konfigurasi WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -zxvf latest.tar.gz
sudo mv wordpress /var/www/html/${WP_DOMAIN}
sudo chown -R www-data:www-data /var/www/html/${WP_DOMAIN}
sudo chmod -R 755 /var/www/html/${WP_DOMAIN}

# Langkah 4: Konfigurasi wp-config.php
cd /var/www/html/${WP_DOMAIN}
sudo mv wp-config-sample.php wp-config.php
sudo sed -i "s/database_name_here/${DB_NAME}/" wp-config.php
sudo sed -i "s/username_here/${DB_USER}/" wp-config.php
sudo sed -i "s/password_here/${DB_PASS}/" wp-config.php

# Langkah 5: Buat wp-content/uploads folder
mkdir wp-content/uploads
sudo chown -R www-data:www-data wp-content/uploads

# Langkah 6: Konfigurasi Nginx
cd /etc/nginx/sites-available/
wget https://raw.githubusercontent.com/amirul5656/wp/main/hendra56.my.id
cd~
cd /var/www/html/
mkdir hendra56.my.id
cd~

# Aktifkan konfigurasi Nginx virtual host
sudo ln -s /etc/nginx/sites-available/${WP_DOMAIN} /etc/nginx/sites-enabled/
# Aktifkan konfigurasi Nginx virtual host untuk PHPMyAdmin
sudo ln -s /etc/nginx/sites-available/${PHPMYADMIN_DOMAIN} /etc/nginx/sites-enabled/

# Uji konfigurasi Nginx
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Langkah 7: Setup WordPress melalui WP-CLI (opsional)


# Selesai
echo "Instalasi WordPress dengan Nginx selesai. Anda bisa mengakses situs Anda di http://${WP_DOMAIN}"
