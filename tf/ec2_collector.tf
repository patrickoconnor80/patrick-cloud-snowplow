module "collector_kinesis" {
  source = "./modules/collector"

  prefix           = local.prefix
  name             = "snowplow-collector"
  vpc_id           = data.aws_vpc.this.id
  subnet_ids       = local.private_subnet_ids
  good_stream_name = module.raw_stream.name
  bad_stream_name  = module.bad_stream.name

  min_size = local.min_size
  max_size = local.max_size

  ssh_key_name     = "snowplow-key-pair"
  ssh_ip_allowlist = local.ssh_ip_allowlist

  tags = local.tags
}


## IAM POLCIY ATTACHMENTS ##

# Policy found at patrick-cloud-snowplow/tf/modules/kinesis/kms.tf:aws_iam_policy.kinesis_kms_access
resource "aws_iam_role_policy_attachment" "collector_raw_stream_access" {
  role       = "${local.prefix}-snowplow-collector-ec2-role"
  policy_arn = module.raw_stream.kinesis_kms_access_policy_arn
}

# Policy found at patrick-cloud-snowplow/tf/modules/kinesis/kms.tf:aws_iam_policy.kinesis_kms_access
resource "aws_iam_role_policy_attachment" "collector_bad_stream_access" {
  role       = "${local.prefix}-snowplow-collector-ec2-role"
  policy_arn = module.bad_stream.kinesis_kms_access_policy_arn
}

# Allow SSM access
resource "aws_iam_role_policy_attachment" "collector_ssm" {
  role       = "${local.prefix}-snowplow-collector-ec2-role"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


## ALARMS ##

resource "aws_cloudwatch_log_metric_filter" "collector" {
  name           = "${local.prefix}-snowplow-collector-error-metric-filter"
  pattern        = "ERROR"
  log_group_name = module.collector_kinesis.log_group
  metric_transformation {
    name      = "${local.prefix}-snowplow-collector-error"
    namespace = "SnowplowError"
    value     = 1
  }
}

resource "aws_cloudwatch_metric_alarm" "collector" {
  alarm_name          = "${local.prefix}-snowplow-collector-error-alarm"
  alarm_description   = "Send email for any errors with Snowplow Collector"
  metric_name         = "${local.prefix}-snowplow-collector-error"
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