#!/bin/bash

# Configuration
TARGET_HOST="nagios.local"  # L'adresse à surveiller
EMAIL_RECIPIENT="desmapangou@gmail.com"  # L'adresse email qui recevra les alertes
CHECK_INTERVAL=5  # Intervalle en minutes entre chaque vérification

# Fonction pour vérifier la connectivité
check_host() {
    if ping -c 1 $TARGET_HOST >/dev/null 2>&1; then
        echo "SUCCESS: $TARGET_HOST est accessible - $(date)"
        return 0
    else
        # Création d'un message plus détaillé
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
        echo "$EMAIL_BODY" | mail -s "ALERTE CRITIQUE: $TARGET_HOST inaccessible" $EMAIL_RECIPIENT
        return 1
    fi
}

# Création de l'entrée cron
(crontab -l 2>/dev/null; echo "*/$CHECK_INTERVAL * * * * $(pwd)/$(basename $0)") | crontab -

# Exécution du check
check_host

echo "Script de surveillance configuré!"
echo "Une vérification sera effectuée toutes les $CHECK_INTERVAL minutes"
echo "Les alertes seront envoyées à $EMAIL_RECIPIENT"
