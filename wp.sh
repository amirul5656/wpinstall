#!/bin/bash

# Konfigurasi database
DB_NAME="wordpress"
DB_USER="wpuser"
DB_PASS="password"

# Konfigurasi situs WordPress
WP_DOMAIN="hendra56.my.id"
WP_TITLE="My WordPress Site"
WP_ADMIN_USER="admin"
WP_ADMIN_PASS="Amirul10021996"
WP_ADMIN_EMAIL="admin@hendra56.my.id"

# Langkah 1: Instalasi Nginx, MySQL, PHP-FPM
# Update and upgrade Ubuntu
apt-get update; apt-get upgrade -y; apt-get install -y fail2ban ufw;

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
sudo nano /etc/nginx/sites-available/${WP_DOMAIN}

# Konfigurasi Nginx virtual host untuk WordPress
server {
    listen 80;
    server_name ${WP_DOMAIN};
    root /var/www/html/${WP_DOMAIN};
    index index.php index.html index.htm;
    location / {
        try_files $uri $uri/ /index.php?$args;
    }
    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/var/run/php/php7.4-fpm.sock; # Sesuaikan dengan versi PHP-FPM yang terinstall
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}

# Aktifkan konfigurasi Nginx virtual host
sudo ln -s /etc/nginx/sites-available/${WP_DOMAIN} /etc/nginx/sites-enabled/

# Uji konfigurasi Nginx
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx

# Langkah 7: Setup WordPress melalui WP-CLI (opsional)
# Install WP-CLI (jika belum terinstall)
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp

# Konfigurasi situs WordPress
wp core install --url=http://${WP_DOMAIN} --title="${WP_TITLE}" --admin_user=${WP_ADMIN_USER} --admin_password=${WP_ADMIN_PASS} --admin_email=${WP_ADMIN_EMAIL}

# Selesai
echo "Instalasi WordPress dengan Nginx selesai. Anda bisa mengakses situs Anda di http://${WP_DOMAIN}"
