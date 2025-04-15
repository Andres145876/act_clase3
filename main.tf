# --- Proveedor AWS ---
provider "aws" {
  region = "us-east-1"
}

# --- VPC ---
resource "aws_vpc" "vpc" {
  cidr_block = "10.10.0.0/20"

  tags = {
    Name = "act_clase3"
  }
}

# --- Subred pública ---
resource "aws_subnet" "subnet_public" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.10.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "act_clase3_subnet_public"
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "IGW"
  }
}

# --- Tabla de ruteo ---
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

# --- Asociación tabla de ruteo a subred ---
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.public.id
}

# --- Grupo de Seguridad: Jump Server ---
resource "aws_security_group" "jump_sg" {
  name        = "JumpServerSG_clase3"
  description = "Permite SSH desde Internet"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "JumpServerSG_clase3"
  }
}

# --- Grupo de Seguridad: Web Servers ---
resource "aws_security_group" "web_sg" {
  name        = "WebServerSG_clase3"
  description = "HTTP desde Internet, SSH solo desde Jump Server"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jump_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "WebServerSG_clase3"
  }
}

# --- Jump Server (Linux) ---
resource "aws_instance" "jump_server" {
  ami                    = "ami-00a929b66ed6e0de6" # Amazon Linux 2
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_public.id
  vpc_security_group_ids = [aws_security_group.jump_sg.id]
  associate_public_ip_address = true
  key_name               = "vockey"

  tags = {
    Name = "JumpServerclase3"
  }
}

# --- Web Servers (Linux x3) ---
resource "aws_instance" "web_server" {
  count                  = 4
  ami                    = "ami-00a929b66ed6e0de6" # Amazon Linux 2
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subnet_public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  associate_public_ip_address = true
  key_name               = "vockey"

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              EOF

  tags = {
    Name = "WebServeraclase3-${count.index + 1}"
  }
}

# --- Outputs ---
output "jump_server_ip" {
  value       = aws_instance.jump_server.public_ip
  description = "IP pública del Jump Server"
}

output "web_servers_ip" {
  value       = [for instance in aws_instance.web_server : instance.public_ip]
  description = "IPs públicas de los Web Servers"
}
