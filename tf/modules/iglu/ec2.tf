module "service" {
  source  = "snowplow-devops/service-ec2/aws"
  version = "0.2.1"

  user_supplied_script = local.user_data
  name                 = "${var.prefix}-${var.name}"
  tags                 = local.tags

  amazon_linux_2_ami_id       = data.aws_ami.amazon_linux_2.id
  instance_type               = "t3a.micro"
  ssh_key_name                = var.ssh_key_name
  iam_instance_profile_name   = aws_iam_instance_profile.this.name
  security_groups             = [data.aws_security_group.snowplow_iglu.id]

  min_size   = var.min_size
  max_size   = var.max_size
  subnet_ids = var.subnet_ids

  health_check_type = "ELB"

  target_group_arns = [data.aws_alb_target_group.snowplow_iglu.arn]
  enable_auto_scaling                 = true
  scale_up_cooldown_sec               = 180
  scale_up_cpu_threshold_percentage   = 60
  scale_up_eval_minutes               = 5
  scale_down_cooldown_sec             = 600
  scale_down_cpu_threshold_percentage = 20
  scale_down_eval_minutes             = 60
}