module "postgres_loader_rds" {
  source  = "snowplow-devops/rds/aws"
  version = "0.4.0"

  name        = "${local.prefix}-pipeline-rds"
  vpc_id      = data.aws_vpc.golden_vpc.id
  subnet_ids  = local.private_subnet_ids
  db_name     = "snowplow"
  db_username = "snowplow"
  db_password = random_password.this.result

  publicly_accessible     = true
  additional_ip_allowlist = local.ssh_ip_allowlist

  tags = local.tags
}

module "postgres_loader_enriched" {
  source  = "snowplow-devops/postgres-loader-kinesis-ec2/aws"
  version = "0.4.3"

  name       = "${local.prefix}-snowplow-postgres-loader-enriched-server"
  vpc_id     = data.aws_vpc.golden_vpc.id
  subnet_ids = local.public_subnet_ids

  min_size                    = local.min_size
  max_size                    = local.max_size
  associate_public_ip_address = true

  in_stream_name = module.enriched_stream.name
  purpose        = "ENRICHED_EVENTS"
  schema_name    = "atomic"

  ssh_key_name     = "snowplow-key-pair"
  ssh_ip_allowlist = local.ssh_ip_allowlist

  telemetry_enabled = local.telemetry_enabled
  user_provided_id  = local.user_provided_id

  # Linking in the custom Iglu Server here
  custom_iglu_resolvers = local.custom_iglu_resolvers

  db_sg_id    = module.postgres_loader_rds.sg_id
  db_host     = module.postgres_loader_rds.address
  db_port     = module.postgres_loader_rds.port
  db_name     = "snowplow"
  db_username = "snowplow"
  db_password = random_password.this.result

  kcl_write_max_capacity = local.pipeline_kcl_write_max_capacity

  tags = local.tags

  cloudwatch_logs_enabled        = local.cloudwatch_logs_enabled
  cloudwatch_logs_retention_days = local.cloudwatch_logs_retention_days
}

module "postgres_loader_bad" {
  source  = "snowplow-devops/postgres-loader-kinesis-ec2/aws"
  version = "0.4.3"

  name       = "${local.prefix}-snowplow-postgres-loader-bad-server"
  vpc_id     = data.aws_vpc.golden_vpc.id
  subnet_ids = local.private_subnet_ids

  min_size                    = local.min_size
  max_size                    = local.max_size
  associate_public_ip_address = local.public_ip  

  in_stream_name = module.bad_1_stream.name
  purpose        = "JSON"
  schema_name    = "atomic_bad"

  ssh_key_name     = "snowplow-key-pair"
  ssh_ip_allowlist = local.ssh_ip_allowlist

  telemetry_enabled = local.telemetry_enabled
  user_provided_id  = local.user_provided_id

  # Linking in the custom Iglu Server here
  custom_iglu_resolvers = local.custom_iglu_resolvers

  db_sg_id    = module.postgres_loader_rds.sg_id
  db_host     = module.postgres_loader_rds.address
  db_port     = module.postgres_loader_rds.port
  db_name     = "snowplow"
  db_username = "snowplow"
  db_password = random_password.this.result

  kcl_write_max_capacity = local.pipeline_kcl_write_max_capacity

  tags = local.tags

  cloudwatch_logs_enabled        = local.cloudwatch_logs_enabled
  cloudwatch_logs_retention_days = local.cloudwatch_logs_retention_days
}
