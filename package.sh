#!/bin/bash

show_message() {
  echo "-------------------------------------------------------------"
  echo "$1"
  echo "-------------------------------------------------------------"
}
show_message "Update package lists and install necessary packages"
sudo apt update
sudo apt install apache2 -y

show_message "Start and enable Apache"
sudo systemctl start apache2
sudo systemctl enable apache2

show_message "Enable Apache rewrite module"
sudo a2enmod rewrite

show_message "Restart Apache"
sudo systemctl restart apache2

show_message "Install MariaDB and secure the installation"
sudo apt install mariadb-server mariadb-client -y
sudo systemctl start mariadb
sudo systemctl enable mariadb

show_message "Install PHP and necessary extensions"
sudo apt update
sudo apt install php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath -y

show_message "Additional PHP extensions"
sudo apt install php-bz2 php-intl php-ffi php-fileinfo php-ftp php-iconv php-json php-mysqli php-phar php-posix php-readline php-shmop php-sockets php-sysvmsg php-sysvsem php-sysvshm php-tokenizer php-curl php-ldap -y

show_message "Install Composer"
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

show_message "Create a MySQL database and user for Snipe-IT"
sudo mysql <<EOF
CREATE DATABASE snipeitdb;
CREATE USER snipeituser@localhost IDENTIFIED BY 'admin';
GRANT ALL PRIVILEGES ON snipeitdb.* TO snipeituser@localhost;
FLUSH PRIVILEGES;
EOF

GIT_USERNAME="nikhilk1669"
GIT_PASSWORD="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"
REPO_URL="https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/PearlThoughtsInternship/snipe-it.git"

show_message "Clone the repository and set up Snipe-IT"
sudo chown -R linuxusr:linuxusr /var/www/
cd /var/www/ || exit 1
git clone $REPO_URL
cd snipe-it || exit 1
cp .env.example .env
sudo sed -i "s/DB_DATABASE=.*/DB_DATABASE=snipeit/" .env
sudo sed -i "s/DB_USERNAME=.*/DB_USERNAME=snipeituser/" .env
sudo sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=admin/" .env
sudo sed -i "s/APP_URL=.*/APP_URL=/" .env

show_message "Set permissions and install dependencies"
sudo apt update
sudo chown -R www-data:www-data /var/www/snipe-it
sudo chmod -R 755 /var/www/snipe-it
yes | sudo composer update --no-plugins --no-scripts
yes | sudo composer install --no-dev --prefer-source --no-plugins --no-scripts
yes | sudo php artisan key:generate
yes | sudo php artisan migrate

show_message "Configure Apache"
sudo a2dissite 000-default.conf

show_message "Define the content to be added to the snipe-it.conf file"
content="<VirtualHost *:80>
    ServerName snipe-it.syncbricks.com
    DocumentRoot /var/www/snipe-it/public
    <Directory /var/www/snipe-it/public>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>"

show_message "Add the content to the snipe-it.conf file"
echo "$content" | sudo tee /etc/apache2/sites-available/snipe-it.conf > /dev/null

show_message "Restart Apache for changes to take effect"
sudo systemctl restart apache2

sudo a2ensite snipe-it.conf

show_message "Adjust permissions and restart Apache"
sudo chown -R www-data:www-data /var/www/snipe-it/storage
sudo chmod -R 755 /var/www/snipe-it/storage
sudo systemctl restart apache2

show_message "Snipe-IT setup complete!"
