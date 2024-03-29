resource "aws_cloudwatch_log_group" "this" {
  name              =  "/aws/ec2/${var.prefix}-snowplow-iglu-log-group"
  retention_in_days = 7
  tags = local.tags
}
