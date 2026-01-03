#!/bin/bash
set -e

# Mise à jour du système
apt-get update
apt-get upgrade -y

# Installation de Docker
apt-get install -y ca-certificates curl gnupg lsb-release
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Démarrer et activer Docker
systemctl start docker
systemctl enable docker

# Créer le répertoire pour Zabbix
mkdir -p /opt/zabbix
cd /opt/zabbix

# Créer le fichier docker-compose.yml pour Zabbix
cat > docker-compose.yml <<'EOF'
version: '3.8'

services:
  mysql-server:
    image: mysql:8.0
    container_name: zabbix-mysql
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: zabbix
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: zabbix_password
      MYSQL_ROOT_PASSWORD: root_password
    command:
      - mysqld
      - --character-set-server=utf8mb4
      - --collation-server=utf8mb4_bin
      - --default-authentication-plugin=mysql_native_password
    volumes:
      - mysql-data:/var/lib/mysql
    networks:
      - zabbix-net

  zabbix-server:
    image: zabbix/zabbix-server-mysql:ubuntu-6.4-latest
    container_name: zabbix-server
    restart: unless-stopped
    environment:
      DB_SERVER_HOST: mysql-server
      MYSQL_DATABASE: zabbix
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: zabbix_password
      MYSQL_ROOT_PASSWORD: root_password
      ZBX_ENABLE_SNMP_TRAPS: "true"
    ports:
      - "10051:10051"
    volumes:
      - zabbix-server-data:/var/lib/zabbix
    depends_on:
      - mysql-server
    networks:
      - zabbix-net

  zabbix-web:
    image: zabbix/zabbix-web-nginx-mysql:ubuntu-6.4-latest
    container_name: zabbix-web
    restart: unless-stopped
    environment:
      DB_SERVER_HOST: mysql-server
      MYSQL_DATABASE: zabbix
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: zabbix_password
      MYSQL_ROOT_PASSWORD: root_password
      ZBX_SERVER_HOST: zabbix-server
      PHP_TZ: Europe/Paris
    ports:
      - "80:8080"
    depends_on:
      - mysql-server
      - zabbix-server
    networks:
      - zabbix-net

volumes:
  mysql-data:
  zabbix-server-data:

networks:
  zabbix-net:
    driver: bridge
EOF

# Démarrer les conteneurs Zabbix
docker compose up -d

# Créer un script de redémarrage automatique
cat > /usr/local/bin/restart-zabbix.sh <<'SCRIPT'
#!/bin/bash
cd /opt/zabbix
docker compose up -d
SCRIPT

chmod +x /usr/local/bin/restart-zabbix.sh

# Créer un service systemd pour démarrer Zabbix au boot
cat > /etc/systemd/system/zabbix-docker.service <<'SERVICE'
[Unit]
Description=Zabbix Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/zabbix
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable zabbix-docker.service

# Afficher les informations de connexion
echo "==================================================" > /home/ubuntu/ZABBIX_INFO.txt
echo "Installation de Zabbix terminée!" >> /home/ubuntu/ZABBIX_INFO.txt
echo "==================================================" >> /home/ubuntu/ZABBIX_INFO.txt
echo "" >> /home/ubuntu/ZABBIX_INFO.txt
echo "Interface Web Zabbix accessible sur:" >> /home/ubuntu/ZABBIX_INFO.txt
echo "http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)" >> /home/ubuntu/ZABBIX_INFO.txt
echo "" >> /home/ubuntu/ZABBIX_INFO.txt
echo "Identifiants par défaut:" >> /home/ubuntu/ZABBIX_INFO.txt
echo "Username: Admin" >> /home/ubuntu/ZABBIX_INFO.txt
echo "Password: zabbix" >> /home/ubuntu/ZABBIX_INFO.txt
echo "" >> /home/ubuntu/ZABBIX_INFO.txt
echo "Pour redémarrer Zabbix: /usr/local/bin/restart-zabbix.sh" >> /home/ubuntu/ZABBIX_INFO.txt
echo "==================================================" >> /home/ubuntu/ZABBIX_INFO.txt

chown ubuntu:ubuntu /home/ubuntu/ZABBIX_INFO.txt

# Attendre que les conteneurs soient prêts
sleep 60
