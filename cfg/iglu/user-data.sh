#!/bin/bash

readonly CONFIG_DIR=/opt/snowplow/config

sudo mkdir -p $${CONFIG_DIR}
sudo cat << EOF > $${CONFIG_DIR}/iglu-server.hocon
${config}
EOF

# Run the server setup
set +e
sudo docker run \
  --name iglu-server-setup \
  --network host \
%{ if cloudwatch_logs_enabled ~}
  --log-driver awslogs \
  --log-opt awslogs-group=${cloudwatch_log_group_name} \
  --log-opt awslogs-stream=$(get_instance_id) \
%{ endif ~}
  -v $${CONFIG_DIR}:/snowplow/config \
  -e 'JAVA_OPTS=${java_opts}' \
  snowplow/iglu-server:${version} \
  setup --config /snowplow/config/iglu-server.hocon
set -e

# Launch the server
sudo docker run \
  -d \
  --name iglu-server \
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
  -v $${CONFIG_DIR}:/snowplow/config \
  -p ${port}:${port} \
  -e 'JAVA_OPTS=${java_opts}' \
  snowplow/iglu-server:${version} \
  --config /snowplow/config/iglu-server.hocon

  # Install nginx
sudo amazon-linux-extras install nginx1 -y

## Create folders for logging
mkdir -p /var/log/nginx/
mkdir -p /var/log/nginx/ssl/
## And html files
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
    "/C=US/ST=MA/L=Boston/O=patrick-cloud.com/OU=Self/CN=snowplow-iglu.patrick-cloud.com"

sudo systemctl enable nginx
sudo systemctl start nginx
sudo systemctl status nginx