## create Bash script package.sh

```
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
sudo  apt install mariadb-server mariadb-client -y
sudo systemctl start mariadb
sudo systemctl enable mariadb

show_message "Configure MariaDB"
sudo mysql -e  <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH 'mysql_native_password' BY 'snipe1';
DELETE FROM mysql.user WHERE User='';
FLUSH PRIVILEGES;
EOF

show_message "Install PHP and necessary extensions"
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
cat <<EOL > .env
APP_DEBUG=false
APP_KEY=
APP_URL=
DB_DATABASE=snipeitdb
DB_USERNAME=snipeituser
DB_PASSWORD=admin
EOL

show_message "Set permissions and install dependencies"
sudo chown -R www-data:www-data /var/www/snipe-it
sudo chmod -R 755 /var/www/snipe-it
yes | sudo composer update --no-plugins --no-scripts
yes | sudo composer install --no-dev --prefer-source --no-plugins --no-scripts
yes | php artisan key:generate

show_message "Configure Apache"
sudo a2dissite 000-default.conf

show_message "Define the content to be added to the snipe-it.conf file"
content="<VirtualHost *:80>
    ServerName snipe-it.syncbricks.com
    DocumentRoot /var/www/snipe-it/public
    <Directory /var/www/snipe-it/public>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Order allow,deny
        allow from all
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
```
## explaination of script

### show_message() function: This function is defined to display a message surrounded by a line of hyphens.
### It then starts and enables the Apache web server using systemctl. The script enables the Apache rewrite module using a2enmod. Apache is restarted to apply the changes.
### The script proceeds to install MariaDB (a relational database) and secure the installation. It starts and enables the MariaDB service. It then configures MariaDB by setting a root user password and removing empty user entries. PHP and various PHP extensions are installed to support Snipe-IT. Composer, a PHP package manager, is installed.A MySQL database and user for Snipe-IT are created, and privileges are granted to the user for the database.
### The script defines variables for a GitHub repository URL, including a username and password for authentication.

### The repository is cloned, and Snipe-IT is set up in the /var/www/snipe-it directory. The script sets permissions and installs dependencies for the Snipe-IT installation, generates an application key, and configures Apache.

### It defines the content for an Apache configuration file (snipe-it.conf) in a variable. The content is added to the snipe-it.conf file, which defines the virtual host for the Snipe-IT website.
### Apache is restarted to apply the configuration changes, and the virtual host is enabled. Permissions are adjusted for the storage directory in the Snipe-IT installation, and Apache is restarted once more. A final message is displayed to indicate that the Snipe-IT setup is complete.
### Overall, this script automates the installation and configuration of the Apache web server, MariaDB, PHP, Composer, and Snipe-IT on a Linux system. It also configures Apache to serve the Snipe-IT application. 

```
