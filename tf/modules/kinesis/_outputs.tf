output "kms_id" {
  value       = aws_kms_key.this.arn
  description = "KMS Key ARN"
}

output "kinesis_kms_access_policy_arn" {
  value       = aws_iam_policy.kinesis_kms_access.arn
  description = "AWS IAM Policy access to Kinesis KMS key"
}

output "name" {
  value       = aws_kinesis_stream.this.name
  description = "Kinesis stream name"
}
