#!/bin/bash

# Script d'installation des utilitaires de bureau à distance pour Linux

# Mise à jour des paquets
echo "Mise à jour des paquets..."
sudo apt update && sudo apt upgrade -y

# Installation de XRDP (Remote Desktop Protocol)
echo "Installation de XRDP..."
sudo apt install xrdp -y

# Installation de XFCE4 (environnement de bureau léger)
echo "Installation de XFCE4..."
sudo apt install xfce4 -y

# Configuration de XRDP pour utiliser XFCE4
echo "Configuration de XRDP..."
echo xfce4-session > ~/.xsession

# Redémarrage du service XRDP
echo "Redémarrage du service XRDP..."
sudo systemctl restart xrdp

# Installation de VNC Server (alternative)
echo "Installation de VNC Server..."
sudo apt install tightvncserver -y

# Installation de SSH Server
echo "Installation de SSH Server..."
sudo apt install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh

# Affichage des informations réseau
echo "Informations réseau:"
ip addr show | grep inet

echo "Installation terminée!"
echo "Vous pouvez maintenant vous connecter à distance via:"
echo "- RDP (port 3389)"
echo "- VNC (port 5900)"
echo "- SSH (port 22)"

# Génération des clés SSH
echo "Génération des clés SSH..."
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
    echo "Nouvelles clés SSH générées"
else
    echo "Les clés SSH existent déjà"
fi

# Affichage de la clé publique
echo "Votre clé publique SSH:"
cat ~/.ssh/id_rsa.pub


