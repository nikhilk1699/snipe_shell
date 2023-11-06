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
  size                = "Standard_D2s_v3"
  admin_username      = "linuxusr"
  network_interface_ids = [azurerm_network_interface.snipee_interface.id]
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
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
  provisioner "file" {
    source      = "package.sh"
    destination = "/home/linuxusr/package.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "ls -lh",
      "sudo chmod 700 ./package.sh",
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

### This resource defines an Azure Linux virtual machine with various settings, including the VM size, admin username, SSH key, OS disk properties, and provisioning steps. It also sets up a connection to the VM using the SSH private key, runs some provisioner steps, and depends on other resources like the network interface and private key.


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











