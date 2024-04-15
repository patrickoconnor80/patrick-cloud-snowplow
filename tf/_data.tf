data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

data "aws_vpc" "this" {
  filter {
    name   = "tag:Name"
    values = ["${local.prefix}-vpc"]
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "tag:Name"
    values = ["${local.prefix}-public-us-east-1*"]
  }
}

data "aws_subnet" "public" {
  for_each = toset(data.aws_subnets.public.ids)
  id       = each.value
}

data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = ["${local.prefix}-private-us-east-1*"]
  }
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

data "external" "whatismyip" {
  program = ["/bin/bash", "../bin/whatismyip.sh"]
}

data "aws_secretsmanager_secret" "databricks_token" {
  name = "DATABRICKS_TOKEN_"
}

data "aws_secretsmanager_secret_version" "databricks_token" {
  secret_id = data.aws_secretsmanager_secret.databricks_token.id
}

data "aws_sns_topic" "email" {
  name = "${local.prefix}-email-sns"
}