#!/bin/bash

# SECTION 1 : MISE À JOUR ET INSTALLATION
# -------------------------------------------------------------------------------
apt update
apt upgrade -y
apt install nginx -y

# SECTION 2 : CONFIGURATION DU SITE
# -------------------------------------------------------------------------------
cat <<EOT > /etc/nginx/sites-available/vproapp
upstream vproapp {
    server app01:8080;
    # Ajouter d'autres serveurs pour le load balancing si nécessaire
    # server app02:8080;
}

server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://vproapp;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Ajouter la gestion des erreurs
    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOT

# SECTION 3 : ACTIVATION DU SITE
# -------------------------------------------------------------------------------
rm -rf /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/vproapp /etc/nginx/sites-enabled/

# SECTION 4 : CONFIGURATION DU PARC-FEU
# -------------------------------------------------------------------------------
ufw allow 'Nginx Full'
ufw allow 22/tcp
ufw --force enable

# SECTION 5 : DÉMARRAGE DES SERVICES
# -------------------------------------------------------------------------------
systemctl start nginx
systemctl enable nginx
systemctl restart nginx

# SECTION 6 : VÉRIFICATION
# -------------------------------------------------------------------------------
echo "==========================================="
echo "NGINX CONFIGURATION"
echo "==========================================="
echo "Nginx Status: $(systemctl is-active nginx)"
echo "Nginx accessible sur: http://192.168.56.11"
echo "Forwarded port: http://localhost:8080"
echo "==========================================="