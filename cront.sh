#!/bin/bash

# Configuration
TARGET_HOST="nagios.local"
EMAIL_RECIPIENT="desmapangou@gmail.com"
CHECK_INTERVAL=5

# Configuration SMTP
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT="587"
SMTP_USER="mapsondeis@gmail.com"
SMTP_PASSWORD="ukia eefd kzyw afax"  # Utiliser un mot de passe d'application pour Gmail
SMTP_FROM="mapsondeis@gmail.com"




# Fonction pour envoyer un email via SMTP
send_mail() {
    local subject="$1"
    local body="$2"
    
    # Utilisation de swaks pour l'envoi SMTP
    swaks --from "$SMTP_FROM" \
          --to "$EMAIL_RECIPIENT" \
          --server "$SMTP_SERVER:$SMTP_PORT" \
          --auth LOGIN \
          --auth-user "$SMTP_USER" \
          --auth-password "$SMTP_PASSWORD" \
          --tls \
          --header "Subject: $subject" \
          --body "$body"
}

# Fonction pour vérifier la connectivité
check_host() {
    if ping -c 1 $TARGET_HOST >/dev/null 2>&1; then
        echo "SUCCESS: $TARGET_HOST est accessible - $(date)"
        return 0
    else
        EMAIL_BODY="
Bonjour,

Une alerte a été détectée sur le système de surveillance :

Hôte : $TARGET_HOST
Date : $(date)
Statut : INACCESSIBLE
Action : Vérification ping échouée

Ceci est un message automatique généré par le système de surveillance.
Merci de vérifier l'état du serveur dès que possible.

Cordialement,
System Monitor
"
        send_mail "ALERTE CRITIQUE: $TARGET_HOST inaccessible" "$EMAIL_BODY"
        return 1
    fi
}

# Installation de swaks si non présent
if ! command -v swaks &> /dev/null; then
    echo "Installation de swaks..."
    sudo apt-get update && sudo apt-get install -y swaks
fi

# Création de l'entrée cron avec MAILTO=""
(crontab -l 2>/dev/null | grep -v "$(basename $0)"; echo "MAILTO=\"\""; echo "*/$CHECK_INTERVAL * * * * $(pwd)/$(basename $0)") | crontab -

# Exécution du check
check_host

echo "Script de surveillance configuré!"
echo "Une vérification sera effectuée toutes les $CHECK_INTERVAL minutes"
echo "Les alertes seront envoyées à $EMAIL_RECIPIENT via SMTP"
