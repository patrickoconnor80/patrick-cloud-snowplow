

resource "aws_iam_instance_profile" "this" {
  name ="${var.prefix}-${var.name}-ec2-profile"
  role = data.aws_iam_role.snowplow_collector.name
}


resource "aws_iam_policy" "this" {
  name = "${var.prefix}-${var.name}-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
        {
          Sid    = "WriteToOutputStream"
          Effect = "Allow",
          Action = [
            "kinesis:DescribeStream",
            "kinesis:DescribeStreamSummary",
            "kinesis:List*",
            "kinesis:Put*"
          ],
          Resource = [
            "arn:aws:kinesis:${local.region}:${local.account_id}:stream/${var.good_stream_name}",
            "arn:aws:kinesis:${local.region}:${local.account_id}:stream/${var.bad_stream_name}"
          ]
        },
        {
          Sid = "WriteToCloudwatch"
          Effect = "Allow",
          Action = [
            "logs:PutLogEvents",
            "logs:CreateLogStream",
            "logs:DescribeLogStreams"
          ],
          Resource = [
            "arn:aws:logs:${local.region}:${local.account_id}:log-group:${aws_cloudwatch_log_group.this.name}:*"
          ]
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = data.aws_iam_role.snowplow_collector.name
  policy_arn = aws_iam_policy.this.arn
}