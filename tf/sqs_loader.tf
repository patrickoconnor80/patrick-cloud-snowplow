resource "aws_sqs_queue" "this" {
  name                        = local.sqs_queue_name
  kms_master_key_id           = aws_kms_key.sqs.arn
  policy                      = data.aws_iam_policy_document.sqs_access_policy.json
  content_based_deduplication = true
  fifo_queue                  = true
}


## IAM ACCESS POLICY ##

data "aws_iam_policy_document" "sqs_access_policy" {

  statement {
    sid    = "SendMessageToSQS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-transformer-server-wrp"]
    }
    actions   = ["sqs:SendMessage"]
    resources = ["arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.sqs_queue_name}"]
  }

  statement {
    sid    = "ReadMessageFromSQS"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.prefix}-snowplow-db-loader-server"]
    }
    actions = [
      "sqs:GetQueueAttributes",
      "sqs:GetQueueUrl",
      "sqs:ListQueues",
      "sqs:UntagQueue",
      "sqs:TagQueue",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
    ]
    resources = ["arn:aws:sqs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${local.sqs_queue_name}"]
  }
}

## KMS ## 

resource "aws_kms_key" "sqs" {
  description             = "CMK for the Snowplow SQS"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  is_enabled              = true

  policy = data.aws_iam_policy_document.sqs_kms_policy.json

  tags = local.tags
}

resource "aws_kms_alias" "sqs" {
  name          = "alias/${local.prefix}-snowplow-sqs"
  target_key_id = aws_kms_key.sqs.key_id
}

data "aws_iam_policy_document" "sqs_kms_policy" {
  statement {
    sid    = "DecryptSQSKMS"
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
    actions   = ["kms:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sqs_kms_access" {
  name        = "${local.prefix}-snowplow-sqs-kms-access"
  path        = "/"
  description = "This Policy give kms key access to SQS: ${local.sqs_queue_name}"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DecryptSQSKMS"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = aws_kms_key.sqs.arn
      }
    ]
  })

  tags = local.tags
}


## ALARMS ##

resource "aws_cloudwatch_metric_alarm" "ApproximateAgeOfOldestMessage" {
  alarm_name          = "${local.prefix}-snowplow-sqs-approximate-age-of-oldest-message-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 15
  metric_name         = "ApproximateAgeOfOldestMessage"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Maximum"
  threshold           = 300
  datapoints_to_alarm = 15
  alarm_description   = "This alarm watches the age of the oldest message in the queue."
  alarm_actions       = [data.aws_sns_topic.email.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.this.name
  }

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "ApproximateNumberOfMessagesNotVisible" {
  alarm_name          = "${local.prefix}-snowplow-sqs-approximate-number-of-messages-not-visible-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 15
  metric_name         = "ApproximateNumberOfMessagesNotVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Average"
  threshold           = 15
  datapoints_to_alarm = 15
  alarm_description   = "This alarm helps to detect a high number of in-flight messages with respect to ${local.sqs_queue_name}"
  alarm_actions       = [data.aws_sns_topic.email.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.this.name
  }

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "ApproximateNumberOfMessagesVisible" {
  alarm_name          = "${local.prefix}-snowplow-sqs-approximate-number-of-messages-visible-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 15
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Average"
  threshold           = 15
  datapoints_to_alarm = 15
  alarm_description   = "This alarm helps to detect a high number of in-flight messages with respect to ${local.sqs_queue_name}"
  alarm_actions       = [data.aws_sns_topic.email.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.this.name
  }

  tags = local.tags
}

resource "aws_cloudwatch_metric_alarm" "NumberOfMessagesSent" {
  alarm_name          = "${local.prefix}-snowplow-sqs-nubmer-of-messages-sent-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 15
  metric_name         = "NumberOfMessagesSent"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  datapoints_to_alarm = 15
  alarm_description   = "This alarm helps to detect if there are no messages being sent from a producer with respect to ${local.sqs_queue_name}."
  alarm_actions       = [data.aws_sns_topic.email.arn]
  treat_missing_data  = "notBreaching"

  dimensions = {
    QueueName = aws_sqs_queue.this.name
  }

  tags = local.tags
}