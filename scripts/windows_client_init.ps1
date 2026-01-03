<powershell>
# Variables
$ZabbixServer = "${zabbix_server_ip}"
$ZabbixAgentVersion = "6.4.10"
$ZabbixAgentUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.4/$ZabbixAgentVersion/zabbix_agent2-$ZabbixAgentVersion-windows-amd64-openssl.msi"

# Créer un répertoire temporaire
$TempDir = "C:\Temp"
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir
}

# Télécharger l'agent Zabbix
Write-Host "Téléchargement de l'agent Zabbix..."
$AgentInstaller = "$TempDir\zabbix_agent2.msi"
try {
    Invoke-WebRequest -Uri $ZabbixAgentUrl -OutFile $AgentInstaller -UseBasicParsing
} catch {
    Write-Host "Erreur lors du téléchargement: $_"
    # Essayer une version alternative si le téléchargement échoue
    $ZabbixAgentUrl = "https://cdn.zabbix.com/zabbix/binaries/stable/6.4/6.4.9/zabbix_agent2-6.4.9-windows-amd64-openssl.msi"
    Invoke-WebRequest -Uri $ZabbixAgentUrl -OutFile $AgentInstaller -UseBasicParsing
}

# Installer l'agent Zabbix
Write-Host "Installation de l'agent Zabbix..."
$Arguments = "/i `"$AgentInstaller`" /qn SERVER=$ZabbixServer SERVERACTIVE=$ZabbixServer HOSTNAME=$env:COMPUTERNAME"
Start-Process msiexec.exe -ArgumentList $Arguments -Wait -NoNewWindow

# Attendre que le service soit créé
Start-Sleep -Seconds 10

# Configurer le service Zabbix Agent
Write-Host "Configuration du service Zabbix Agent..."
Set-Service -Name "Zabbix Agent 2" -StartupType Automatic

# Ouvrir le port du firewall pour l'agent Zabbix
Write-Host "Configuration du firewall..."
New-NetFirewallRule -DisplayName "Zabbix Agent" -Direction Inbound -LocalPort 10050 -Protocol TCP -Action Allow

# Démarrer le service
Write-Host "Démarrage du service Zabbix Agent..."
Start-Service -Name "Zabbix Agent 2"

# Créer un fichier d'information sur le bureau de l'administrateur
$InfoContent = @"
=================================================
Configuration de l'Agent Zabbix Windows
=================================================
Serveur Zabbix: $ZabbixServer
Hostname: $env:COMPUTERNAME
Version Agent: $ZabbixAgentVersion

Statut du service:
$(Get-Service -Name 'Zabbix Agent 2' | Format-List | Out-String)

Commandes PowerShell utiles:
- Voir le statut: Get-Service -Name 'Zabbix Agent 2'
- Redémarrer: Restart-Service -Name 'Zabbix Agent 2'
- Voir les logs: Get-Content 'C:\Program Files\Zabbix Agent 2\zabbix_agent2.log' -Tail 50

Configuration: C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf
=================================================
"@

$DesktopPath = "C:\Users\Administrator\Desktop"
if (-not (Test-Path $DesktopPath)) {
    New-Item -ItemType Directory -Path $DesktopPath -Force
}

$InfoContent | Out-File -FilePath "$DesktopPath\AGENT_INFO.txt" -Encoding UTF8

Write-Host "Installation terminée!"
</powershell>
