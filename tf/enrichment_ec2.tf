module "enrich_kinesis" {
  source  = "snowplow-devops/enrich-kinesis-ec2/aws"
  version = "0.5.3"

  name                 = "${local.prefix}-snowplow-enrich-server"
  vpc_id               = data.aws_vpc.golden_vpc.id
  subnet_ids           = local.private_subnet_ids
  in_stream_name       = module.raw_stream.name
  enriched_stream_name = module.enriched_stream.name
  bad_stream_name      = module.bad_1_stream.name

  min_size                    = local.min_size
  max_size                    = local.max_size
  associate_public_ip_address = local.public_ip

  ssh_key_name     = aws_key_pair.this.key_name
  ssh_ip_allowlist = local.ssh_ip_allowlist

  telemetry_enabled = local.telemetry_enabled
  user_provided_id  = local.user_provided_id

  # Linking in the custom Iglu Server here
  custom_iglu_resolvers = local.custom_iglu_resolvers

  kcl_write_max_capacity = 50

  tags = var.tags

  cloudwatch_logs_enabled        = local.cloudwatch_logs_enabled
  cloudwatch_logs_retention_days = local.cloudwatch_logs_retention_days
}