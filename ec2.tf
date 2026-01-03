# Instance EC2 pour le serveur Zabbix
resource "aws_instance" "zabbix_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.zabbix_instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.zabbix_server.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = file("${path.module}/scripts/zabbix_server_init.sh")

  tags = {
    Name = "${var.project_name}-zabbix-server"
    Role = "Zabbix Server"
  }

  # Attendre que le user_data soit exécuté
  depends_on = [
    aws_internet_gateway.main
  ]
}

# Instance EC2 pour le client Linux
resource "aws_instance" "linux_client" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.linux_client_instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.linux_client.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/scripts/linux_client_init.sh", {
    zabbix_server_ip = aws_instance.zabbix_server.private_ip
  })

  tags = {
    Name = "${var.project_name}-linux-client"
    Role = "Monitored Linux Client"
  }

  depends_on = [
    aws_instance.zabbix_server
  ]
}

# Instance EC2 pour le client Windows
resource "aws_instance" "windows_client" {
  ami                    = data.aws_ami.windows.id
  instance_type          = var.windows_client_instance_type
  key_name               = var.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.windows_client.id]

  root_block_device {
    volume_size = 50
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/scripts/windows_client_init.ps1", {
    zabbix_server_ip = aws_instance.zabbix_server.private_ip
  })

  tags = {
    Name = "${var.project_name}-windows-client"
    Role = "Monitored Windows Client"
  }

  depends_on = [
    aws_instance.zabbix_server
  ]
}
