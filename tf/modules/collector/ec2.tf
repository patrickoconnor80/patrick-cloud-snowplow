module "service" {
  # source  = "snowplow-devops/service-ec2/aws"
  # version = "0.2.1"
  source = "git::https://github.com/snowplow-devops/terraform-aws-service-ec2.git?ref=ea38577ac9c2bbaddb6318428d1b81c8a091a817"

  user_supplied_script = local.user_data
  name                 = "${var.prefix}-${var.name}"
  tags                 = local.tags

  amazon_linux_2_ami_id       = data.aws_ami.amazon_linux_2.id
  instance_type               = "t3a.micro"
  ssh_key_name                = var.ssh_key_name
  iam_instance_profile_name   = aws_iam_instance_profile.this.name
  security_groups             = [data.aws_security_group.snowplow_collector.id]

  min_size   = var.min_size
  max_size   = var.max_size

  subnet_ids = var.subnet_ids
  associate_public_ip_address = false

  health_check_type = "ELB"

  target_group_arns = [data.aws_alb_target_group.snowplow_collector.arn]
  enable_auto_scaling                 = true
  scale_up_cooldown_sec               = 180
  scale_up_cpu_threshold_percentage   = 60
  scale_up_eval_minutes               = 5
  scale_down_cooldown_sec             = 600
  scale_down_cpu_threshold_percentage = 20
  scale_down_eval_minutes             = 60
}