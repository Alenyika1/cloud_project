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
TO do that create a project directory and ```vagrant init``` and edit the configuration file with the following
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

The first step is to install all the neccessary lamp stack and it dependencies needed to deploy your application
```bash
# Install Apache2
echo "Installing Apache2..."
sudo apt-get install -y apache2
# Install MySQL Server
echo "Installing MySQL Server..."
sudo apt-get install -y mysql-server
# Install PHP 8.2 and necessary PHP extensions
echo "Installing PHP 8.2 and necessary PHP extensions..."
sudo add-apt-repository ppa:ondrej/php
sudo apt-get update -y
sudo apt-get install -y php8.2 php8.2-common php8.2-cli php8.2-gd php8.2-curl php8.2-mysql php8.2-zip php-xml
```

- The next is to download and install Composer, a tool for dependency management in PHP.
```bash
# Install Composer
echo "Installing Composer..."
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
```
- clone Laravel application from GitHub into the `/var/www/html/laravel` directory.
```bash
# Clone Laravel application from GitHub
echo "Cloning Laravel application from Git..."
git clone https://github.com/laravel/laravel.git /var/www/html/laravel
```
- Navigates into the project directory, installs project dependencies through Composer, sets up the environment file for Laravel, and sets necessary permissions
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
```
- Configure a .conf file for the laravel application in the /etc/apache2/sites-available directory
```bash
# Configure Apache to run the Laravel application
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
```

- Creates a MySQL database and user for the Laravel application

```bash
# Create MySQL Database and User for the Laravel app lication (Replace 'database_name', 'user' and 'password' with your actual database name, username and password)
mysql -uroot -proot <<MYSQL_SCRIPT
CREATE DATABASE laravel;
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'alenyika';
GRANT ALL PRIVILEGES ON laravel.* TO 'admin'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT
```
- Update the .env file with the the database configuration
```bash
# Update .env file with database configuration
sed -i "s/DB_DATABASE=.*/DB_DATABASE=laravel/" .env
sed -i "s/DB_USERNAME=.*/DB_USERNAME=admin/" .env
sed -i "s/DB_PASSWORD=.*/DB_PASSWORD=alenyika/" .env
```
- Configure the Apache2 service to deploy the laravel by disabling the default configuration and enabling the new laravel configuration. Rewrite after and restart the apache2 service.

```bash
# Disable the default configuration file
sudo a2dissite 000-default.conf

# enable the laravel configuration in Apache
sudo a2ensite laravel.conf

# Enable Apache mod_rewrite
sudo a2enmod rewrite

# Restart Apache
sudo systemctl restart apache2
```
- Start Laravel server deployement
```bash
# Start local server deployement
php artisan migrate # this start the database migration as configured in the .env file and mysql settings
php artisan serve

echo "LAMP Stack Installed and Configured!"
```

4. **Execute the Ansible Playbook**
- Install anisble on the master server 
```bash
sudo apt-get install ansible
```
- create an inventory file for the slave server that will be configure by the server and the slave vm ip address
```bash
nano inventory

[webservers]
192.168.58.4 ansible_ssh_user=vagrant
```
- A playbook to execute the task should be created.
the first part of the playbook is to copy the script to the slave node and set the permission so as to execute the task.
```bash
- hosts: webservers
  become: yes
  tasks:
    - name: Copy the LAMP setup script to the remote server
      copy:
        src: /home/vagrant/cloud_project/deploy_new.sh
        dest: /home/vagrant/deploy_new.sh
        mode: '0755'

    - name: Execute the LAMP setup script
      command: /home/vagrant/deploy_new.sh
      register: setup_output'
  ``` 
- Check to ensure that all services installed are running properly
```bash
    - name: Ensure the Apache service is running
      service:
        name: apache2
        state: started

    - name: Ensure the MySQL service is running
      service:
        name: mysql
        state: started
  ``` 
 - The last part is to create a cron job that check for server uptime and register the log into a file on the slave server.
```bash
  - name: Create a cron job to check server uptime
      cron:
        name: "uptime_check"
        minute: "0"
        hour: "0"
        job: "uptime >> /var/log/uptime.log"
```
- To execute the Ansible playbook, make sure that the ssh connectiion between the nodes are enabled. To do this, copy your ssh key from your master node to the slave node autorized_keys file. 
Navigate to the directory containing your playbook file in your terminal and run:

 ```bash
 ansible-playbook -i inventory deploy.yml
 ```

That's it! Your Laravel application should now be deployed on your Slave server with a LAMP stack.
