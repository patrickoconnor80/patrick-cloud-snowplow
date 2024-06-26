#!/bin/bash

readonly CONFIG_DIR=/opt/snowplow/config

sudo mkdir -p $${CONFIG_DIR}

sudo base64 --decode << EOF > $${CONFIG_DIR}/collector.hocon
${config_b64}
EOF

sudo docker run \
  -d \
  --name collector \
  --restart always \
  --network host \
%{ if cloudwatch_logs_enabled ~}
  --log-driver awslogs \
  --log-opt awslogs-group=${cloudwatch_log_group_name} \
  --log-opt awslogs-stream=$(get_instance_id) \
%{ else ~}
  --log-opt max-size=10m \
  --log-opt max-file=5 \
%{ endif ~}
  --mount type=bind,source=$${CONFIG_DIR},target=/snowplow/config \
  --env JDK_JAVA_OPTIONS='${java_opts}' \
  --env INSTANCE_ID=$(get_instance_id) \
  -p ${port}:${port} \
  snowplow/scala-stream-collector-${sink_type}:${version} \
  --config /snowplow/config/collector.hocon

# Install nginx
sudo amazon-linux-extras install nginx1 -y

## Create folders
mkdir -p /var/log/nginx/
mkdir -p /var/log/nginx/ssl/
mkdir -p /usr/share/nginx/html

sudo cat > /etc/nginx/nginx.conf <<EOF
${nginx-config}
EOF

sudo cat > /usr/share/nginx/html/index.html <<EOF
${index-html}
EOF

# Create self-signed certifcates
cd /home/ec2-user
mkdir .ssl
cd .ssl
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -sha256 -days 3650 -nodes -subj \
    "/C=US/ST=MA/L=Boston/O=patrick-cloud.com/OU=Self/CN=snowplow-collector.patrick-cloud.com"

sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl status nginx