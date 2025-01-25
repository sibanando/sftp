provider "aws" {
    region = "us-west-2"
}

# VPC
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
}

# Public Subnet
resource "aws_subnet" "public" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.1.0/24"
    map_public_ip_on_launch = true
    availability_zone = "us-west-2a"
}

# Private Subnet
resource "aws_subnet" "private" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.2.0/24"
    availability_zone = "us-west-2a"
}

resource "aws_subnet" "private2" {
    vpc_id            = aws_vpc.main.id
    cidr_block        = "10.0.3.0/24"
    availability_zone = "us-west-2b"
}

# NAT Gateway
resource "aws_eip" "nat" {
    associate_with_private_ip = true
}

resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat.id
    subnet_id     = aws_subnet.public.id
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }
}

resource "aws_route_table_association" "public" {
    subnet_id      = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
}

# Route Table for Private Subnet
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat.id
    }
}

resource "aws_route_table_association" "private" {
    subnet_id      = aws_subnet.private.id
    route_table_id = aws_route_table.private.id
}

resource "aws_route_table" "private2" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat.id
    }
}

resource "aws_route_table_association" "private2" {
    subnet_id      = aws_subnet.private2.id
    route_table_id = aws_route_table.private2.id
}

# S3 Bucket
resource "aws_s3_bucket" "sftp_bucket" {
    bucket = "my-sftp-bucket"
}

# IAM Role
resource "aws_iam_role" "sftp_role" {
    name = "sftp-role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Principal = {
                    Service = "transfer.amazonaws.com"
                }
            }
        ]
    })
}

resource "aws_iam_role_policy" "sftp_policy" {
    role = aws_iam_role.sftp_role.id

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "s3:ListBucket",
                    "s3:GetObject",
                    "s3:PutObject"
                ]
                Effect   = "Allow"
                Resource = [
                    aws_s3_bucket.sftp_bucket.arn,
                    "${aws_s3_bucket.sftp_bucket.arn}/*"
                ]
            }
        ]
    })
}

# Security Group
resource "aws_security_group" "sftp_sg" {
    vpc_id = aws_vpc.main.id

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

# AWS Transfer Family
resource "aws_transfer_server" "sftp" {
    endpoint_type = "VPC"
    identity_provider_type = "SERVICE_MANAGED"
    endpoint_details {
    vpc_id            = aws_vpc.main.id
    subnet_ids        = [aws_subnet.private.id, aws_subnet.private2.id]
    security_group_ids = [aws_security_group.sftp_sg.id]
  }
  protocols = ["SFTP"]
  logging_role = aws_iam_role.sftp_role.arn
}

# Application Load Balancer
resource "aws_lb" "internal" {
    name               = "alb-internal"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [aws_security_group.sftp_sg.id]
    subnets            = [aws_subnet.public.id]
}

resource "aws_lb_target_group" "sftp_tg" {
    name     = "sftp-tg"
    port     = 22
    protocol = "TCP"
    vpc_id   = aws_vpc.main.id
}

resource "aws_lb_listener" "sftp_listener" {
    load_balancer_arn = aws_lb.internal.arn
    port              = 22
    protocol          = "TCP"

    default_action {
        type             = "forward"
        target_group_arn = aws_lb_target_group.sftp_tg.arn
    }
}

# Route 53
resource "aws_route53_zone" "main" {
    name = "talktech.in"
}

resource "aws_route53_record" "sftp" {
    zone_id = aws_route53_zone.main.zone_id
    name    = "sftp"
    type    = "CNAME"
    alias {
        name                   = aws_lb.internal.dns_name
        zone_id                = aws_lb.internal.zone_id
        evaluate_target_health = true
    }
}