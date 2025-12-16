#!/bin/bash

# Script de provisionnement pour Finance
# CentOS Stream 9

set -e

echo "================================================"
echo "Début de l'installation du site Finance"
echo "================================================"

# Mise à jour
echo "Mise à jour du système..."
dnf update -y

# Configuration du nom d'hôte
echo "Configuration du nom d'hôte..."
echo "10.2.33.21 finance" >> /etc/hosts

# Installation d'Apache et outils
echo "Installation des paquets..."
dnf install -y \
    httpd \
    wget \
    unzip \
    vim \
    net-tools \
    firewalld

# Démarrage des services
echo "Démarrage des services..."
systemctl start httpd
systemctl enable httpd
systemctl start firewalld
systemctl enable firewalld

# Configuration du firewall
echo "Configuration du firewall..."
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# Téléchargement du template
echo "Téléchargement du template Finance..."
mkdir -p /tmp/finance-template
cd /tmp/finance-template

wget -q https://www.tooplate.com/zip-templates/2135_mini_finance.zip
unzip -o 2135_mini_finance.zip

# Déploiement du site
echo "Déploiement du site..."
rm -rf /var/www/html/*
cp -r 2135_mini_finance/* /var/www/html/

# Configuration des permissions
echo "Configuration des permissions..."
chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html

# Création d'un fichier info
cat > /var/www/html/info.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Info - Site Finance</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .container { max-width: 800px; margin: 0 auto; }
        .info-box { background: #f5f5f5; padding: 20px; border-radius: 5px; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Site Finance - Information</h1>
        <div class="info-box">
            <h2>Serveur: finance</h2>
            <p>IP: 10.2.33.21</p>
            <p>Système: CentOS Stream 9</p>
            <p>Service: Apache HTTP Server</p>
            <p>Template: Mini Finance by Tooplate</p>
            <p>Date d'installation: $(date)</p>
        </div>
    </div>
</body>
</html>
EOF

# Redémarrage d'Apache
systemctl restart httpd

# Nettoyage
rm -rf /tmp/finance-template

echo "================================================"
echo "Site Finance installation terminée!"
echo ""
echo "Accès:"
echo "  Site principal: http://10.2.33.21"
echo "  Page info:      http://10.2.33.21/info.html"
echo "================================================"