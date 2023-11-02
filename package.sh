#!/bin/bash

show_message() {
  echo "-------------------------------------------------------------"
  echo "$1"
  echo "-------------------------------------------------------------"
}

show_message "Check if the script is being run as the root user"
if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as the root user."
    exit 1
fi

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
sudo mysql_secure_installation 

show_message "Install PHP and necessary extensions"
sudo apt install php php-cli php-fpm php-json php-common php-mysql php-zip php-gd php-mbstring php-curl php-xml php-pear php-bcmath -y

show_message "Additional PHP extensions"
sudo apt install php php-bcmath php-bz2 php-intl php-gd php-mbstring php-mysql php-zip php-opcache php-pdo php-calendar php-ctype php-exif php-ffi php-fileinfo php-ftp php-iconv php-intl php-json php-mysqli php-phar php-posix php-readline php-shmop php-sockets php-sysvmsg php-sysvsem php-sysvshm php-tokenizer php-curl php-ldap -y

show_message "Install Composer"
sudo curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

show_message "Create a MySQL database and user for Snipe-IT"

mysql -u root -p <<EOF
CREATE DATABASE snipeitdb;
CREATE USER snipeituser@localhost IDENTIFIED BY 'admin';
GRANT ALL PRIVILEGES ON snipeitdb.* TO snipeituser@localhost;
FLUSH PRIVILEGES;
EOF

echo "packages installation setup complete!"

