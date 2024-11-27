#!/bin/bash

# Update system packages
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install required dependencies
echo "Installing dependencies..."
apt-get install -y apache2 \
    php \
    php-gd \
    libapache2-mod-php \
    unzip \
    curl \
    wget \
    build-essential \
    libgd-dev \
    openssl \
    libssl-dev \
    apache2-utils \
    autoconf \
    gcc \
    libc6 \
    make \
    apache2-dev \
    php-mysql \
    libmcrypt-dev \
    libssl-dev \
    bc \
    gawk \
    dc \
    snmp \
    libnet-snmp-perl \
    gettext

# Create Nagios user and group
echo "Creating Nagios user and group..."

useradd nagios
usermod -a -G nagios www-data

# Download and install Nagios Core
echo "Downloading and installing Nagios Core..."
cd /tmp
wget https://github.com/NagiosEnterprises/nagioscore/archive/nagios-4.4.6.tar.gz
tar xzf nagios-4.4.6.tar.gz
cd nagioscore-nagios-4.4.6

# Configure and compile Nagios
./configure --with-httpd-conf=/etc/apache2/sites-enabled
make all
make install
make install-daemoninit
make install-commandmode
make install-config
make install-webconf

# Download and install Nagios Plugins
echo "Downloading and installing Nagios Plugins..."
cd /tmp
wget https://github.com/nagios-plugins/nagios-plugins/archive/release-2.3.3.tar.gz
tar xzf release-2.3.3.tar.gz
cd nagios-plugins-release-2.3.3
./tools/setup
./configure
make
make install

# Configure Apache
echo "Configuring Apache..."
a2enmod rewrite
a2enmod cgi

# Create nagiosadmin user for web interface
echo "Creating nagiosadmin user..."
htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

# Set permissions
echo "Setting permissions..."
chown -R nagios:nagios /usr/local/nagios/etc
chown -R nagios:nagios /usr/local/nagios/var

# Restart Apache
echo "Restarting Apache..."
systemctl restart apache2

# Start Nagios
echo "Starting Nagios..."
systemctl start nagios

# Enable services to start on boot
echo "Enabling services..."
systemctl enable apache2
systemctl enable nagios

echo "Nagios installation completed!"
echo "You can access the Nagios web interface at: http://your-server-ip/nagios"
echo "Use 'nagiosadmin' as username and the password you set during installation"
