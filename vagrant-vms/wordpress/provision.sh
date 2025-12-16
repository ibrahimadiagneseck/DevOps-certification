#!/bin/bash

# ------------------------------
# Définir le nom d’hôte
# ------------------------------
hostnamectl set-hostname wordpress

# ------------------------------
# Mise à jour des paquets
# ------------------------------
apt update -y
apt upgrade -y

# ------------------------------
# Installer Apache2, PHP, MySQL et extensions
# ------------------------------
apt install -y apache2 \
               ghostscript \
               libapache2-mod-php \
               mysql-server \
               php \
               php-bcmath \
               php-curl \
               php-imagick \
               php-intl \
               php-json \
               php-mbstring \
               php-mysql \
               php-xml \
               php-zip \
               wget vim unzip zip net-tools curl

# ------------------------------
# Démarrage et activation Apache et MySQL
# ------------------------------
systemctl enable apache2
systemctl start apache2
systemctl enable mysql
systemctl start mysql

# ------------------------------
# Créer le dossier WordPress et définir les permissions
# ------------------------------
mkdir -p /srv/www
chown www-data:www-data /srv/www

# Télécharger et extraire WordPress
curl -s https://wordpress.org/latest.tar.gz | sudo -u www-data tar zx -C /srv/www

# ------------------------------
# Configuration Apache pour WordPress
# ------------------------------
cat << EOF > /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    DocumentRoot /srv/www/wordpress
    <Directory /srv/www/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory /srv/www/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
EOF

# Activer le site WordPress et URL rewriting
a2ensite wordpress
a2enmod rewrite

# Désactiver le site par défaut
a2dissite 000-default

# Recharger Apache pour appliquer la configuration
systemctl reload apache2

# ------------------------------
# Configurer la base de données MySQL pour WordPress
# ------------------------------
MYSQL_ROOT_PASSWORD='root'        # Mot de passe root MySQL
WP_DB_PASSWORD='root'             # Mot de passe pour l'utilisateur WordPress

mysql -u root <<MYSQL_SCRIPT
CREATE DATABASE wordpress;
CREATE USER 'wordpress'@'localhost' IDENTIFIED BY '${WP_DB_PASSWORD}';
GRANT ALL PRIVILEGES ON wordpress.* TO 'wordpress'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# ------------------------------
# Configurer WordPress pour se connecter à la base
# ------------------------------
sudo -u www-data cp /srv/www/wordpress/wp-config-sample.php /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i "s/database_name_here/wordpress/" /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i "s/username_here/wordpress/" /srv/www/wordpress/wp-config.php
sudo -u www-data sed -i "s/password_here/${WP_DB_PASSWORD}/" /srv/www/wordpress/wp-config.php

# ------------------------------
# Générer les clés secrètes uniques pour WordPress
# ------------------------------
# define('AUTH_KEY',         'D?]g6ED8YyX!~2_DJd`25Mo(|.T.z:?Z*l&]A#<+tbv<4h;4}W,Kynw{]N@goIL-');
# define('SECURE_AUTH_KEY',  '>329^nL|4YhD?qF!|rx#(]H+-{+i>^T1VI<X[xeZNU]w_kF-gMz72U$5S}b9VRBQ');
# define('LOGGED_IN_KEY',    '-ws]8,(UDi:|elP/C|/5.<`j1VZHMXmFNFPYL#TX}l#~y`NwpN;p)SDnpCMm,xA9');
# define('NONCE_KEY',        'd|n.&Z?S-xGF67hIdO`.PY4iewR@ydH%h1zv4|rSgu5(NeD`xW6%Zs|VVHLF!q|7');
# define('AUTH_SALT',        'Y *u)M|{mQS-(/V:QEm`^/^Rn|:b17L[P:<:P_m/v/$QL$KCyw<j9XZEQ3k{ !Hd');
# define('SECURE_AUTH_SALT', ' {4V4taA=K,z,W4iH7eS|#Va3[w1+(1|@vtUV?=X^$GP-w{@cVuNePt0;qsrS(K#');
# define('LOGGED_IN_SALT',   '2bHG+S<F-/5kuZG^~eS-u,eS)&|A4vLvK)$0^%d-p~a|M+|VB*T~QFjdtX6}+*Nh');
# define('NONCE_SALT',       'z&a3k@!*u!O/D_Hp+89Lfk.M5Q>ay{cWqE>EIr4Px>Jf|0xH0|KB|()x|:<wZ]4$');
curl -s https://api.wordpress.org/secret-key/1.1/salt/ | sudo -u www-data tee -a /srv/www/wordpress/wp-config-sample.php > /dev/null

# Open http://localhost/ to finish the WordPress installation.
