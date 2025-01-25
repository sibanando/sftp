# Route 53 Hosted Zone
resource "aws_route53_zone" "main" {
  name = "talktech.in" # Replace with your domain name
}

# DNS Record for ALB
resource "aws_route53_record" "alb_record" {
  zone_id = aws_route53_zone.main.id
  name    = "sftp.talktech.in" # Replace with your subdomain
  type    = "A"

  alias {
    name                   = aws_lb.alb.dns_name
    zone_id                = aws_lb.alb.zone_id
    evaluate_target_health = true
  }
}
