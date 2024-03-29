resource "random_password" "this" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "random_uuid" "this" {}

resource "aws_key_pair" "this" {
  key_name   = "${local.prefix}-snowplow-key-pair"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILRWiz+2Ro7E8RmJduWZikiVCvKqBowxOaC58l2Skxyx patrickoconnor8014.com"
}