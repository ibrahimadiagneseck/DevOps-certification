#!/bin/bash

# SECTION 1 : INSTALLATION
# -------------------------------------------------------------------------------
sudo dnf install epel-release -y
sudo dnf install memcached -y

# SECTION 2 : CONFIGURATION SÉCURISÉE
# -------------------------------------------------------------------------------
# Configurer memcached pour écouter sur le réseau privé Vagrant uniquement
sudo tee /etc/sysconfig/memcached > /dev/null <<EOF
PORT="11211"
USER="memcached"
MAXCONN="1024"
CACHESIZE="64"
OPTIONS="-l 192.168.56.14"
EOF

# SECTION 3 : DÉMARRAGE ET CONFIGURATION DU PARC-FEU
# -------------------------------------------------------------------------------
sudo systemctl start memcached
sudo systemctl enable memcached

sudo systemctl start firewalld
sudo systemctl enable firewalld
firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='192.168.56.0/24' port port='11211' protocol='tcp' accept"
firewall-cmd --reload

# SECTION 4 : VÉRIFICATION
# -------------------------------------------------------------------------------
echo "==========================================="
echo "MEMCACHED CONFIGURATION"
echo "==========================================="
echo "Status: $(systemctl is-active memcached)"
echo "Listening on: 192.168.56.14:11211"
echo "==========================================="