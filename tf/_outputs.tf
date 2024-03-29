# --- Target: PostgreSQL

output "postgres_db_address" {
  description = "The RDS DNS name where your data is being streamed"
  value       = module.postgres_loader_rds.address
}

output "postgres_db_port" {
  description = "The RDS port where your data is being streamed"
  value       = module.postgres_loader_rds.port
}

output "postgres_db_id" {
  description = "The ID of the RDS instance"
  value       = module.postgres_loader_rds.id
}