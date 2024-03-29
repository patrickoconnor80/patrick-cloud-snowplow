resource "aws_security_group_rule" "ingress_tcp_22" {
  description       =  "Allow ssh from local"
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = var.ssh_ip_allowlist
  security_group_id = data.aws_security_group.snowplow_collector.id
}

resource "aws_security_group_rule" "egress_tcp_443" {
  description       = "Allow HTTPS Traffic from the ALB"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  source_security_group_id = data.aws_security_group.alb_sg.id
  security_group_id = data.aws_security_group.snowplow_collector.id
}

resource "aws_security_group_rule" "egress_udp_123" {
  description = "Allow outbound traffic on port 123 for Snowplows clock synchronization"
  type              = "egress"
  from_port         = 123
  to_port           = 123
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.snowplow_collector.id
}

resource "aws_security_group_rule" "egress" {
  type              = "egress"
  description = "Allow all outbound requests"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.snowplow_collector.id
}