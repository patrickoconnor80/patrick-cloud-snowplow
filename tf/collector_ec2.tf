module "collector_kinesis" {
  source  = "./modules/collector"
  
  prefix               = "${local.prefix}"
  name               = "snowplow-collector"
  vpc_id             = data.aws_vpc.golden_vpc.id
  subnet_ids         = local.public_subnet_ids
  good_stream_name   = module.raw_stream.name
  bad_stream_name    = module.bad_1_stream.name

  min_size                    = local.min_size
  max_size                    = local.max_size

  ssh_key_name     = "snowplow-key-pair"
  ssh_ip_allowlist = local.ssh_ip_allowlist

  tags = var.tags
}