module "enrich_kinesis" {
  source  = "snowplow-devops/enrich-kinesis-ec2/aws"
  version = "0.5.3"

  name                 = "${local.prefix}-snowplow-enrich-server"
  vpc_id               = data.aws_vpc.this.id
  subnet_ids           = local.private_subnet_ids
  in_stream_name       = module.raw_stream.name
  enriched_stream_name = module.enriched_stream.name
  bad_stream_name      = module.bad_stream.name

  min_size                    = local.min_size
  max_size                    = local.max_size
  associate_public_ip_address = false

  ssh_key_name     = aws_key_pair.this.key_name
  ssh_ip_allowlist = local.ssh_ip_allowlist

  telemetry_enabled = false
  user_provided_id  = "pco"

  # Linking in the custom Iglu Server here
  custom_iglu_resolvers  = local.custom_iglu_resolvers
  default_iglu_resolvers = local.default_iglu_resolvers

  kcl_write_max_capacity = 50

  tags = local.tags

  cloudwatch_logs_enabled        = true
  cloudwatch_logs_retention_days = 7
}


## IAM POLCIY ATTACHMENTS ##

# Policy found at patrick-cloud-snowplow/tf/modules/kinesis/kms.tf:aws_iam_policy.kinesis_kms_access
resource "aws_iam_role_policy_attachment" "enrich_raw_stream_access" {
  role       = "${local.prefix}-snowplow-enrich-server"
  policy_arn = module.raw_stream.kinesis_kms_access_policy_arn
}

# Policy found at patrick-cloud-snowplow/tf/modules/kinesis/kms.tf:aws_iam_policy.kinesis_kms_access
resource "aws_iam_role_policy_attachment" "enrich_bad_stream_access" {
  role       = "${local.prefix}-snowplow-enrich-server"
  policy_arn = module.bad_stream.kinesis_kms_access_policy_arn
}

# Policy found at patrick-cloud-snowplow/tf/modules/kinesis/kms.tf:aws_iam_policy.kinesis_kms_access
resource "aws_iam_role_policy_attachment" "enrich_enrich_stream_access" {
  role       = "${local.prefix}-snowplow-enrich-server"
  policy_arn = module.enriched_stream.kinesis_kms_access_policy_arn
}

# Allow SSM access
resource "aws_iam_role_policy_attachment" "enrich_ssm" {
  role       = "${local.prefix}-snowplow-enrich-server"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


## ALARMS ##

resource "aws_cloudwatch_log_metric_filter" "enrich" {
  name           = "${local.prefix}-snowplow-enrich-error-metric-filter"
  pattern        = "ERROR"
  log_group_name = "/aws/ec2/${local.prefix}-snowplow-enrich-server"
  metric_transformation {
    name      = "${local.prefix}-snowplow-enrich-error"
    namespace = "SnowplowError"
    value     = 1
  }
}

resource "aws_cloudwatch_metric_alarm" "enrich" {
  alarm_name          = "${local.prefix}-snowplow-enrich-error-alarm"
  metric_name         = "${local.prefix}-snowplow-enrich-error"
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