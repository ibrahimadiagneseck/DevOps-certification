#!/bin/bash
set -e

# Variables configurables
RABBITMQ_USER="vprofile_app"
RABBITMQ_PASS=$(openssl rand -base64 16)
TRUSTED_NETWORK="192.168.56.0/24"

# SECTION 1 : INSTALLATION
# -------------------------------------------------------------------------------
sudo yum install epel-release -y
sudo yum update -y
sudo yum install wget -y
cd /tmp/
dnf -y install centos-release-rabbitmq-38
dnf --enablerepo=centos-rabbitmq-38 -y install rabbitmq-server

# SECTION 2 : CONFIGURATION DU PARC-FEU
# -------------------------------------------------------------------------------
systemctl start firewalld
systemctl enable firewalld
firewall-cmd --permanent --add-port=5672/tcp
firewall-cmd --permanent --add-port=15672/tcp
firewall-cmd --reload

# SECTION 3 : DÉMARRAGE ET CONFIGURATION RABBITMQ
# -------------------------------------------------------------------------------
sudo systemctl enable --now rabbitmq-server

# Configuration pour permettre les connexions distantes
sudo tee /etc/rabbitmq/rabbitmq.conf > /dev/null <<EOF
loopback_users = none
default_user = ${RABBITMQ_USER}
default_pass = ${RABBITMQ_PASS}
EOF

# Création de l'utilisateur
sudo rabbitmqctl add_user "${RABBITMQ_USER}" "${RABBITMQ_PASS}"
sudo rabbitmqctl set_user_tags "${RABBITMQ_USER}" administrator
sudo rabbitmqctl set_permissions -p / "${RABBITMQ_USER}" ".*" ".*" ".*"

# Redémarrer pour appliquer la configuration
sudo systemctl restart rabbitmq-server

# SECTION 4 : AFFICHAGE DES INFORMATIONS
# -------------------------------------------------------------------------------
echo "==========================================="
echo "RABBITMQ CONFIGURATION"
echo "==========================================="
echo "Username: ${RABBITMQ_USER}"
echo "Password: ${RABBITMQ_PASS}"
echo "Management Interface: http://192.168.56.16:15672"
echo "Connection String: amqp://${RABBITMQ_USER}:${RABBITMQ_PASS}@192.168.56.16:5672"
echo "==========================================="