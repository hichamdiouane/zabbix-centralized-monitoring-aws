# Guide de Déploiement avec WSL (Windows Subsystem for Linux)

## 🐧 Prérequis WSL

### Vérifier WSL
```bash
wsl --version
# Si WSL n'est pas installé, suivez: https://docs.microsoft.com/windows/wsl/install
```

### Installation des outils nécessaires

#### 1. Terraform
```bash
# Télécharger Terraform
cd /tmp
wget https://releases.hashicorp.com/terraform/1.7.0/terraform_1.7.0_linux_amd64.zip

# Installer
sudo apt update
sudo apt install -y unzip
unzip terraform_1.7.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
terraform --version
```

#### 2. AWS CLI
```bash
# Installer AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Vérifier l'installation
aws --version
```

#### 3. Outils utiles
```bash
sudo apt install -y curl wget jq git
```

## 🚀 Déploiement Étape par Étape

### 1️⃣ Navigation vers le projet

```bash
# Accéder au disque Windows depuis WSL
cd /mnt/d/ENSET/S5/Sec/Projet

# Vérifier les fichiers
ls -la
```

### 2️⃣ Configuration AWS

#### Récupérer les credentials AWS Academy

1. Dans AWS Academy Lab, cliquez sur **AWS Details**
2. Cliquez sur **Show** à côté de "AWS CLI"
3. Copiez les credentials

#### Configurer AWS CLI
```bash
# Créer le répertoire de configuration
mkdir -p ~/.aws

# Éditer le fichier credentials
nano ~/.aws/credentials
```

Collez vos credentials (format):
```ini
[default]
aws_access_key_id = ASIAXXXXXXXXXXX
aws_secret_access_key = XXXXXXXXXXXXXXXXXXXXXXX
aws_session_token = VERY_LONG_TOKEN_HERE
```

Sauvegarder: `Ctrl + O`, `Enter`, puis quitter: `Ctrl + X`

#### Configurer la région
```bash
nano ~/.aws/config
```

Ajoutez:
```ini
[default]
region = us-east-1
output = json
```

#### Vérifier la configuration
```bash
aws sts get-caller-identity
```

### 3️⃣ Récupérer votre IP publique

```bash
# Méthode 1
curl https://api.ipify.org
echo ""

# Méthode 2
curl ifconfig.me
echo ""

# Méthode 3
wget -qO- https://ipecho.net/plain
echo ""
```

### 4️⃣ Créer la Key Pair AWS

#### Via AWS CLI (recommandé)
```bash
# Créer la key pair
aws ec2 create-key-pair \
    --key-name zabbix-key \
    --query 'KeyMaterial' \
    --output text > zabbix-key.pem

# Sécuriser la clé
chmod 400 zabbix-key.pem

# Vérifier
ls -l zabbix-key.pem
```

#### Via AWS Console (alternative)
1. Ouvrir AWS Console: EC2 > Key Pairs > Create key pair
2. Name: `zabbix-key`
3. Type: RSA, Format: .pem
4. Télécharger et copier vers WSL:
```bash
# Depuis Windows, copiez le fichier vers WSL
cp /mnt/c/Users/VOTRE_USER/Downloads/zabbix-key.pem .
chmod 400 zabbix-key.pem
```

### 5️⃣ Configuration Terraform

```bash
# Copier le fichier d'exemple
cp terraform.tfvars.example terraform.tfvars

# Éditer avec nano
nano terraform.tfvars
```

Modifiez les valeurs:
```hcl
aws_region = "us-east-1"
project_name = "zabbix-monitoring"

# IMPORTANT: Remplacez par votre IP (résultat de curl ifconfig.me)
my_ip = "203.0.113.45/32"  # VOTRE IP ICI

# Nom de votre key pair
key_name = "zabbix-key"

# Types d'instances
zabbix_instance_type = "t3.large"
linux_client_instance_type = "t3.medium"
windows_client_instance_type = "t3.large"
```

Sauvegarder: `Ctrl + O`, `Enter`, `Ctrl + X`

### 6️⃣ Déploiement Terraform

```bash
# Initialiser Terraform
terraform init

# Vérifier la syntaxe
terraform validate

# Voir ce qui sera créé
terraform plan

# Déployer (durée: ~10-15 minutes)
terraform apply

# Ou déployer sans confirmation
terraform apply -auto-approve
```

### 7️⃣ Récupérer les informations

```bash
# Afficher toutes les sorties
terraform output

# IP du serveur Zabbix
terraform output zabbix_server_public_ip

# URL de l'interface web
terraform output zabbix_web_url

# IP du client Linux
terraform output linux_client_public_ip

# IP du client Windows
terraform output windows_client_public_ip

# Sauvegarder les outputs dans un fichier
terraform output > deployment_info.txt
cat deployment_info.txt
```

## 🔐 Connexion aux Serveurs

### Serveur Zabbix (SSH)

```bash
# Se connecter
ssh -i zabbix-key.pem ubuntu@$(terraform output -raw zabbix_server_public_ip)

# Une fois connecté, vérifier Zabbix
docker ps
docker compose -f /opt/zabbix/docker-compose.yml ps

# Voir les logs
cd /opt/zabbix
docker compose logs -f

# Quitter: Ctrl + C puis exit
```

### Client Linux (SSH)

```bash
# Se connecter
ssh -i zabbix-key.pem ubuntu@$(terraform output -raw linux_client_public_ip)

# Vérifier l'agent Zabbix
sudo systemctl status zabbix-agent2
sudo tail -f /var/log/zabbix/zabbix_agent2.log

# Tester la connexion avec le serveur
sudo zabbix_agent2 -t agent.ping
```

### Client Windows (RDP)

```bash
# Récupérer l'ID de l'instance Windows
WINDOWS_INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=zabbix-monitoring-windows-client" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)

echo "Instance ID: $WINDOWS_INSTANCE_ID"

# Récupérer le mot de passe (attendez 5-10 min après le déploiement)
aws ec2 get-password-data \
    --instance-id $WINDOWS_INSTANCE_ID \
    --priv-launch-key zabbix-key.pem \
    --query PasswordData \
    --output text | base64 --decode

# Connexion RDP depuis Windows
# Utilisez l'IP: terraform output windows_client_public_ip
# Username: Administrator
# Password: (mot de passe récupéré ci-dessus)
```

## 🛠️ Commandes de Maintenance

### Vérifier l'état des instances

```bash
# Lister toutes les instances du projet
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=zabbix-monitoring-*" \
    --query 'Reservations[].Instances[].[InstanceId,State.Name,PublicIpAddress,Tags[?Key==`Name`].Value|[0]]' \
    --output table
```

### Arrêter les instances (économiser le budget)

```bash
# Obtenir les IDs des instances
ZABBIX_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=zabbix-monitoring-zabbix-server" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)

LINUX_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=zabbix-monitoring-linux-client" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)

WINDOWS_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=zabbix-monitoring-windows-client" \
    --query 'Reservations[0].Instances[0].InstanceId' \
    --output text)

# Arrêter toutes les instances
aws ec2 stop-instances --instance-ids $ZABBIX_ID $LINUX_ID $WINDOWS_ID

# Vérifier l'état
aws ec2 describe-instances \
    --instance-ids $ZABBIX_ID $LINUX_ID $WINDOWS_ID \
    --query 'Reservations[].Instances[].[InstanceId,State.Name]' \
    --output table
```

### Redémarrer les instances

```bash
# Redémarrer
aws ec2 start-instances --instance-ids $ZABBIX_ID $LINUX_ID $WINDOWS_ID

# Attendre qu'elles démarrent
aws ec2 wait instance-running --instance-ids $ZABBIX_ID $LINUX_ID $WINDOWS_ID

# Obtenir les nouvelles IPs (elles changent après un stop/start!)
terraform refresh
terraform output
```

### Redémarrer Zabbix après un arrêt

```bash
# Se connecter au serveur
ssh -i zabbix-key.pem ubuntu@$(terraform output -raw zabbix_server_public_ip)

# Redémarrer les conteneurs
cd /opt/zabbix
sudo docker compose up -d

# Vérifier
sudo docker ps
```

## 🧹 Nettoyage

### Détruire l'infrastructure

```bash
# Détruire tout
terraform destroy

# Ou sans confirmation
terraform destroy -auto-approve

# Vérifier que tout est supprimé
aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=zabbix-monitoring-*" \
    --query 'Reservations[].Instances[].[InstanceId,State.Name]' \
    --output table
```

### Nettoyer les fichiers locaux

```bash
# Supprimer les fichiers Terraform temporaires
rm -rf .terraform/
rm -f .terraform.lock.hcl
rm -f terraform.tfstate*

# Garder la configuration
# Ne PAS supprimer: terraform.tfvars, zabbix-key.pem
```

## 📊 Monitoring du Budget

```bash
# Voir les coûts estimés (nécessite AWS Cost Explorer activé)
aws ce get-cost-and-usage \
    --time-period Start=2026-01-01,End=2026-01-31 \
    --granularity DAILY \
    --metrics UnblendedCost \
    --group-by Type=SERVICE

# Voir les instances en cours d'exécution
aws ec2 describe-instances \
    --filters "Name=instance-state-name,Values=running" \
    --query 'Reservations[].Instances[].[InstanceType,State.Name]' \
    --output table
```

## 🔧 Dépannage WSL

### Problème d'accès aux fichiers Windows

```bash
# Si le dossier n'est pas accessible
cd /mnt/d/ENSET/S5/Sec/Projet

# Vérifier les permissions
ls -la
```

### Problème de credentials AWS

```bash
# Vérifier les credentials
cat ~/.aws/credentials

# Tester la connexion
aws sts get-caller-identity

# Si expired, mettez à jour depuis AWS Academy Lab
nano ~/.aws/credentials
```

### Terraform ne trouve pas les fichiers

```bash
# Vérifier le répertoire courant
pwd

# Lister les fichiers
ls -la *.tf

# Si vous n'êtes pas dans le bon dossier
cd /mnt/d/ENSET/S5/Sec/Projet
```

### Erreur de permissions sur la clé SSH

```bash
# Corriger les permissions
chmod 400 zabbix-key.pem
ls -l zabbix-key.pem

# Devrait afficher: -r-------- 1 user user
```

## 📝 Script Utile : Déploiement Complet

Créez un script pour automatiser:

```bash
# Créer le script
nano deploy.sh
```

Contenu du script:
```bash
#!/bin/bash
set -e

echo "🚀 Déploiement de l'infrastructure Zabbix"

# Vérifier que nous sommes dans le bon dossier
if [ ! -f "provider.tf" ]; then
    echo "❌ Erreur: Pas dans le bon dossier!"
    exit 1
fi

# Vérifier terraform.tfvars
if [ ! -f "terraform.tfvars" ]; then
    echo "❌ Erreur: terraform.tfvars n'existe pas!"
    echo "Créez-le avec: cp terraform.tfvars.example terraform.tfvars"
    exit 1
fi

# Vérifier AWS credentials
echo "🔐 Vérification des credentials AWS..."
if ! aws sts get-caller-identity > /dev/null 2>&1; then
    echo "❌ Erreur: Credentials AWS invalides!"
    exit 1
fi

echo "✅ Credentials OK"

# Terraform init
echo "📦 Initialisation de Terraform..."
terraform init

# Terraform validate
echo "✅ Validation de la configuration..."
terraform validate

# Terraform plan
echo "📋 Planification..."
terraform plan

# Demander confirmation
read -p "🤔 Voulez-vous déployer? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo "❌ Déploiement annulé"
    exit 0
fi

# Terraform apply
echo "🚀 Déploiement en cours..."
terraform apply -auto-approve

# Afficher les résultats
echo ""
echo "✅ Déploiement terminé!"
echo ""
echo "📊 Informations importantes:"
terraform output

echo ""
echo "🌐 Interface Zabbix:"
echo "URL: $(terraform output -raw zabbix_web_url)"
echo "Username: Admin"
echo "Password: zabbix"
echo ""
echo "💾 Sauvegardez ces informations!"
```

Rendre le script exécutable:
```bash
chmod +x deploy.sh
```

Utiliser le script:
```bash
./deploy.sh
```

## 🎯 Checklist Complète

- [ ] WSL installé et fonctionnel
- [ ] Terraform installé (`terraform --version`)
- [ ] AWS CLI installé (`aws --version`)
- [ ] Credentials AWS configurés dans `~/.aws/credentials`
- [ ] Key Pair créée (`zabbix-key.pem` avec chmod 400)
- [ ] IP publique récupérée
- [ ] Fichier `terraform.tfvars` configuré
- [ ] `terraform init` exécuté sans erreur
- [ ] `terraform apply` réussi
- [ ] Interface Zabbix accessible
- [ ] Connexion SSH au serveur Zabbix fonctionne

## 📚 Commandes de Référence Rapide

```bash
# Déployer
terraform init && terraform apply -auto-approve

# Voir les infos
terraform output

# SSH Zabbix
ssh -i zabbix-key.pem ubuntu@$(terraform output -raw zabbix_server_public_ip)

# Arrêter les instances
aws ec2 stop-instances --instance-ids $(aws ec2 describe-instances --filters "Name=tag:Name,Values=zabbix-monitoring-*" --query 'Reservations[].Instances[].InstanceId' --output text)

# Détruire tout
terraform destroy -auto-approve
```

---

**Besoin d'aide?** Consultez [README.md](README.md) pour plus de détails! 🐧
