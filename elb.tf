# ALB Security Group
resource "aws_security_group" "alb_sg_lb" {
  name        = "alb_sg_lb"
  description = "Security group for ALB"

  ingress {
    from_port   = 22   # SFTP port
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

# ALB
resource "aws_lb" "alb" {
  name               = "sftp-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.alb_sg_lb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

# ALB Listener
resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 22
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_target_group.arn
  }
}

# ALB Target Group
resource "aws_lb_target_group" "alb_target_group" {
  name        = "sftp-target-group"
  port        = 22
  protocol    = "TCP"
  target_type = "instance"

  health_check {
    protocol = "TCP"
    port     = "22"
  }
}

# Register AWS Transfer Family as Target in the ALB Target Group
resource "aws_lb_target_group_attachment" "alb_target_group_attachment" {
  target_group_arn = aws_lb_target_group.alb_target_group.arn
  target_id        = aws_transfer_server.internal_sftp.id
  port             = 22
}
