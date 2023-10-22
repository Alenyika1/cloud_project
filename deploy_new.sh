#!/bin/bash

# Update System
echo "Updating System..."
sudo apt-get update -y

# Install Apache2
echo "Installing Apache2..."
sudo apt-get install -y apache2

# Install MySQL Server
echo "Installing MySQL Server..."
sudo apt-get install -y mysql-server

# Install PHP and necessary PHP extensions
echo "Installing PHP and necessary PHP extensions..."
sudo apt-get install -y php php-common php-cli php-gd php-curl php-mysql

# Install Composer
echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Install Git
echo "Installing Git..."
sudo apt-get install git -y

# Clone Laravel application from GitHub
echo "Cloning Laravel application from Git..."
sudo git clone https://github.com/laravel/laravel.git /var/www/html/

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
</VirtualHost>" > /etc/apache2/sites-available/laravel.conf'

# Enable Apache mod_rewrite
sudo a2enmod rewrite

# Restart Apache
sudo systemctl restart apache2

# Create MySQL Database and User for the Laravel application (Replace 'database_name', 'user' and 'password' with your actual database name, username and password)
mysql -uroot -proot <<MYSQL_SCRIPT
CREATE DATABASE laravel;
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'alenyika';
GRANT ALL PRIVILEGES ON laravel.* TO 'admin'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Update .env file with database configuration
sed -i "s/DB_DATABASE=.*/DB_DATABASE=laravel/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=admin/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=alenyika/" .env

echo "LAMP Stack Installed and Configured!"
