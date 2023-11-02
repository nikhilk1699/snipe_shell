#!/bin/bash

show_message() {
  echo "-------------------------------------------------------------"
  echo "$1"
  echo "-------------------------------------------------------------"
}

show_message "Check if the script is being run as the root user"
if [ "$EUID" -ne 0 ]; then
    show_message "Please run this script as the root user."
    exit 1
fi

show_message "Clone the repository and set up Snipe-IT"
cd /var/www/ || exit 1
git clone https://github.com/PearlThoughtsInternship/snipe-it.git
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
chown -R www-data:www-data /var/www/snipe-it
chmod -R 755 /var/www/snipe-it
composer update --no-plugins --no-scripts
composer install --no-dev --prefer-source --no-plugins --no-scripts
php artisan key:generate

show_message "Configure Apache"
a2dissite 000-default.conf

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
systemctl restart apache2

a2ensite snipe-it.conf

show_message "Adjust permissions and restart Apache"
chown -R www-data:www-data /var/www/snipe-it/storage
chmod -R 755 /var/www/snipe-it/storage
systemctl restart apache2

show_message "Snipe-IT setup complete!"

