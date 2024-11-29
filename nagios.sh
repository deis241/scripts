#!/bin/bash

# Vérifier si le script est exécuté en tant que root
if [ "$EUID" -ne 0 ]; then 
    echo "Ce script doit être exécuté en tant que root"
    exit 1
fi

# Update system packages
echo "Mise à jour des paquets système..."
apt-get update
apt-get upgrade -y

# Install required dependencies
echo "Installation des dépendances..."
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
echo "Création de l'utilisateur et du groupe Nagios..."
useradd nagios
usermod -a -G nagios www-data

# Download and install Nagios Core
echo "Téléchargement et installation de Nagios Core..."
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
echo "Téléchargement et installation des plugins Nagios..."
cd /tmp
wget https://github.com/nagios-plugins/nagios-plugins/archive/release-2.3.3.tar.gz
tar xzf release-2.3.3.tar.gz
cd nagios-plugins-release-2.3.3
./tools/setup
./configure
make
make install

# Configure Apache
echo "Configuration d'Apache..."
a2enmod rewrite
a2enmod cgi
a2enmod ssl

# Configuration du ServerName Apache
echo "Configuration du ServerName Apache..."
echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Création du certificat SSL auto-signé
echo "Création du certificat SSL..."
mkdir -p /etc/ssl/nagios
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/nagios/nagios.key \
    -out /etc/ssl/nagios/nagios.crt \
    -subj "/C=FR/ST=Paris/L=Paris/O=Nagios/OU=Monitoring/CN=nagios.local"

# Création du virtual host Nagios
echo "Création du virtual host Nagios..."
cat > /etc/apache2/sites-available/nagios.conf << 'EOL'
# Configuration HTTP (redirection vers HTTPS)
<VirtualHost *:80>
    ServerName nagios.local
    Redirect permanent / https://nagios.local/
</VirtualHost>

# Configuration HTTPS
<VirtualHost *:443>
    ServerAdmin webmaster@localhost
    ServerName nagios.local
    DocumentRoot /usr/local/nagios/share

    SSLEngine on
    SSLCertificateFile /etc/ssl/nagios/nagios.crt
    SSLCertificateKeyFile /etc/ssl/nagios/nagios.key

    <Directory "/usr/local/nagios/share">
        Options None
        AllowOverride None
        Require all granted
    </Directory>

    ScriptAlias /nagios/cgi-bin "/usr/local/nagios/sbin"
    <Directory "/usr/local/nagios/sbin">
        Options ExecCGI
        AllowOverride None
        Require all granted
        SSLRequireSSL
    </Directory>

    Alias /nagios "/usr/local/nagios/share"

    ErrorLog ${APACHE_LOG_DIR}/nagios_error.log
    CustomLog ${APACHE_LOG_DIR}/nagios_access.log combined
</VirtualHost>
EOL

# Activer les configurations Apache
a2ensite nagios.conf
a2dissite 000-default.conf

# Create nagiosadmin user for web interface
echo "Création de l'utilisateur nagiosadmin..."
htpasswd -c /usr/local/nagios/etc/htpasswd.users nagiosadmin

# Set permissions
echo "Configuration des permissions..."
chown -R nagios:nagios /usr/local/nagios/etc
chown -R nagios:nagios /usr/local/nagios/var
chmod 644 /usr/local/nagios/etc/htpasswd.users

# Configurer le pare-feu
echo "Configuration du pare-feu..."
if command -v ufw >/dev/null 2>&1; then
    ufw allow 80/tcp
    ufw allow 443/tcp
fi

# Restart Apache
echo "Redémarrage d'Apache..."
systemctl restart apache2

# Start Nagios
echo "Démarrage de Nagios..."
systemctl start nagios

# Enable services to start on boot
echo "Activation des services au démarrage..."
systemctl enable apache2
systemctl enable nagios

# Ajouter l'entrée dans /etc/hosts
echo "127.0.0.1 nagios.local" >> /etc/hosts

echo "Installation de Nagios terminée!"
echo "Instructions importantes:"
echo "1. Sur votre ordinateur distant, ajoutez cette ligne dans /etc/hosts:"
echo "   $(hostname -I | awk '{print $1}') nagios.local"
echo "2. Accédez à l'interface web via: https://nagios.local/nagios"
echo "3. Utilisez 'nagiosadmin' comme nom d'utilisateur et le mot de passe défini pendant l'installation"
echo "4. Le certificat SSL est auto-signé, vous devrez donc l'accepter dans votre navigateur"
echo "5. Pour plus de sécurité, pensez à:"
echo "   - Configurer un certificat SSL valide"
echo "   - Restreindre l'accès par IP dans la configuration Apache"
echo "   - Modifier régulièrement le mot de passe de nagiosadmin"
