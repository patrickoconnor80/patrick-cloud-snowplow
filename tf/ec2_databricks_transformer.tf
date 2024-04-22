module "transformer_wrp" {
  # source = "snowplow-devops/transformer-kinesis-ec2/aws"
  # version = 0.4.1
  source = "git::https://github.com/snowplow-devops/terraform-aws-transformer-kinesis-ec2.git?ref=f1c8b3f89c17a78de495a4d03a571b460148c66f"


  accept_limited_use_license = true
  telemetry_enabled          = false

  name       = "${local.prefix}-snowplow-transformer-server-wrp"
  vpc_id     = data.aws_vpc.this.id
  subnet_ids = local.private_subnet_ids

  stream_name             = module.enriched_stream.name
  s3_bucket_name          = aws_s3_bucket.this.id
  s3_bucket_object_prefix = "transformed/good/widerow/parquet"
  window_period_min       = 1
  sqs_queue_name          = aws_sqs_queue.this.name

  transformation_type = "widerow"
  widerow_file_format = "parquet"

  ssh_key_name     = "snowplow-key-pair"
  ssh_ip_allowlist = local.ssh_ip_allowlist

  # Linking in the custom Iglu Server here
  custom_iglu_resolvers = local.custom_iglu_resolvers
}


## IAM POLCIY ATTACHMENTS ##

# Policy found at patrick-cloud-snowplow/tf/s3_iam_access.tf:aws_iam_policy.kms_decrypt_s3_bucket
resource "aws_iam_role_policy_attachment" "transformer_kms_descrypt_s3" {
  role       = "${local.prefix}-snowplow-transformer-server-wrp"
  policy_arn = aws_iam_policy.kms_decrypt_s3_bucket.arn
}

# Policy found at patrick-cloud-snowplow/tf/modules/kinesis/kms.tf:aws_iam_policy.kinesis_kms_access
resource "aws_iam_role_policy_attachment" "transformer_decrypt_enrich_stream" {
  role       = "${local.prefix}-snowplow-transformer-server-wrp"
  policy_arn = module.enriched_stream.kinesis_kms_access_policy_arn
}

# Policy found at patrick-cloud-snowplow/tf/sqs_databricks.tf:aws_iam_policy.sqs_kms_access
resource "aws_iam_role_policy_attachment" "transformer_decrypt_sqs" {
  role       = "${local.prefix}-snowplow-transformer-server-wrp"
  policy_arn = aws_iam_policy.sqs_kms_access.arn
}

# Allow SSM access
resource "aws_iam_role_policy_attachment" "transformer_ssm" {
  role       = "${local.prefix}-snowplow-transformer-server-wrp"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}



## ALARMS ##

resource "aws_cloudwatch_log_metric_filter" "transformer" {
  name           = "${local.prefix}-snowplow-transformer-error-metric-filter"
  pattern        = "ERROR"
  log_group_name = "/aws/ec2/${local.prefix}-snowplow-transformer-server-wrp"
  metric_transformation {
    name      = "${local.prefix}-snowplow-transformer-error"
    namespace = "SnowplowError"
    value     = 1
  }
}

resource "aws_cloudwatch_metric_alarm" "transformer" {
  alarm_name          = "${local.prefix}-snowplow-transformer-error-alarm"
  metric_name         = "${local.prefix}-snowplow-transformer-error"
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

