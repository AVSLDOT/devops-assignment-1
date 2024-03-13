terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider

provider "aws" {
  region = "us-east-1"
  sts_region = "us-east-1"
}

# RSA key of size 4096 bits
resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

variable "key_name" {}

resource "aws_key_pair" "key_pair" {
  key_name   = var.key_name
  public_key = tls_private_key.rsa_4096.public_key_openssh
}

resource "local_file" "private_key" {     
    content = tls_private_key.rsa_4096.private_key_pem
    filename = var.key_name
}

resource "aws_ec2_serial_console_access" "jenkins" {
  enabled = true
}

resource "aws_security_group" "security" {
  name = "allow-all"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}  


resource "aws_instance" "jenkins" {
  ami           = "ami-07d9b9ddc6cd8dd30"
  instance_type = "t2.micro"
  key_name = aws_key_pair.key_pair.key_name 
  tags = {
    Name = "jenkins"
  }
}