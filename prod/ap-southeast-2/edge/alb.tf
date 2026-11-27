resource "aws_security_group" "alb" {
  name        = "${local.name}-alb"
  description = "Public ALB ${local.name}"
  vpc_id      = data.aws_vpc.this.id

  tags = { Name = "${local.name}-alb" }
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  description       = "HTTPS from the internet"
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  description       = "HTTP from the internet, redirected to HTTPS"
}

resource "aws_vpc_security_group_egress_rule" "to_targets" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = data.aws_vpc.this.cidr_block
  ip_protocol       = "tcp"
  from_port         = local.dagu_port
  to_port           = local.dagu_port
  description       = "Dagu targets inside the VPC"
}

resource "aws_lb" "this" {
  name                       = local.name
  load_balancer_type         = "application"
  internal                   = false
  ip_address_type            = "ipv4"
  subnets                    = data.aws_subnets.public.ids
  security_groups            = [aws_security_group.alb.id]
  drop_invalid_header_fields = true

  # Deletion protection stays on; switch it off before destroying the stack.
  enable_deletion_protection = true
}

resource "aws_lb_target_group" "dagu" {
  name                 = "mdb-prod-dagu"
  target_type          = "ip"
  protocol             = "HTTP"
  port                 = local.dagu_port
  vpc_id               = data.aws_vpc.this.id
  deregistration_delay = 30

  health_check {
    path    = "/api/v1/health"
    matcher = "200"
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-Res-2021-06"
  certificate_arn   = data.aws_acm_certificate.this.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.dagu.arn
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_route53_record" "dagu" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}
