module "raw_stream" {
  source = "./modules/kinesis"
  prefix = local.prefix
  name   = "${local.prefix}-snowplow-raw-stream"
  put_record_iam_roles = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-collector-ec2-role"]
  get_record_iam_roles = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-enrich-server"]
  alarm_action = data.aws_sns_topic.email.arn
  tags = local.tags
}

module "bad_stream" {
  source = "./modules/kinesis"
  prefix = local.prefix
  name   = "${local.prefix}-snowplow-bad-stream"
  put_record_iam_roles = [
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-collector-ec2-role",
    "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-enrich-server"
  ]
  get_record_iam_roles = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-transformer-server-wrp"]
  alarm_action = data.aws_sns_topic.email.arn
  tags = local.tags
}

module "enriched_stream" {
  source = "./modules/kinesis"
  prefix = local.prefix
  name   = "${local.prefix}-snowplow-enriched-stream"
  put_record_iam_roles = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-enrich-server"]
  get_record_iam_roles = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-transformer-server-wrp"]
  alarm_action = data.aws_sns_topic.email.arn
  tags = local.tags
}
