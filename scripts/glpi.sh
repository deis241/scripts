#!/bin/bash

# Script d'installation automatisée de GLPI sur Ubuntu

# === Configuration ===
DB_NAME="glpidb"
DB_USER="glpiuser"
DB_PASS="Nsi@Pass"

echo "🔄 Mise à jour du système..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installation des dépendances Apache, MariaDB, PHP..."
sudo apt install -y apache2 mariadb-server php php-mysql php-curl php-intl php-xmlrpc php-gd php-xml php-mbstring php-ldap php-imap php-apcu php-zip php-bz2 php-soap wget unzip

echo "⚙️ Activation des services..."
sudo systemctl enable apache2
sudo systemctl enable mariadb
sudo systemctl start apache2
sudo systemctl start mariadb

echo "🔐 Sécurisation de MariaDB..."
sudo mysql_secure_installation

echo "🛠 Création de la base de données et utilisateur GLPI..."
sudo mysql -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
sudo mysql -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
sudo mysql -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

echo "⬇️ Téléchargement de GLPI..."
cd /tmp
wget https://github.com/glpi-project/glpi/releases/latest/download/glpi.tgz

echo "📂 Décompression et déploiement..."
sudo tar -xvzf glpi.tgz -C /var/www/
sudo chown -R www-data:www-data /var/www/glpi
sudo chmod -R 755 /var/www/glpi

echo "🌐 Configuration d'Apache..."
sudo tee /etc/apache2/sites-available/glpi.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerAdmin admin@localhost
    DocumentRoot /var/www/glpi
    ServerName glpi.local

    <Directory /var/www/glpi>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/glpi_error.log
    CustomLog \${APACHE_LOG_DIR}/glpi_access.log combined
</VirtualHost>
EOF

sudo a2enmod rewrite
sudo a2ensite glpi.conf
sudo systemctl reload apache2

echo "✅ GLPI installé. Terminez la configuration via http://<ip>/"

# === Étapes post-installation ===

read -p "❗ Avez-vous terminé l'installation via le navigateur ? (y/n) " CONFIRM

if [ "$CONFIRM" == "y" ]; then
    echo "🧹 Suppression du fichier d'installation..."
    sudo rm -rf /var/www/glpi/install/install.php

    echo "📁 Renommage du dossier install en install_bak (sécurité)..."
    sudo mv /var/www/glpi/install /var/www/glpi/install_bak

    echo "🔒 Sécurisation du dossier files/..."
    sudo chown -R www-data:www-data /var/www/glpi/files
    sudo chmod -R 750 /var/www/glpi/files

    echo "✅ Configuration post-installation terminée."
else
    echo "⚠️ Terminez d'abord l'installation via le navigateur avant de relancer ce script."
fi

echo "🔐 Infos connexion base de données pour l'installation web GLPI :"
echo "  ➤ Base : $DB_NAME"
echo "  ➤ Utilisateur : $DB_USER"
echo "  ➤ Mot de passe : $DB_PASS"
