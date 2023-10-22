# Laravel Application Deployment Guide

This guide provides step-by-step instructions on how to automate the deployment of a Laravel application using a bash script and Ansible.

## Prerequisites

- Ubuntu-based servers named "Master" and "Slave"
- Ansible installed on your local machine
- Git installed on your local machine
- A Laravel application hosted on GitHub

## Steps

1. **Create a Bash Script for LAMP Stack Deployment**

    Create a bash script named `deploy.sh` in the home directory of your Master server. This script will install and configure the LAMP (Linux, Apache, MySQL, PHP) stack, clone your Laravel application from GitHub, and set up a MySQL database for the application.


```bash
# Update System
echo "Updating System..."
sudo apt-get update -y
```
This part updates the package lists for upgrades and new package installations.

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
sudo chgrp -R www-data storage bootstrap/cache
sudo chmod -R ug+rwx storage bootstrap/cache

# Configure Apache to run the Laravel application
sudo sh -c 'echo "<VirtualHost *:80>
    DocumentRoot /var/www/html/laravel/public
    <Directory /var/www/html/laravel/>
        AllowOverride All
    </Directory>
</VirtualHost>" > /etc/apache2/sites-available/000-default.conf'

# Enable Apache mod_rewrite
sudo a2enmod rewrite

# Restart Apache
sudo service apache2 restart

# Create MySQL Database and User for the Laravel application (Replace 'database_name', 'user' and 'password' with your actual database name, username and password)
mysql -uroot -proot <<MYSQL_SCRIPT
CREATE DATABASE laravel;
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'alenyika';
GRANT ALL PRIVILEGES ON laravel.* TO 'admin'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "LAMP Stack Installed and Configured!"
```
The rest of the script navigates into the project directory, installs project dependencies through Composer, sets up the environment file for Laravel, sets necessary permissions, configures Apache to serve the Laravel application, enables mod_rewrite for URL rewriting support, restarts Apache to apply changes, creates a MySQL database and user for the Laravel application, and finally prints a success message.

3. **Execute the Ansible Playbook**

   To execute the Ansible playbook, navigate to the directory containing your playbook file in your terminal and run:

   ```bash
   ansible-playbook playbook.yml
   ```

That's it! Your Laravel application should now be deployed on your Slave server with a LAMP stack.