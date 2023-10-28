# Laravel Application Deployment Guide

This guide provides step-by-step instructions on how to automate the deployment of a Laravel application using a bash script and Ansible.

## Prerequisites

- Ubuntu-based servers named "Master" and "Slave"
- Vagrant Insatlled on the loacl machine
- Ansible installed on your local machine
- Git installed on your local machine
- A Laravel application hosted on GitHub

## Steps
1. **Create a vahrant configuration file to provision the Master and Slave node and the appropiate configuration needed for the cluster**

 ```bash
 Vagrant.configure("2") do |config|
  # Configure the "Master" VM
  config.vm.define "master" do |master|
    master.vm.box = "ubuntu/focal64"  # Define the base box for the "Master" VM
    master.vm.hostname = "master"  # Set the hostname for the "Master" VM
    master.vm.network "private_network", ip: "192.168.58.2"  # Assign a private network IP to the "Master" VM
  end

  # Configure the "Slave" VM
  config.vm.define "slave" do |slave|
    slave.vm.box = "ubuntu/focal64"  # Define the base box for the "Slave" VM
    slave.vm.hostname = "slave"  # Set the hostname for the "Slave" VM
    slave.vm.network "private_network", ip: "192.168.58.4"  # Assign a private network IP to the "Slave" VM
  end

  # Customize provider settings (VirtualBox in this example)
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"  # Adjust the value to allocate more memory to each VM
  end
end
 ```

2. **Create a Bash Script for LAMP Stack Deployment**

    Create a bash script named `deploy.sh` in the home directory of your Master server. This script will install and configure the LAMP (Linux, Apache, MySQL, PHP) stack, clone your Laravel application from GitHub, and set up a MySQL database for the application.


```bash
# Install Apache2
echo "Installing Apache2..."
sudo apt-get install -y apache2
```
This part installs Apache2, a popular open-source web server.

```bash
# Install MySQL Server
echo "Installing MySQL Server..."
sudo apt-get install -y mysql-server
```
This part installs MySQL server, a widely used database management system.

```bash
# Install PHP 8.2 and necessary PHP extensions
echo "Installing PHP 8.2 and necessary PHP extensions..."
sudo add-apt-repository ppa:ondrej/php
sudo apt-get update -y
sudo apt-get install -y php8.2 php8.2-common php8.2-cli php8.2-gd php8.2-curl php8.2-mysql
```
This part adds a Personal Package Archive (PPA) repository that contains PHP 8.2, updates the package lists again, and then installs PHP 8.2 along with some common extensions.

```bash
# Install Composer
echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
```
This part downloads and installs Composer, a tool for dependency management in PHP.

```bash
# Clone Laravel application from GitHub
echo "Cloning Laravel application from Git..."
git clone https://github.com/laravel/laravel.git /var/www/html/laravel
```
This part clones a Laravel application from GitHub into the `/var/www/html/laravel` directory.

```bash
# Navigate to the project directory
cd /var/www/html/laravel

# Install dependencies through Composer
echo "Installing project dependencies..."
composer install

# Configure environment file for Laravel
cp .env.example .env
php artisan key:generate

# Set necessary permissions
oobcsudo chgrp -R www-data storage bootstrap/cache
sudo chmod -R ug+rwx storage bootstrap/cache
```
The script navigates into the project directory, installs project dependencies through Composer, sets up the environment file for Laravel, and sets necessary permissions

```bash
# Configure Apache to run the Laravel application
sudo sh -c 'echo "<VirtualHost *:80>
    DocumentRoot /var/www/html/laravel/public
    <Directory /var/www/html/laravel/>
        AllowOverride All
    </Directory>
</VirtualHost>" > /etc/apache2/sites-available/laravel.conf'

# Enable Apache mod_rewrite
sudo a2enmod rewrite

# Restart Apache
sudo systemctl restart apache2
```
The above part of the deploy.sh script is to configures Apache to serve the Laravel application, enables mod_rewrite for URL rewriting support, and restarts Apache to apply changes

```bash
# Create MySQL Database and User for the Laravel app lication (Replace 'database_name', 'user' and 'password' with your actual database name, username and password)
mysql -uroot -proot <<MYSQL_SCRIPT
CREATE DATABASE laravel;
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'alenyika';
GRANT ALL PRIVILEGES ON laravel.* TO 'admin'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
```
This part of the script creates a MySQL database and user for the Laravel application
```bash
# Update .env file with database configuration
sed -i "s/DB_DATABASE=.*/DB_DATABASE=laravel/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=admin/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=alenyika/" .env
```
This part of the script will update the .env file with the configured mysql database
```bash
# Start local server deployement
php artisan migrate # this start the database migration as configured in the .env file and mysql settings
php artisan serve

echo "LAMP Stack Installed and Configured!"
```
The last step is to migrate the database configured in the .env file and start a local development server. 

4. **Execute the Ansible Playbook**
    Create 

   To execute the Ansible playbook, make sure that the ssh connectiion between the nodes are enabled. To do this, copy your ssh key from your master node to the slave node autorized_keys file. Navigate to the directory containing your playbook file in your terminal and run:

   ```bash
   ansible-playbook deploy.yml
   ```

That's it! Your Laravel application should now be deployed on your Slave server with a LAMP stack.
