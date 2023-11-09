#!/bin/bash

show_message() {
  echo "-------------------------------------------------------------"
  echo "$1"
  echo "-------------------------------------------------------------"
}

show_message "db_password"
MYSQL_ROOT_PASSWORD="1"
show_message "Define Snipe-IT database credentials"
DB_NAME="snipeit"
DB_USER="snipeituser"
DB_PASSWORD="admin"
APP_URL="azurerm_public_ip.snipee_public_ip.ip_address}"

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

show_message "Download and move Composer"
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

show_message "Create a MySQL database and user for Snipe-IT"
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE $DB_NAME;"
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

show_message "Clone the repository into /var/www directory and set up Snipe-IT .env file"
cd /var/www/
sudo git clone https://github.com/snipe/snipe-it
cd snipe-it
sudo cp .env.example .env
sudo sed -i "s/DB_DATABASE=.*/DB_DATABASE=$DB_NAME/" .env
sudo sed -i "s/DB_USERNAME=.*/DB_USERNAME=$DB_USER/" .env
sudo sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=$DB_PASSWORD/" .env
sudo sed -i "s/APP_URL=.*/APP_URL=$APP_URL/" .env

show_message "Set permissions and install dependencies"
sudo apt update
sudo chown -R www-data:www-data /var/www/snipe-it
sudo chmod -R 755 /var/www/snipe-it
yes | sudo composer update --no-plugins --no-scripts
yes | sudo composer install --no-dev --prefer-source --no-plugins --no-scripts
yes | sudo php artisan key:generate

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
