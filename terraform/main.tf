terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.50"
    }
  }
}

provider "aws" {
  access_key                  = "test"
  secret_key                  = "test"
  region                      = "us-east-1"
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://127.0.0.1:4566"
    sts = "http://127.0.0.1:4566"
  }
}

# Passo 3: Regras de Firewall (Security Group)
resource "aws_security_group" "app_sg" {
  name        = "app_security_group"
  description = "Permitir trafego para a API Node"

  ingress {
    description = "Porta da aplicacao Node"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Saida total"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Passo 4 & 5: Criacao da Instancia EC2 e User Data
resource "aws_instance" "app_server" {
  ami                    = "ami-0c55b159cbfafe1f0" # Mock AMI para LocalStack
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.app_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nodejs npm
              mkdir -p /app
              cd /app
              cat << 'ENTRY' > package.json
              ${file("${path.module}/../package.json")}
              ENTRY
              npm install
              nohup node src/index.js > app.log 2>&1 &
              EOF

  tags = {
    Name = "NodeApp-Desafio5"
  }
}