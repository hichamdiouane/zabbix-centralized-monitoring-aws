output "zabbix_server_public_ip" {
  description = "Adresse IP publique du serveur Zabbix"
  value       = aws_instance.zabbix_server.public_ip
}

output "zabbix_web_url" {
  description = "URL d'accès à l'interface web Zabbix"
  value       = "http://${aws_instance.zabbix_server.public_ip}"
}

output "linux_client_public_ip" {
  description = "Adresse IP publique du client Linux"
  value       = aws_instance.linux_client.public_ip
}

output "linux_client_private_ip" {
  description = "Adresse IP privée du client Linux"
  value       = aws_instance.linux_client.private_ip
}

output "windows_client_public_ip" {
  description = "Adresse IP publique du client Windows"
  value       = aws_instance.windows_client.public_ip
}

output "windows_client_private_ip" {
  description = "Adresse IP privée du client Windows"
  value       = aws_instance.windows_client.private_ip
}

output "windows_admin_password_command" {
  description = "Commande pour récupérer le mot de passe administrateur Windows"
  value       = "aws ec2 get-password-data --instance-id ${aws_instance.windows_client.id} --priv-launch-key <path-to-your-private-key.pem>"
}

output "default_zabbix_credentials" {
  description = "Identifiants par défaut de Zabbix"
  value = {
    username = "Admin"
    password = "zabbix"
  }
  sensitive = false
}
