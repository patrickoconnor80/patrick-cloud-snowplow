locals {
  prefix             = "patrick-cloud-${var.env}"
  public_subnet_ids  = [for subnet in data.aws_subnet.public : subnet.id]
  private_subnet_ids = [for subnet in data.aws_subnet.private : subnet.id]
  sqs_queue_name     = "${local.prefix}-snowplow-db-loader.fifo"
  sns_topic_name     = "${local.prefix}-snowplow-monitoring-sns"
  ssh_ip_allowlist   = [format("%s/%s", data.external.whatismyip.result["internet_ip"], 32)]
  min_size           = 0
  max_size           = 1
  tags = {
    env        = var.env
    project    = "patrick-cloud"
    deployment = "terraform"
    repo       = "https://github.com/patrickoconnor80/patrick-cloud-snowplow/tree/main/tf"
  }
  custom_iglu_resolvers = [
    {
      name            = "Custom Iglu Server"
      priority        = 15
      uri             = "https://snowplow-iglu.patrick-cloud.com/api"
      api_key         = random_uuid.this.result
      vendor_prefixes = ["com.patrick-cloud"]
    }
  ]
  default_iglu_resolvers = [
    {
      api_key  = "",
      name     = "Iglu Central",
      priority = 10,
      uri      = "http://iglucentral.com",
      vendor_prefixes : []
    },
    {
      api_key         = "",
      name            = "Iglu Central - Mirror 01",
      priority        = 20,
      uri             = "http://mirror01.iglucentral.com",
      vendor_prefixes = []
    }
  ]
}