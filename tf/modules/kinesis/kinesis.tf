resource "aws_kinesis_stream" "this" {
  name             = var.name
  shard_count      = 1
  retention_period = 24
  encryption_type  = "KMS"
  kms_key_id       = aws_kms_key.this.id
  enforce_consumer_deletion = true

  tags = var.tags

  stream_mode_details {
    stream_mode = "PROVISIONED"
  }
}


## IAM ACCESS POLICY ##

resource "aws_kinesis_resource_policy" "this" {
  resource_arn = aws_kinesis_stream.this.arn
  policy = data.aws_iam_policy_document.kinesis_access_policy.json
}

data "aws_iam_policy_document" "kinesis_access_policy" {
  statement {
    sid    = "PutRecordToKinesis"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = var.put_record_iam_roles
    }
    actions   = [
      "kinesis:DescribeStreamSummary",
      "kinesis:ListShards",
      "kinesis:PutRecord",
      "kinesis:PutRecords"
    ]
    resources = ["arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/${var.name}"]
  }

  statement {
    sid    = "GetRecordFromKinesis"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = var.get_record_iam_roles
    }
    actions = [
      "kinesis:DescribeStreamSummary",
      "kinesis:ListShards",
      "kinesis:GetRecords",
      "kinesis:GetShardIterator"
    ]
    resources = ["arn:aws:kinesis:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:stream/${var.name}"]
  }
}


## KMS ##

resource "aws_kms_key" "this" {
  description             = "CMK for the Snowplow Kinesis Raw Stream"
  deletion_window_in_days = 10
  enable_key_rotation = true
  is_enabled = true
  policy = data.aws_iam_policy_document.kinesis_kms_policy.json

  tags = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.this.key_id
}

data "aws_iam_policy_document" "kinesis_kms_policy" {
  statement {
    sid = "DecryptKinesisKMSkey"
    effect   = "Allow"
    principals {
      type        = "AWS"
      identifiers = concat(var.get_record_iam_roles, var.put_record_iam_roles)
    }
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["*"]
  }

  statement {
    sid = "AdminAccessToKMS"
    effect   = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
    actions = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "kinesis_kms_access" {
  name        = "${var.name}-kms-access"
  path        = "/"
  description = "This Policy gives KMS access to Kinesis"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "DecryptKMSkeyForKinesis"
        Effect   = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.this.arn
      }
    ]
  })

  tags = var.tags
}

## ALARMS ##

resource "aws_cloudwatch_metric_alarm" "GetRecordsIteratorAgeMilliseconds" {
  alarm_name          = "${var.name}-get-records-iterator-age-milliseconds"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 15
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Maximum"
  threshold           = 60
  datapoints_to_alarm = 10
  alarm_description   = "This alarm is used to detect if data in your stream is going to expire because of being preserved too long or because record processing is too slow. It helps you avoid data loss after reaching 100% of the stream retention time."
  alarm_actions       = [var.alarm_action]
  treat_missing_data  = "notBreaching"

  dimensions = {
    StreamName = var.name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "GetRecordsSuccess" {
  alarm_name          = "${var.name}-get-records-success"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 5
  metric_name         = "GetRecords.Success"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Average"
  threshold           = 99/100
  datapoints_to_alarm = 5
  alarm_description   = "This alarm can detect if the retrieval of records from the stream by consumers is failing. By setting an alarm on this metric, you can proactively detect any issues with data consumption, such as increased error rates or a decline in successful retrievals."
  alarm_actions       = [var.alarm_action]
  treat_missing_data  = "notBreaching"

  dimensions = {
    StreamName = var.name
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "PutRecordSuccess" {
  alarm_name          = "${var.name}-put-record-success"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 15
  threshold           = 99
  datapoints_to_alarm = 10
  alarm_description   = "This alarm can detect if ingestion of records into the stream is failing. It helps you identify issues in writing data to the stream. By setting an alarm on this metric, you can proactively detect any issues of producers in publishing data to the stream, such as increased error rates or a decrease in successful records being published."
  alarm_actions       = [var.alarm_action]
  treat_missing_data  = "notBreaching"


  metric_query {
    id          = "totalRecords"
    return_data = false

    metric {
      dimensions = {
        "StreamName" = aws_kinesis_stream.this.name
      }
      namespace   = "AWS/Kinesis"
      metric_name = "PutRecords.TotalRecords"
      period      = 60
      stat        = "Sum"
    }
  }

  metric_query {
    id          = "successfulRecods"
    return_data = false

    metric {
      dimensions = {
        "StreamName" = aws_kinesis_stream.this.name
      }
      namespace   = "AWS/Kinesis"
      metric_name = "PutRecords.SuccessfulRecords"
      period      = 60
      stat        = "Sum"
    }
  }

  metric_query {
    expression  = "(successfulRecods / totalRecords) * 100"
    id          = "successRate"
    label       = "successRate"
    return_data = true
  }

  tags = var.tags
}