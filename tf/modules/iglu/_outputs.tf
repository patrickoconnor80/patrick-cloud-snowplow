output "asg_id" {
  value       = module.service.asg_id
  description = "ID of the ASG"
}

output "asg_name" {
  value       = module.service.asg_name
  description = "Name of the ASG"
}

output "log_group" {
  value       = aws_cloudwatch_log_group.this.name
  description = "Name of the log group"
}
