#!/bin/bash

# Update System
echo "Updating System..."
sudo apt-get update -y

# Add PHP repository for PHP 8.2
sudo add-apt-repository ppa:ondrej/php -y
sudo apt-get update -y

# Install Apache2
echo "Installing Apache2..."
sudo apt-get install -y apache2

# Install Zip and Unzip Tools
sudo apt-get install -y zip unzip

# Install PHP 8.2 and necessary PHP extensions
echo "Installing PHP 8.2 and necessary PHP extensions..."
<<<<<<< HEAD
sudo apt-get install -y php8.2 php8.2-common php8.2-cli php8.2-gd php8.2-curl php8.2-mysql php-xml
=======
sudo apt-get install -y php8.2 php8.2-common php8.2-cli php8.2-gd php8.2-curl php8.2-mysql php8.2-zip php-xml

# Install MySQL Server
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password alenyika'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password alenyika'
sudo apt-get install -y mysql-server

# Secure the MySQL installation
sudo mysql_secure_installation <<EOF

y
alenyika
alenyika
y
y
y
y
EOF

>>>>>>> 78709c15d5ad0f69229adf88ba671e8596e7a6c4

# Install Composer
echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# Clone Laravel application from GitHub
echo "Cloning Laravel application from Git..."
sudo git clone https://github.com/laravel/laravel.git /var/www/html/laravel

# Navigate to the project directory
sudo chown -R vagrant:vagrant /var/www/html/laravel/
cd /var/www/html/laravel

# Configure environment file for Laravel
sudo cp .env.example .env

# Install dependencies through Composer
echo "Installing project dependencies..."
composer install
sudo php artisan key:generate

# Set necessary permissions
sudo chgrp -R www-data storage bootstrap/cache
sudo chmod -R ug+rwx storage bootstrap/cache

# Configure Apache to run the laravel Application
echo "<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/laravel/public

    <Directory /var/www/html/laravel/>
      Options +FollowSymlinks
      AllowOverride All
      Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>" | sudo tee /etc/apache2/sites-available/laravel.conf


# Create MySQL Database and User for the Laravel application
# (Replace 'database_name', 'user', and 'password' with your actual database name, username, and password)
mysql -proot <<MYSQL_SCRIPT
CREATE DATABASE laravel;
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'alenyika';
GRANT ALL PRIVILEGES ON laravel.* TO 'admin'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Update .env file with database configuration
sudo sed -i "s/DB_DATABASE=.*/DB_DATABASE=laravel/" .env
sudo sed -i "s/DB_USERNAME=.*/DB_USERNAME=admin/" .env
sudo sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=alenyika/" .env

# This starts the database migration as configured in the .env file and MySQL settings
php artisan migrate 

# Disable the default configuration file
sudo a2dissite 000-default.conf

# enable the laravel configuration in Apache
sudo a2ensite laravel.conf

# Enable Apache mod_rewrite
sudo a2enmod rewrite

# Restart Apache
sudo systemctl restart apache2

# Start local server deployment
php artisan serve

echo "LAMP Stack Installed and Configured with PHP 8.2!"
