provider "aws" {
  region = "us-west-2"
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create public subnets
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"
}



# Security Group for the Transfer Family server
resource "aws_security_group" "alb_sg" {
  name        = "alb_sg"
  description = "Allow SFTP traffic"
  vpc_id      = aws_vpc.main.id

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
}

# AWS Transfer Family server with internal endpoint
resource "aws_transfer_server" "internal_sftp" {
  identity_provider_type = "SERVICE_MANAGED"
  endpoint_type          = "VPC"
  endpoint_details {
    vpc_id            = aws_vpc.main.id
    subnet_ids        = [aws_subnet.public_1.id, aws_subnet.public_2.id]
    security_group_ids = [aws_security_group.alb_sg.id]
  }
  protocols = ["SFTP"]
  logging_role = aws_iam_role.transfer_role.arn
}