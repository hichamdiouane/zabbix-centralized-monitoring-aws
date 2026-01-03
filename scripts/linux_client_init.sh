#!/bin/bash
set -e

# Variables
ZABBIX_SERVER="${zabbix_server_ip}"

# Mise à jour du système
apt-get update
apt-get upgrade -y

# Installation de l'agent Zabbix
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb
dpkg -i zabbix-release_6.4-1+ubuntu22.04_all.deb
apt-get update

# Installer l'agent Zabbix
apt-get install -y zabbix-agent2

# Configurer l'agent Zabbix
cat > /etc/zabbix/zabbix_agent2.conf <<EOF
PidFile=/var/run/zabbix/zabbix_agent2.pid
LogFile=/var/log/zabbix/zabbix_agent2.log
LogFileSize=0
Server=$ZABBIX_SERVER
ServerActive=$ZABBIX_SERVER
Hostname=$(hostname)
Include=/etc/zabbix/zabbix_agent2.d/*.conf
EOF

# Redémarrer et activer l'agent
systemctl restart zabbix-agent2
systemctl enable zabbix-agent2

# Installer quelques outils de monitoring supplémentaires
apt-get install -y htop iotop net-tools

# Créer un fichier d'information
cat > /home/ubuntu/AGENT_INFO.txt <<INFO
=================================================
Configuration de l'Agent Zabbix
=================================================
Serveur Zabbix: $ZABBIX_SERVER
Hostname: $(hostname)
Statut: systemctl status zabbix-agent2

Commandes utiles:
- Voir les logs: tail -f /var/log/zabbix/zabbix_agent2.log
- Redémarrer: sudo systemctl restart zabbix-agent2
- Vérifier le statut: sudo systemctl status zabbix-agent2

Configuration: /etc/zabbix/zabbix_agent2.conf
=================================================
INFO

chown ubuntu:ubuntu /home/ubuntu/AGENT_INFO.txt

echo "Agent Zabbix installé et configuré pour le serveur: $ZABBIX_SERVER"
