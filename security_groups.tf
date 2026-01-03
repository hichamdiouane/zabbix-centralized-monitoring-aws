# Security Group pour le serveur Zabbix
resource "aws_security_group" "zabbix_server" {
  name        = "${var.project_name}-zabbix-server-sg"
  description = "Security group pour le serveur Zabbix"
  vpc_id      = aws_vpc.main.id

  # SSH depuis votre IP
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # HTTP pour l'interface web Zabbix
  ingress {
    description = "HTTP for Zabbix Web Interface"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # HTTPS pour l'interface web Zabbix
  ingress {
    description = "HTTPS for Zabbix Web Interface"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Port Zabbix Trapper (pour les agents actifs)
  ingress {
    description = "Zabbix Trapper"
    from_port   = 10051
    to_port     = 10051
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Tout le trafic sortant
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-zabbix-server-sg"
  }
}

# Security Group pour le client Linux
resource "aws_security_group" "linux_client" {
  name        = "${var.project_name}-linux-client-sg"
  description = "Security group pour le client Linux"
  vpc_id      = aws_vpc.main.id

  # SSH depuis votre IP
  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Port Zabbix Agent
  ingress {
    description     = "Zabbix Agent from Zabbix Server"
    from_port       = 10050
    to_port         = 10050
    protocol        = "tcp"
    security_groups = [aws_security_group.zabbix_server.id]
  }

  # Tout le trafic sortant
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-linux-client-sg"
  }
}

# Security Group pour le client Windows
resource "aws_security_group" "windows_client" {
  name        = "${var.project_name}-windows-client-sg"
  description = "Security group pour le client Windows"
  vpc_id      = aws_vpc.main.id

  # RDP depuis votre IP
  ingress {
    description = "RDP from my IP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  # Port Zabbix Agent
  ingress {
    description     = "Zabbix Agent from Zabbix Server"
    from_port       = 10050
    to_port         = 10050
    protocol        = "tcp"
    security_groups = [aws_security_group.zabbix_server.id]
  }

  # Tout le trafic sortant
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-windows-client-sg"
  }
}
