
resource "aws_iam_instance_profile" "this" {
  name = "${var.prefix}-${var.name}-ec2-profile"
  role = data.aws_iam_role.snowplow_iglu.name
}

resource "aws_iam_policy" "this" {
  name = "${var.prefix}-${var.name}-policy"
  tags = var.tags
  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:PutLogEvents",
        "logs:CreateLogStream",
        "logs:DescribeLogStreams"
      ],
      "Resource": [
        "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.this.name}:*"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = data.aws_iam_role.snowplow_iglu.name
  policy_arn = aws_iam_policy.this.arn
}