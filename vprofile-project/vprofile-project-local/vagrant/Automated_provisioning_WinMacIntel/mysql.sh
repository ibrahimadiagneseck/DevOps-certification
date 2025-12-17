#!/bin/bash
DATABASE_PASS='admin123'
VPROJECT_PATH="/tmp/vprofile-project"

# SECTION 1 : INSTALLATION
# -------------------------------------------------------------------------------
sudo yum update -y
sudo yum install epel-release -y
sudo yum install git zip unzip -y
sudo yum install mariadb-server -y

# SECTION 2 : DÉMARRAGE ET CONFIGURATION MARIADB
# -------------------------------------------------------------------------------
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Copier le projet depuis le dossier partagé vers /tmp
# Assurez-vous que /vagrant/backups/vprofile-project existe (chemin partagé)
if [ -d "/vagrant/backups/vprofile-project" ]; then
    sudo cp -r /vagrant/backups/vprofile-project /tmp/
    echo "Projet copié depuis /vagrant/backups/vprofile-project vers /tmp/"
elif [ -d "/backups/vprofile-project" ]; then
    sudo cp -r /backups/vprofile-project /tmp/
    echo "Projet copié depuis /backups/vprofile-project vers /tmp/"
else
    # Fallback: Cloner si le dossier n'existe pas
    echo "Dossier vprofile-project non trouvé, clonage depuis GitHub..."
    cd /tmp/
    git clone -b main https://github.com/hkhcoder/vprofile-project.git
fi

# Configuration du mot de passe root
sudo mysqladmin -u root password "$DATABASE_PASS"

# Sécurisation
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1')"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.user WHERE User=''"
sudo mysql -u root -p"$DATABASE_PASS" -e "DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%'"
sudo mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

# Création de la base de données et des utilisateurs
sudo mysql -u root -p"$DATABASE_PASS" -e "CREATE DATABASE IF NOT EXISTS accounts"
sudo mysql -u root -p"$DATABASE_PASS" -e "CREATE USER IF NOT EXISTS 'admin'@'localhost' IDENTIFIED BY 'admin123'"
sudo mysql -u root -p"$DATABASE_PASS" -e "CREATE USER IF NOT EXISTS 'admin'@'%' IDENTIFIED BY 'admin123'"
sudo mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'localhost'"
sudo mysql -u root -p"$DATABASE_PASS" -e "GRANT ALL PRIVILEGES ON accounts.* TO 'admin'@'%'"

# Restauration de la base de données depuis le chemin local
if [ -f "$VPROJECT_PATH/src/main/resources/db_backup.sql" ]; then
    sudo mysql -u root -p"$DATABASE_PASS" accounts < "$VPROJECT_PATH/src/main/resources/db_backup.sql"
    echo "Base de données restaurée depuis: $VPROJECT_PATH/src/main/resources/db_backup.sql"
else
    echo "ERREUR: Fichier db_backup.sql non trouvé dans $VPROJECT_PATH/src/main/resources/"
    echo "Contenu du dossier:"
    find "$VPROJECT_PATH" -name "*.sql" -type f 2>/dev/null || ls -la "$VPROJECT_PATH" 2>/dev/null
    exit 1
fi

sudo mysql -u root -p"$DATABASE_PASS" -e "FLUSH PRIVILEGES"

# SECTION 3 : CONFIGURATION DU RÉSEAU ET PARC-FEU
# -------------------------------------------------------------------------------
# Configurer MariaDB pour écouter sur toutes les interfaces
sudo sed -i 's/^#bind-address=127.0.0.1/bind-address=0.0.0.0/' /etc/my.cnf.d/mariadb-server.cnf

# Configuration du pare-feu
sudo systemctl start firewalld
sudo systemctl enable firewalld
sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='192.168.56.0/24' port port='3306' protocol='tcp' accept"
sudo firewall-cmd --reload

# SECTION 4 : REDÉMARRAGE FINAL
# -------------------------------------------------------------------------------
sudo systemctl restart mariadb

echo "==========================================="
echo "MYSQL/MARIADB CONFIGURATION"
echo "==========================================="
echo "Root Password: $DATABASE_PASS"
echo "Admin User: admin / admin123"
echo "Database: accounts"
echo "Connection String: jdbc:mysql://192.168.56.15:3306/accounts"
echo "==========================================="