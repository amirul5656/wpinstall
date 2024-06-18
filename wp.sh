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
apt update
apt install -y nginx mysql-server php-fpm php-mysql

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
