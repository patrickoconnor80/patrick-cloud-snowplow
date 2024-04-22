module "db_loader" {
  # source = "snowplow-devops/databricks-loader-ec2/aws"
  # version = 0.2.1
  source = "git::https://github.com/snowplow-devops/terraform-aws-databricks-loader-ec2.git?ref=036344c9313fbccd1584a2f23aa54b3b69cf7cc1"

  accept_limited_use_license = true
  telemetry_enabled          = false

  name       = "${local.prefix}-snowplow-db-loader-server"
  vpc_id     = data.aws_vpc.this.id
  subnet_ids = local.private_subnet_ids

  sqs_queue_name = aws_sqs_queue.this.name

  deltalake_catalog             = "snowplow"
  deltalake_schema              = "atomic"
  deltalake_host                = data.aws_secretsmanager_secret_version.databricks_host.secret_string
  deltalake_port                = "443"
  deltalake_http_path           = data.aws_secretsmanager_secret_version.databricks_sql_endpoint.secret_string
  deltalake_auth_token          = data.aws_secretsmanager_secret_version.databricks_token.secret_string
  databricks_aws_s3_bucket_name = aws_s3_bucket.this.id

  ssh_key_name     = "snowplow-key-pair"
  ssh_ip_allowlist = local.ssh_ip_allowlist

  # Linking in the custom Iglu Server here
  custom_iglu_resolvers = local.custom_iglu_resolvers
}


## IAM POLCIY ATTACHMENTS ##

# Policy found at patrick-cloud-snowplow/tf/s3_iam_access.tf:aws_iam_policy.kms_decrypt_s3_bucket
resource "aws_iam_role_policy_attachment" "loader_kms_decrypt_s3" {
  role       = "${local.prefix}-snowplow-db-loader-server"
  policy_arn = aws_iam_policy.kms_decrypt_s3_bucket.arn
}

# Policy found at patrick-cloud-snowplow/tf/sqs_databricks.tf:aws_iam_policy.sqs_kms_access
resource "aws_iam_role_policy_attachment" "loader_kms_descrypt_sqs" {
  role       = "${local.prefix}-snowplow-db-loader-server"
  policy_arn = aws_iam_policy.sqs_kms_access.arn
}

# Allow SSM access
resource "aws_iam_role_policy_attachment" "loader_ssm" {
  role       = "${local.prefix}-snowplow-db-loader-server"
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}


## ALARMS ##

resource "aws_cloudwatch_log_metric_filter" "loader" {
  name           = "${local.prefix}-snowplow-loader-error-metric-filter"
  pattern        = "ERROR"
  log_group_name = "/aws/ec2/${local.prefix}-snowplow-db-loader-server"
  metric_transformation {
    name      = "${local.prefix}-snowplow-loader-error"
    namespace = "SnowplowError"
    value     = 1
  }
}

resource "aws_cloudwatch_metric_alarm" "loader" {
  alarm_name          = "${local.prefix}-snowplow-loader-error-alarm"
  metric_name         = "${local.prefix}-snowplow-loader-error"
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