#!/bin/bash

# Script de provisionnement pour WordPress
# Ubuntu 20.04 LTS

set -e  # Arrêter en cas d'erreur

echo "================================================"
echo "Début de l'installation de WordPress"
echo "================================================"

# Mise à jour du système
echo "Mise à jour des paquets..."
apt-get update -y
apt-get upgrade -y

# Installation des dépendances
echo "Installation des paquets nécessaires..."
apt-get install -y \
    apache2 \
    mysql-server \
    php \
    libapache2-mod-php \
    php-mysql \
    php-curl \
    php-gd \
    php-mbstring \
    php-xml \
    php-xmlrpc \
    php-soap \
    php-intl \
    php-zip \
    wget \
    curl \
    unzip \
    vim \
    net-tools

# Configuration du nom d'hôte
echo "Configuration du nom d'hôte..."
echo "10.2.33.17 wordpress" >> /etc/hosts

# Démarrage des services
echo "Démarrage des services..."
systemctl start apache2
systemctl enable apache2
systemctl start mysql
systemctl enable mysql

# Configuration de MySQL
echo "Configuration de MySQL..."
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'rootpassword';"
mysql -e "FLUSH PRIVILEGES;"

# Création de la base de données WordPress
echo "Création de la base de données..."
mysql -uroot -prootpassword <<EOF
CREATE DATABASE IF NOT EXISTS wordpress;
CREATE USER IF NOT EXISTS 'wpuser'@'localhost' IDENTIFIED BY 'wppassword';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wpuser'@'localhost';
FLUSH PRIVILEGES;
EOF

# Téléchargement de WordPress
echo "Téléchargement de WordPress..."
cd /tmp
wget -q https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz -C /var/www/html/
chown -R www-data:www-data /var/www/html/wordpress

# Configuration d'Apache
echo "Configuration d'Apache..."
cat > /etc/apache2/sites-available/wordpress.conf <<EOF
<VirtualHost *:80>
    ServerName wordpress
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/wordpress
    
    <Directory /var/www/html/wordpress>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
    
    ErrorLog \${APACHE_LOG_DIR}/wordpress_error.log
    CustomLog \${APACHE_LOG_DIR}/wordpress_access.log combined
</VirtualHost>
EOF

# Activation du site
a2ensite wordpress
a2dissite 000-default
a2enmod rewrite
systemctl restart apache2

# Configuration de WordPress
echo "Configuration de WordPress..."
cd /var/www/html/wordpress
cp wp-config-sample.php wp-config.php

# Mise à jour des informations de la base de données
sed -i "s/database_name_here/wordpress/" wp-config.php
sed -i "s/username_here/wpuser/" wp-config.php
sed -i "s/password_here/wppassword/" wp-config.php

# Génération des clés de sécurité
curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> wp-config.php

# Configuration des permissions
find /var/www/html/wordpress -type d -exec chmod 755 {} \;
find /var/www/html/wordpress -type f -exec chmod 644 {} \;
chown -R www-data:www-data /var/www/html/wordpress

# Création d'une page de test
cat > /var/www/html/wordpress/test.php <<EOF
<?php
phpinfo();
?>
EOF

echo "================================================"
echo "WordPress installation terminée!"
echo ""
echo "Accès:"
echo "  WordPress: http://10.2.33.17"
echo "  Test PHP:  http://10.2.33.17/test.php"
echo ""
echo "Informations de connexion MySQL:"
echo "  User: root"
echo "  Password: rootpassword"
echo ""
echo "Informations de connexion WordPress:"
echo "  Database: wordpress"
echo "  User: wpuser"
echo "  Password: wppassword"
echo "================================================"