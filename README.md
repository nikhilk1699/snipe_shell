## create Bash script package.sh

```
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
```
## Above Bash script used to automate the setup of the Snipe-IT asset management software on an Ubuntu server. 
- show_message(): This function is defined to display messages
- MYSQL_ROOT_PASSWORD: This is the root password for MySQL
- database credentials: The script defines the database name (DB_NAME), the database user (DB_USER), and the user's password (DB_PASSWORD). The APP_URL is also set here.
- Updating package lists and installs Apache web server (apache2).The Apache web server is started and set to start on boot.
- Apache rewrite module: The mod_rewrite module is enabled for Apache, which is often needed for web applications.
- Installed MariaDB and securing the installation: MariaDB is installed, started, and set to start on boot.
- Installed PHP and necessary extensions:installs PHP and various PHP extensions that are required for Snipe-IT to function properly.
- Downloading and moving Composer: Composer, a PHP dependency manager, is downloaded and moved to the system's bin directory for easy access.
- Creating a MySQL database and user for Snipe-IT: A MySQL database, user, and privileges are set up for Snipe-IT.
- Cloning the Snipe-IT repository: The Snipe-IT repository is cloned from GitHub into the /var/www directory.
- .env file: The .env configuration file for Snipe-IT is created, and values for the database and other settings are set within this file.
- permissions and installing dependencies: Permissions are set for the Snipe-IT directory, and the necessary dependencies are installed using Composer. The php artisan key:generate command is used to generate an application key.
- Configuring Apache: The default Apache configuration file is disabled (a2dissite 000-default.conf).
- Defining the content for the snipe-it.conf file: The Apache virtual host configuration for Snipe-IT is defined and stored in the $content variable.
- Adding the content to the snipe-it.conf file: The contents of $content are added to the Apache configuration file located at /etc/apache2/sites-available/snipe-it.conf.
- Restarting Apache: Apache is restarted to apply the new configuration.
  
# Create main.tf file for run terraform code
```
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.78.0"
    }
  }
}
````
### This block specifies the required provider, which is "azurerm" from HashiCorp, along with its version. It tells Terraform to use the Azure provider with version 3.78.0.

```
provider "azurerm" {
  features {}
}
```
### This block configures the Azure provider without any specific features.

```
locals {
  resource_group = "snipee_rp"
  location       = "North Europe"
}
```
### It defines local variables for resource group and location, making it easier to reuse these values throughout the configuration.

```
resource "tls_private_key" "linux_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
```
### This resource generates a TLS private key with RSA encryption and 4096 bits.

```
resource "local_file" "linuxkey" {
  filename = "linuxkey.pem"
  content  = tls_private_key.linux_key.private_key_pem
}
```
### It creates a local file named "linuxkey.pem" containing the private key generated by the "tls_private_key" resource.

```
resource "azurerm_resource_group" "snipee_rg" {
  name     = local.resource_group
  location = local.location
}
```
### This resource defines an Azure resource group with the name and location specified in the "locals" block.

```
resource "azurerm_virtual_network" "snipee_vnet" {
  name                = "snipee-network"
  location            = local.location
  resource_group_name = azurerm_resource_group.snipee_rg.name
  address_space       = ["10.0.0.0/16"]
}
```
### This resource creates an Azure virtual network with a specific name, location, associated resource group, and an address space.

```
resource "azurerm_subnet" "SubnetA" {
  name                 = "SubnetA"
  resource_group_name  = local.resource_group
  virtual_network_name = azurerm_virtual_network.snipee_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
```
### It defines an Azure subnet within the virtual network, specifying its name, resource group, virtual network association, and address range.

```
resource "azurerm_public_ip" "snipee_public_ip" {
  name                = "snipee-public-ip"
  resource_group_name = azurerm_resource_group.snipee_rg.name
  location            = local.location
  allocation_method   = "Static"
}
```
### This resource creates a static Azure public IP address in the specified resource group and location.

```
resource "azurerm_network_interface" "snipee_interface" {
  name                = "snipee-interface"
  location            = local.location
  resource_group_name = azurerm_resource_group.snipee_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.snipee_public_ip.id
  }
}
```
### This resource defines an Azure network interface card (NIC) associated with a subnet and public IP address. It's named snipee-interface.

```
resource "azurerm_network_security_group" "snipee_nsg" {
  name                = "snipee-SecurityGroup1"
  location            = local.location
  resource_group_name = azurerm_resource_group.snipee_rg.name

  security_rule {
    name                       = "all-traffic"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
```
### resource creates a network security group with a rule allowing all inbound traffic.

```
resource "azurerm_linux_virtual_machine" "linux_vm" {
  name                = "linuxvm"
  resource_group_name = local.resource_group
  location            = local.location
  size                = "Standard_B1s"
  admin_username      = "linuxusr"
  network_interface_ids = [
    azurerm_network_interface.snipee_interface.id,
  ]
  admin_ssh_key {
    username   = "linuxusr"
    public_key = tls_private_key.linux_key.public_key_openssh
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  provisioner "file" {
    source      = "package.sh"
    destination = "/home/linuxusr/package.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "ls -lh",
      "chmod 777 ./package.sh",
      "./package.sh",
    ]
  }

  provisioner "local-exec" {
    command = "echo ${azurerm_public_ip.snipee_public_ip.ip_address} >> local.txt"
  }

  connection {
    type        = "ssh"
    user        = "linuxusr"
    host        = azurerm_public_ip.snipee_public_ip.ip_address
    private_key = file(local_file.linuxkey.filename)
  }

  depends_on = [
    azurerm_network_interface.snipee_interface,
    tls_private_key.linux_key,
  ]
}
```

### This resource defines an Azure Linux virtual machine with various settings, including the VM size, run pacakage.sh script, admin username, SSH key, OS disk properties, and provisioning steps. It also sets up a connection to the VM using the SSH private key, runs some provisioner steps, and depends on other resources like the network interface and private key.


## Run this terraform script, open terminal run following cmd:
```
$az login #login into az cli accoount
$ terraform init # This command initializes a new or existing Terraform working directory.It downloads the provider plugins and modules specified in your configuration. It sets up the necessary backend configuration, such as remote state storage or local configuration.
$ terraform validate #This command is used to check the syntax and structure of your Terraform configuration files.
$ terraform plan # preview the changes Terraform will make.
$ terraform apply -auto-approve # This command is used to create or update infrastructure according to your Terraform configuration.
terraform destroy This command is used to  destroy t:whe infrastructure created by Terraform.
```


![image](https://github.com/nikhilk1699/snipe_shell/assets/109533285/1eb57117-8042-4db0-8530-4ccc2c22954c)

![image](https://github.com/nikhilk1699/snipe_shell/assets/109533285/76bd4b75-8c14-436d-943d-c833551e5dc0)

![image](https://github.com/nikhilk1699/snipe_shell/assets/109533285/dea4960b-4cb2-4432-b78d-41d0f71b8a6b)











