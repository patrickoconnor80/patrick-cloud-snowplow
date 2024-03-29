locals {

    tags = merge(
        var.tags,
        {
            Name           = "${var.prefix}-snowplow-iglu-ec2"
            app_name       = "iglu-server"
            app_version    = "0.10.0"
            module_name    = "iglu-server-ec2"
            module_version =  "0.4.4"
        }
    )

    iglu_server_hocon = templatefile("../cfg/iglu/config.hocon", {
        port            = 8080
        db_host         = var.db_host
        db_port         = var.db_port
        db_name         = var.db_name
        db_username     = var.db_username
        db_password     = var.db_password
        patches_allowed = true
        super_api_key   = lower(var.super_api_key)
    })

    user_data = templatefile("../cfg/iglu/user-data.sh", {
        port        = 8080
        config      = local.iglu_server_hocon
        version     = "0.10.0"
        db_host     = var.db_host
        db_port     = var.db_port
        db_name     = var.db_name
        db_username = var.db_username
        db_password = var.db_password

        cloudwatch_logs_enabled   = true
        cloudwatch_log_group_name = aws_cloudwatch_log_group.this.name

        java_opts        = "-Dorg.slf4j.simpleLogger.defaultLogLevel=info -XX:MinRAMPercentage=50 -XX:MaxRAMPercentage=75"

        nginx-config = file("../cfg/iglu/nginx.conf")
        index-html = file("../cfg/iglu/index.html")
    })
}