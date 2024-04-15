resource "aws_s3_bucket" "this" {
  bucket        = "${local.prefix}-snowplow"
  force_destroy = true
  tags = merge(local.tags, {
    Name = "${local.prefix}-snowplow"
  })
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "this" {
  depends_on = [aws_s3_bucket_ownership_controls.this]

  bucket = aws_s3_bucket.this.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket                  = aws_s3_bucket.this.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  depends_on              = [aws_s3_bucket.this]
}


## BUCKET POLICY ##

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket     = aws_s3_bucket.this.id
  policy     = data.aws_iam_policy_document.bucket_policy.json
  depends_on = [aws_s3_bucket_public_access_block.this]
}

data "aws_iam_policy_document" "bucket_policy" {
      statement {
        sid    = "ReadBucketMetadata"
        effect = "Allow"
        principals {
          type        = "AWS"
          identifiers = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-db-loader-server",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-transformer-server-wrp"
          ]
        }
        actions = [
          "s3:ListBucket"
        ]
        resources = [aws_s3_bucket.this.arn]
      }

      statement {
        sid    = "ReadContentsFromBucket"
        effect = "Allow"
        principals {
          type = "AWS"
          identifiers = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-db-loader-server",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-transformer-server-wrp"
          ]
        }
        actions = [
          "s3:GetObject",
          "s3:GetObjectAcl"
        ]
        resources = ["${aws_s3_bucket.this.arn}/transformed/*"]
      }

      statement {
        sid    = "WriteToBucket"
        effect = "Allow"
        principals {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-transformer-server-wrp"]
        }
        actions = [
          "s3:PutObject",
          "s3:PutObjectAcl",
          "s3:DeleteObject"
        ]
        resources = ["${aws_s3_bucket.this.arn}/transformed/*"]
      }

      statement {
        sid    = "AdminAccessToBucket"
        effect = "Allow"
        principals {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
        }
        actions = ["s3:*"]
        resources = ["${aws_s3_bucket.this.arn}/*","${aws_s3_bucket.this.arn}"]
      }
}


## KMS ## 

resource "aws_kms_key" "s3_bucket" {
  description             = "CMK for the Snowplow S3 Bucket"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  is_enabled              = true
  policy                  = data.aws_iam_policy_document.s3_kms_policy.json

  tags = local.tags
}

resource "aws_kms_alias" "s3_bucket" {
  name          = "alias/${local.prefix}-snowplow-s3-bucket"
  target_key_id = aws_kms_key.s3_bucket.key_id
}

data "aws_iam_policy_document" "s3_kms_policy" {
  statement {
    sid    = "WriteToS3Bucket"
    effect = "Allow"
    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-transformer-server-wrp",
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-db-loader-server"
      ]
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDatKey"
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

resource "aws_iam_policy" "kms_decrypt_s3_bucket" {
  name        = "${local.prefix}-snowplow-kms-decrypt-s3-bucket-policy"
  path        = "/"
  description = "This Policy give read only access to the Snowplow S3 Bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "WriteToBucket"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.s3_bucket.arn
      }
    ]
  })

  tags = local.tags
}


## ALARMS ##

resource "aws_cloudwatch_metric_alarm" "s3_4xxErrors" {
  alarm_name          = "${local.prefix}-snowplow-4xxErrors-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 15
  metric_name         = "4xxErrors"
  namespace           = "AWS/S3"
  period              = 60
  statistic           = "Average"
  threshold           = ".05"
  datapoints_to_alarm = 15
  alarm_description   = "This alarm helps us report the total number of 4xx error status codes that are made in response to client requests. 403 error codes might indicate an incorrect IAM policy, and 404 error codes might indicate mis-behaving client application"
  alarm_actions       = [data.aws_sns_topic.email.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName = "${local.prefix}-snowplow"
    FilterId   = "EntireBucket"
  }

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "s3_5xxErrors" {
  alarm_name          = "${local.prefix}-snowplow-5xxErrors-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 15
  metric_name         = "5xxErrors"
  namespace           = "AWS/S3"
  period              = 60
  statistic           = "Average"
  threshold           = ".05"
  datapoints_to_alarm = 15
  alarm_description   = "This alarm helps you detect a high number of server-side errors. These errors indicate that a client made a request that the server couldn’t complete."
  alarm_actions       = [data.aws_sns_topic.email.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    BucketName = "${local.prefix}-snowplow"
    FilterId   = "EntireBucket"
  }

  tags = local.tags
}
