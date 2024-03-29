module "s3_pipeline_bucket" {
  source  = "snowplow-devops/s3-bucket/aws"
  version = "0.2.0"

  bucket_name = "${local.prefix}-snowplow"

  tags = var.tags
}