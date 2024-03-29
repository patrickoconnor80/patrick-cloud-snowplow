locals {
    prefix = "patrick-cloud-${var.env}"
    public_subnet_ids = [for subnet in data.aws_subnet.public : subnet.id]
    private_subnet_ids = [for subnet in data.aws_subnet.private : subnet.id]
    ssh_ip_allowlist = [format("%s/%s",data.external.whatismyip.result["internet_ip"],32)]
    telemetry_enabled = false
    user_provided_id = "pco"
    cloudwatch_logs_enabled = true
    cloudwatch_logs_retention_days = 7
    pipeline_kcl_write_max_capacity = 50
    min_size = 1
    max_size = 2
    public_ip = false
    custom_iglu_resolvers = [
        {
        name            = "Iglu Server"
        priority        = 0
        uri             = "https://snowplow.patrick-cloud/iglu/api"
        api_key         = random_uuid.this.result
        vendor_prefixes = []
        }
    ]
}