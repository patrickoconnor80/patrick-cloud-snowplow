resource "aws_secretsmanager_secret" "this" {
  name = "snowplow_rds_password"
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = random_password.this.result
}