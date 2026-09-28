# -------------------
# Security Group
# -------------------
resource "aws_security_group" "app_sg" {
  name        = "facebook-app-server-sg"
  description = "Dedicated SG for App Server"
  vpc_id      = data.aws_vpc.main.id

  # Example: allow SSH from anywhere
  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Example: allow HTTP
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound: allow all
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.comman_tags, {
    Name = "facebook-app-server-sg"
  })
}

# -------------------
# EC2 Instance
# -------------------
resource "aws_instance" "app_server" {
  ami           = data.aws_ami.amazon-windows.id
  instance_type = var.instance_type
  subnet_id     = data.aws_subnet.app_a.id
  disable_api_termination = false
  associate_public_ip_address = false
  key_name   = "lab-5-keypair"  # Attach SG
  vpc_security_group_ids = [aws_security_group.app_sg.id]  

  # Root volume (20 GB gp2)
  root_block_device {
    volume_size = 35
    volume_type = "gp2"
  }

 user_data = file("./userdata.sh")

  tags = merge(local.comman_tags, {
    Name = "facebook-app-server"
  })
}

/*
# -------------------
# Elastic IP
# -------------------
resource "aws_eip" "app_eip" {
  tags = merge(local.comman_tags, {
    Name = "${local.prefix}-app-eip"
  })
}

# -------------------
# Associate EIP with EC2
# -------------------
resource "aws_eip_association" "app_eip_assoc" {
  instance_id   = aws_instance.app_server.id
  allocation_id = aws_eip.app_eip.id
}
*/

resource "aws_ebs_volume" "app_data_volume" {
  availability_zone = data.aws_subnet.app_a.availability_zone
  size              = 30
  type              = "gp2"
  tags = merge(local.comman_tags, {
    Name = "${local.prefix}-app-data-volume"
  })
}

resource "aws_volume_attachment" "app_data_volume_attachment" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.app_data_volume.id
  instance_id = aws_instance.app_server.id
}

resource "aws_ebs_volume" "app_ec2_volume" {
  availability_zone = data.aws_subnet.app_a.availability_zone
  size              = 30
  type              = "gp2"
  tags = merge(local.comman_tags, {
    Name = "${local.prefix}-app-data-volume"
  })
}

resource "aws_volume_attachment" "app_ec2_volume_attachment" {
  device_name = "/dev/sdg"
  volume_id   = aws_ebs_volume.app_ec2_volume.id
  instance_id = aws_instance.app_server.id
}