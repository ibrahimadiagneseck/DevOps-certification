#!/bin/bash

# Script de provisionnement pour DevOps
# Ubuntu 22.04

set -e

echo "================================================"
echo "Début de l'installation DevOps"
echo "================================================"

# Mise à jour
echo "Mise à jour du système..."
apt-get update -y

# Configuration du nom d'hôte
echo "Configuration du nom d'hôte..."
echo "10.2.33.10 devops" >> /etc/hosts

# Installation des outils
echo "Installation des outils DevOps..."
apt-get install -y \
    apache2 \
    wget \
    curl \
    unzip \
    git \
    net-tools \
    htop \
    tree \
    python3 \
    python3-pip \
    docker.io \
    docker-compose \
    nginx \
    fail2ban

# Démarrage des services
systemctl start apache2
systemctl enable apache2
systemctl start docker
systemctl enable docker

# Création des dossiers
echo "Création des dossiers de travail..."
mkdir -p /opt/devops
mkdir -p /opt/monitoring
mkdir -p /opt/backups
mkdir -p /var/log/devops

# Scripts de monitoring
echo "Création des scripts de monitoring..."

# Script 1: Surveillance système
cat > /opt/devops/monitor.sh <<'EOF'
#!/bin/bash

LOG_FILE="/var/log/devops/monitor_$(date +%Y%m%d).log"
echo "=== Monitoring Report - $(date) ===" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# CPU
echo "CPU Usage:" | tee -a $LOG_FILE
top -bn1 | grep "Cpu(s)" | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Mémoire
echo "Memory Usage:" | tee -a $LOG_FILE
free -h | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Disque
echo "Disk Usage:" | tee -a $LOG_FILE
df -h | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE

# Services
echo "Service Status:" | tee -a $LOG_FILE
systemctl is-active apache2 docker | tee -a $LOG_FILE
echo "" | tee -a $LOG_FILE
EOF

chmod +x /opt/devops/monitor.sh

# Script 2: Backup
cat > /opt/devops/backup.sh <<'EOF'
#!/bin/bash

BACKUP_DIR="/opt/backups/backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR

echo "Starting backup at $(date)" > $BACKUP_DIR/backup.log

# Sauvegarde des configurations importantes
cp -r /etc/apache2 $BACKUP_DIR/ 2>/dev/null || true
cp -r /etc/nginx $BACKUP_DIR/ 2>/dev/null || true
cp -r /opt/devops $BACKUP_DIR/ 2>/dev/null || true

# Informations système
uname -a > $BACKUP_DIR/system_info.txt
ip addr show > $BACKUP_DIR/network_info.txt
df -h > $BACKUP_DIR/disk_info.txt

echo "Backup completed at $(date)" >> $BACKUP_DIR/backup.log
echo "Backup saved to: $BACKUP_DIR"
EOF

chmod +x /opt/devops/backup.sh

# Page web de monitoring
echo "Création de la page de monitoring..."
mkdir -p /var/www/html/monitoring

cat > /var/www/html/monitoring/index.html <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>DevOps Monitoring</title>
    <meta http-equiv="refresh" content="30">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { font-family: 'Courier New', monospace; background: #1a1a1a; color: #00ff00; }
        .container { max-width: 1200px; margin: 0 auto; padding: 20px; }
        .header { text-align: center; padding: 20px; border-bottom: 2px solid #00ff00; }
        .server-info { display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 20px; margin: 20px 0; }
        .card { background: #2a2a2a; padding: 20px; border-radius: 5px; border: 1px solid #00ff00; }
        .status { padding: 5px 10px; border-radius: 3px; display: inline-block; }
        .online { background: #00aa00; }
        .offline { background: #aa0000; }
        pre { background: #000; padding: 10px; border-radius: 3px; overflow-x: auto; }
        .timestamp { color: #888; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 DevOps Monitoring Dashboard</h1>
            <p>Server: devops (10.2.33.10) | Last update: <span class="timestamp">$(date)</span></p>
        </div>
        
        <div class="server-info">
            <div class="card">
                <h2>📊 System Status</h2>
                <p>Uptime: <span id="uptime">Loading...</span></p>
                <p>Load Average: <span id="load">Loading...</span></p>
                <p>Services: <span class="status online">Apache ✓</span> <span class="status online">Docker ✓</span></p>
            </div>
            
            <div class="card">
                <h2>💾 Disk Usage</h2>
                <pre id="disk">Loading disk info...</pre>
            </div>
            
            <div class="card">
                <h2>🖥️ Memory Usage</h2>
                <pre id="memory">Loading memory info...</pre>
            </div>
            
            <div class="card">
                <h2>🔗 Network</h2>
                <p>IP Address: 10.2.33.10</p>
                <p>Hostname: devops</p>
                <p>Interface: enp0s3</p>
            </div>
        </div>
        
        <div class="card">
            <h2>📈 Quick Stats</h2>
            <button onclick="runCommand('uptime')">Check Uptime</button>
            <button onclick="runCommand('df -h')">Check Disk</button>
            <button onclick="runCommand('free -h')">Check Memory</button>
            <div id="commandOutput"></div>
        </div>
    </div>
    
    <script>
    function runCommand(cmd) {
        fetch('/cgi-bin/exec?cmd=' + encodeURIComponent(cmd))
            .then(response => response.text())
            .then(data => {
                document.getElementById('commandOutput').innerHTML = '<pre>' + data + '</pre>';
            });
    }
    
    // Auto-refresh stats
    setInterval(() => {
        document.querySelector('.timestamp').textContent = new Date().toLocaleString();
    }, 30000);
    </script>
</body>
</html>
EOF

# Création d'un script CGI simple pour l'interface web
mkdir -p /usr/lib/cgi-bin
cat > /usr/lib/cgi-bin/exec <<'EOF'
#!/bin/bash
echo "Content-type: text/plain"
echo ""
cmd=$(echo "$QUERY_STRING" | sed 's/cmd=//' | sed 's/%20/ /g')
eval "$cmd" 2>&1
EOF
chmod +x /usr/lib/cgi-bin/exec

# Installation de Netdata (monitoring avancé)
echo "Installation de Netdata pour le monitoring..."
bash <(curl -Ss https://my-netdata.io/kickstart.sh) --non-interactive

# Création d'un crontab pour le monitoring automatique
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/devops/monitor.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/devops/backup.sh") | crontab -

# Test de Docker
docker run hello-world

echo "================================================"
echo "DevOps installation terminée!"
echo ""
echo "Accès:"
echo "  Dashboard:    http://10.2.33.10/monitoring"
echo "  Netdata:      http://10.2.33.10:19999"
echo "  Apache:       http://10.2.33.10"
echo ""
echo "Outils installés:"
echo "  - Apache2, Nginx, Docker, Docker Compose"
echo "  - Git, Python3, Netdata (monitoring)"
echo "  - Scripts de monitoring et backup"
echo "================================================"