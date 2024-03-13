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


resource "aws_vpc" "jenkins-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
  Name = "jenkins"
}
}

 resource "aws_subnet" "subnet-1" {
   vpc_id            = aws_vpc.jenkins-vpc.id
   cidr_block        = "10.0.1.0/24"
   map_public_ip_on_launch = true
   depends_on = [aws_vpc.jenkins-vpc]
   availability_zone = "us-east-1a"
   tags = {
     Name = "jenkins-subnet1"
   }
 }

resource "aws_route_table" "jenkins-route-table" {
vpc_id = aws_vpc.jenkins-vpc.id
 tags = {
     Name = "jenkins"
   }
 }

resource "aws_route_table_association" "assiciation" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.jenkins-route-table.id
}

resource "aws_internet_gateway" "gw" {
 vpc_id = aws_vpc.jenkins-vpc.id
depends_on = [aws_vpc.jenkins-vpc]
 }

resource "aws_route" "jenkins-route" {
 route_table_id = aws_route_table.jenkins-route-table.id
 destination_cidr_block = "0.0.0.0/0"
 gateway_id = aws_internet_gateway.gw.id
 }

resource "aws_security_group" "allow_jenkins_ssh" {
   name        = "allow_jenkins_ssh_traffic"
   description = "Allow Jenkins and ssh inbound traffic"
     vpc_id      = aws_vpc.jenkins-vpc.id
ingress {
     description = "HTTP_Jenkins"
     from_port   = 8080
     to_port     = 8080
     protocol    = "tcp"
     cidr_blocks = ["0.0.0.0/0"]
   }
   ingress {
     description = "SSH"
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
     Name = "allow_jenkins_ssh"
   }
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


resource "aws_instance" "jenkins" {
  ami           = "ami-07d9b9ddc6cd8dd30"
  instance_type = "t2.micro"
  key_name = aws_key_pair.key_pair.key_name 
  tags = {
    Name = "jenkins"
  }
  security_groups = [aws_security_group.allow_jenkins_ssh.name]
}
