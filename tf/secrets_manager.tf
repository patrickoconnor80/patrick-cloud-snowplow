## SECRET - SNOWPLOW_IGLU_RDS_PASSWORD ##

resource "aws_secretsmanager_secret" "rds_password" {
  name       = "SNOWPLOW_IGLU_RDS_PASSWORD"
  policy     = data.aws_iam_policy_document.secrets_policy.json
  kms_key_id = aws_kms_key.secrets.key_id
  tags       = local.tags
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id     = aws_secretsmanager_secret.rds_password.id
  secret_string = random_password.this.result
}


## SECRET - SNOWPLOW_IGLU_SUPER_API_KEY ##

resource "aws_secretsmanager_secret" "super_api_key" {
  name       = "SNOWPLOW_IGLU_SUPER_API_KEY"
  policy     = data.aws_iam_policy_document.secrets_policy.json
  kms_key_id = aws_kms_key.secrets.key_id
  tags       = local.tags
}

resource "aws_secretsmanager_secret_version" "super_api_key" {
  secret_id     = aws_secretsmanager_secret.super_api_key.id
  secret_string = random_uuid.this.result
}


## IAM ACCESS POLICY ##

data "aws_iam_policy_document" "secrets_policy" {

  statement {
    sid    = "GetSecret"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-iglu-ec2-role"]
    }
    actions = ["secretsmanager:GetSecretValue"]
    resources = [
      "arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:SNOWPLOW_IGLU_*"
    ]
  }

  statement {
    sid    = "AdminAccessToSecret"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "secretsmanager:*"
    ]
    resources = ["arn:aws:secretsmanager:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:secret:SNOWPLOW_IGLU_*"]
  }
}


## KMS ##

resource "aws_kms_key" "secrets" {
  description             = "CMK for the Snowplow RDS Secrets"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  is_enabled              = true
  policy                  = data.aws_iam_policy_document.secrets_kms_policy.json

  tags = local.tags
}

resource "aws_kms_alias" "secrets" {
  name          = "alias/${local.prefix}-snowplow-rds-secrets"
  target_key_id = aws_kms_key.secrets.key_id
}

data "aws_iam_policy_document" "secrets_kms_policy" {
  statement {
    sid    = "DecryptSecretsKMSKey"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-iglu-ec2-role"]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AdminAccessToKMS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = [
      "kms:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "secrets_kms_access" {
  name        = "${local.prefix}-snowplow-rds-kms-access"
  path        = "/"
  description = "This Policy gives KMS access to Snowplow Secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "DecryptKMSkeyforSecrets"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Effect   = "Allow"
        Resource = aws_kms_key.secrets.arn
      }
    ]
  })

  tags = local.tags
}