#!/bin/bash
# HOSTS IP >
LB_HOST=$1
WEB_HOST1=$2
WEB_HOST2=$3
# <
sudo yum -y update 
sudo yum -y install epel-release

# Install Nginx-balancer >
sudo yum -y install nginx
sudo systemctl start nginx
sudo systemctl enable nginx
# <
# recreate & configure parameter-file >
sudo rm /etc/nginx/nginx.conf
sudo cat <<EOF | sudo tee -a /etc/nginx/nginx.conf
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;
# Load dynamic modules. See /usr/share/nginx/README.dynamic.
include /usr/share/nginx/modules/*.conf;
events {
    worker_connections 1024;
}
http {
upstream ${LB_HOST}  {
  least_conn;
  server ${WEB_HOST1};
  server ${WEB_HOST2};
}
    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;
    sendfile            on;
    tcp_nopush          on;
    tcp_nodelay         on;
    keepalive_timeout   65;
    types_hash_max_size 2048;
    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    include /etc/nginx/conf.d/*.conf;
    server {
        listen       80 default_server;
        server_name  ${LB_HOST};
        root         /usr/share/nginx/html;
        # Load configuration files for the default server block.
        include /etc/nginx/default.d/*.conf;
        location / {
        proxy_pass  http://$LB_HOST;
        }
        error_page 404 /404.html;
            location = /40x.html {
        }
        error_page 500 502 503 504 /50x.html;
            location = /50x.html {
        }
    }
}
EOF
# <

sudo nginx -t
sudo systemctl restart nginx
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --add-service=ssh
sudo firewall-cmd --permanent --zone=public --add-service=http 
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload