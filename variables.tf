variable "aws_region" {
  description = "AWS region pour le déploiement"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "zabbix-monitoring"
}

variable "vpc_cidr" {
  description = "CIDR block pour le VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block pour le sous-réseau public"
  type        = string
  default     = "10.0.1.0/24"
}

variable "zabbix_instance_type" {
  description = "Type d'instance pour le serveur Zabbix"
  type        = string
  default     = "t3.large"
}

variable "linux_client_instance_type" {
  description = "Type d'instance pour le client Linux"
  type        = string
  default     = "t3.medium"
}

variable "windows_client_instance_type" {
  description = "Type d'instance pour le client Windows"
  type        = string
  default     = "t3.large"
}

variable "my_ip" {
  description = "Votre IP publique pour l'accès SSH/RDP (format: x.x.x.x/32)"
  type        = string
  # Vous devez définir cette variable lors du déploiement
}

variable "key_name" {
  description = "Nom de la paire de clés AWS pour l'accès SSH"
  type        = string
  # Vous devez créer une key pair dans AWS avant le déploiement
}
