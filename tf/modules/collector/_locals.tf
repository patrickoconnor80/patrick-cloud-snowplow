locals {
    region     = data.aws_region.current.name
    account_id = data.aws_caller_identity.current.account_id

    tags = merge(
        var.tags,
        {
            Name           = "${var.prefix}-snowplow-collector-ec2"
            app_name       = "stream-collector"
            app_version    = "2.9.2"
            module_name    = "collector-kinesis-ec2"
            module_version = "0.8.1"
        }
    )

    collector_hocon = templatefile("../cfg/collector/config.hocon", {
        sink_type            = "kinesis"
        port                 = 8080
        good_stream_name     = var.good_stream_name
        bad_stream_name      = var.bad_stream_name
        region               = data.aws_region.current.name

        byte_limit    = 1000000
        record_limit  = 500
        time_limit_ms = 500
    })

    user_data = templatefile("../cfg/collector/user-data.sh", {
        sink_type  = "kinesis"
        port       = 8080
        config_b64 = base64encode(local.collector_hocon)
        version    = "2.9.2"

        cloudwatch_logs_enabled   = true
        cloudwatch_log_group_name = aws_cloudwatch_log_group.this.name

        java_opts        = "-Dcom.amazonaws.sdk.disableCbor -XX:InitialRAMPercentage=75 -XX:MaxRAMPercentage=75"

        nginx-config = file("../cfg/collector/nginx.conf")
        index-html = file("../cfg/collector/index.html")
    })
}