#!/bin/bash

# Configuration de base
NAGIOS_SERVER="nagios.local"  # Adresse du serveur Nagios
HOST_NAME=$(hostname)          # Nom de l'hôte à surveiller
HOST_IP=$(hostname -I | awk '{print $1}')  # IP de l'hôte

# Création du répertoire de configuration
echo "Création du répertoire de configuration..."
sudo mkdir -p /usr/local/nagios/etc/servers/

# Création du fichier de configuration pour cet hôte
echo "Création de la configuration pour $HOST_NAME..."
cat << EOF | sudo tee /usr/local/nagios/etc/servers/${HOST_NAME}.cfg
define host {
    use                     linux-server
    host_name              ${HOST_NAME}
    alias                  ${HOST_NAME}
    address                ${HOST_IP}
    max_check_attempts     5
    check_period           24x7
    notification_interval  30
    notification_period    24x7
}

define service {
    use                    generic-service
    host_name              ${HOST_NAME}
    service_description    PING
    check_command          check_ping!100.0,20%!500.0,60%
}

define service {
    use                    generic-service
    host_name              ${HOST_NAME}
    service_description    Current Load
    check_command          check_load!5.0,4.0,3.0!10.0,6.0,4.0
}

define service {
    use                    generic-service
    host_name              ${HOST_NAME}
    service_description    Current Users
    check_command          check_users!20!50
}

define service {
    use                    generic-service
    host_name              ${HOST_NAME}
    service_description    Disk Space
    check_command          check_disk!20%!10%!/
}
EOF

# Installation des plugins NRPE
echo "Installation des plugins NRPE..."
sudo apt-get update
sudo apt-get install -y nagios-nrpe-server nagios-plugins

# Configuration de NRPE
echo "Configuration de NRPE..."
sudo sed -i "s/allowed_hosts=127.0.0.1/allowed_hosts=127.0.0.1,${NAGIOS_SERVER}/" /etc/nagios/nrpe.cfg

# Redémarrage du service NRPE
echo "Redémarrage du service NRPE..."
sudo systemctl restart nagios-nrpe-server
sudo systemctl enable nagios-nrpe-server

echo "Configuration terminée!"
echo "Instructions importantes:"
echo "1. Assurez-vous que le serveur Nagios ($NAGIOS_SERVER) peut accéder à cet hôte"
echo "2. Vérifiez que le port 5666 (NRPE) est ouvert dans le pare-feu"
echo "3. Sur le serveur Nagios, importez la configuration depuis: /usr/local/nagios/etc/servers/${HOST_NAME}.cfg"
echo "4. Redémarrez le service Nagios sur le serveur principal"
