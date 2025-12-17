#!/bin/bash
DATABASE_PASS='admin123'

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

cd /tmp/
git clone -b main https://github.com/hkhcoder/vprofile-project.git

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

# Restauration de la base de données
sudo mysql -u root -p"$DATABASE_PASS" accounts < /tmp/vprofile-project/src/main/resources/db_backup.sql
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