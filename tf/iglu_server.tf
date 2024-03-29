module "iglu_rds" {
  source  = "snowplow-devops/rds/aws"
  version = "0.4.0"

  name        = "${local.prefix}-iglu-rds"
  vpc_id      = data.aws_vpc.golden_vpc.id
  subnet_ids  = local.private_subnet_ids
  db_name     = "iglu"
  db_username = "iglu"
  db_password = random_password.this.result

  tags = var.tags
}

module "iglu_server" {
  #source  = "snowplow-devops/iglu-server-ec2/aws"
  source  = "./modules/iglu"

  prefix               = "${local.prefix}"
  name                 = "snowplow-iglu"
  subnet_ids           = local.public_subnet_ids
  db_sg_id             = module.iglu_rds.sg_id
  db_host              = module.iglu_rds.address
  db_port              = module.iglu_rds.port
  db_name              = "iglu"
  db_username          = "iglu"
  db_password          = random_password.this.result
  super_api_key        = random_uuid.this.result

  min_size                    = local.min_size
  max_size                    = local.max_size

  ssh_key_name     = "snowplow-key-pair"
  ssh_ip_allowlist = local.ssh_ip_allowlist

  tags = var.tags

}