module "iglu_rds" {
  # source  = "snowplow-devops/rds/aws"
  # version = "0.4.0"
  source = "git::https://github.com/snowplow-devops/terraform-aws-rds.git?ref=a4a0466e2ed99ad3bc6205264c1012ced0b3dce4"

  name        = "${local.prefix}-iglu-rds"
  vpc_id      = data.aws_vpc.this.id
  subnet_ids  = local.private_subnet_ids
  db_name     = "iglu"
  db_username = "iglu"
  db_password = random_password.this.result

  tags = local.tags
}

module "iglu_server" {
  source = "./modules/iglu"

  prefix        = local.prefix
  name          = "snowplow-iglu"
  subnet_ids    = local.private_subnet_ids
  db_sg_id      = module.iglu_rds.sg_id
  db_host       = module.iglu_rds.address
  db_port       = module.iglu_rds.port
  db_name       = "iglu"
  db_username   = "iglu"
  db_password   = random_password.this.result
  super_api_key = random_uuid.this.result

  min_size = local.min_size
  max_size = local.max_size

  ssh_key_name     = "snowplow-key-pair"
  ssh_ip_allowlist = local.ssh_ip_allowlist

  tags = local.tags
}


## IAM POLCIY ATTACHMENTS ##

# Policy found at patrick-cloud-snowplow/tf/secrets_manager.tf:aws_iam_policy.secrets_kms_access
resource "aws_iam_role_policy_attachment" "iglu_secrets_decrypt_kms" {
  role       = "${local.prefix}-snowplow-iglu-ec2-role"
  policy_arn = aws_iam_policy.secrets_kms_access.arn
}

# Allow SSM access
resource "aws_iam_role_policy_attachment" "iglu_ssm" {
  role       = "${local.prefix}-snowplow-iglu-ec2-role"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


## PASSWORD ##

resource "random_password" "this" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_uuid" "this" {}


## ALARMS ##

resource "aws_cloudwatch_log_metric_filter" "iglu" {
  name           = "${local.prefix}-snowplow-iglu-error-metric-filter"
  pattern        = "ERROR"
  log_group_name = module.iglu_server.log_group
  metric_transformation {
    name      = "${local.prefix}-snowplow-iglu-error"
    namespace = "SnowplowError"
    value     = 1
  }
}

resource "aws_cloudwatch_metric_alarm" "iglu" {
  alarm_name          = "${local.prefix}-snowplow-iglu-error-alarm"
  metric_name         = "${local.prefix}-snowplow-iglu-error"
  namespace           = "SnowplowError"
  threshold           = "0"
  statistic           = "Sum"
  comparison_operator = "GreaterThanThreshold"
  datapoints_to_alarm = "1"
  evaluation_periods  = "1"
  period              = "300"
  alarm_actions       = [data.aws_sns_topic.email.arn]
  tags                = local.tags
}