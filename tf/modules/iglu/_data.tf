data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_security_group" "snowplow_iglu" {
  name = "${var.prefix}-snowplow-iglu-sg"
}

data "aws_security_group" "alb_sg" {
  name = "${var.prefix}-alb-sg"
}

data "aws_iam_role" "snowplow_iglu" {
  name = "${var.prefix}-snowplow-iglu-ec2-role"
}

data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["amazon"]
}

data "aws_alb_target_group" "snowplow_iglu" {
  name = "${var.prefix}-snow-iglu-tg"
}