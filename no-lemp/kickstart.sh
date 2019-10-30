#!/bin/bash

# To temp dir
mkdir /tmp/lemp
cd /tmp/lemp

# Timezone
sudo timedatectl set-timezone Asia/Ho_Chi_Minh
sudo timedatectl set-ntp on

# Harden linux
echo "kernel.randomize_va_space = 1" | sudo tee -a /etc/sysctl.conf
echo "kernel.sched_migration_cost_ns = 5000000" | sudo tee -a /etc/sysctl.conf
echo "kernel.sched_autogroup_enabled = 0" | sudo tee -a /etc/sysctl.conf

echo "net.core.rmem_max = 16777216" | sudo tee -a /etc/sysctl.conf
echo "net.core.wmem_max = 16777216" | sudo tee -a /etc/sysctl.conf
echo "net.core.somaxconn = 1024" | sudo tee -a /etc/sysctl.conf

echo "net.ipv4.ip_local_port_range = 1024 65535" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_tw_recycle = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_tw_reuse = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_source_route = 0" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_timestamps = 0" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 4096" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_synack_retries = 3" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_max_tw_buckets = 1440000" | sudo tee -a /etc/sysctl.conf

echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf

echo "fs.file-max = 100000" | sudo tee -a /etc/sysctl.conf

echo "vm.swappiness = 5" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_ratio = 60" | sudo tee -a /etc/sysctl.conf
echo "vm.dirty_background_ratio = 10" | sudo tee -a /etc/sysctl.conf

sudo sysctl -p

# Firewall
sudo sed -i -e 's/IPV6=yes/IPV6=no/' /etc/default/ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw limit OpenSSH
sudo ufw --force enable

# SSH disable password authentication (make sure you configured authorized keys)
test -f ~/.ssh/authorized_keys && sudo sed -i -e 's/.*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config && sudo systemctl restart ssh

# Upgrade system
sudo add-apt-repository universe
sudo apt update
sudo apt list --upgradable
sudo apt upgrade -y

# Install tools
sudo apt install git screen vim curl software-properties-common -y
wget https://github.com/xenolf/lego/releases/download/v3.1.0/lego_v3.1.0_linux_amd64.tar.gz && mkdir lego_linux && tar xf lego_v3.1.0_linux_amd64.tar.gz -C lego_linux && chmod +x lego_linux/lego && sudo mv lego_linux/lego /usr/local/bin/lego && rm -f lego_v3.1.0_linux_amd64.tar.gz && rm -rf lego_linux
echo "hardstatus alwayslastline" | sudo tee -a /etc/screenrc
echo "hardstatus string '%{= kG}[ %{G}%H %{g}][%= %{=kw}%?%-Lw%?%{r}(%{W}%n*%f%t%?(%u)%?%{r})%{w}%?%+Lw%?%?%= %{g}][%{B}%Y-%m-%d %{W}%c %{g}]'" | sudo tee -a /etc/screenrc

# NGINX (mainline branch)
echo "deb http://nginx.org/packages/mainline/ubuntu/ bionic nginx" | sudo tee -a /etc/apt/sources.list
echo "deb-src http://nginx.org/packages/mainline/ubuntu/ bionic nginx" | sudo tee -a /etc/apt/sources.list
wget -qO - https://nginx.org/keys/nginx_signing.key | sudo apt-key add -
sudo apt update
sudo apt install nginx -y

cat >/tmp/nginx_conf <<EOF
user  nginx;
worker_processes auto;
error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    include /etc/nginx/conf.d/*.conf;
}
EOF
sudo mv /tmp/nginx_conf /etc/nginx/nginx.conf

cat >/tmp/nginx_conf <<EOF
keepalive_timeout 65;
keepalive_requests 100000;
sendfile on;
tcp_nopush on;
tcp_nodelay on;

reset_timedout_connection on;
client_body_buffer_size 128k;
client_max_body_size         10m;
client_header_buffer_size    1k;
large_client_header_buffers  4 4k;
output_buffers               4 64k;
postpone_output              1460;
client_header_timeout  3m;
client_body_timeout    3m;
send_timeout           3m;

types_hash_max_size 2048;
server_tokens off;

gzip on;
gzip_disable "msie6";
gzip_min_length 1000;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 6;
gzip_buffers 16 8k;
gzip_http_version 1.1;
gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript;
EOF
sudo mv /tmp/nginx_conf /etc/nginx/conf.d/nginx.conf

sudo mkdir /var/lego
sudo mkdir /etc/nginx/ssl
sudo mkdir /etc/nginx/certs
sudo mkdir /usr/share/nginx/acme-challenge
echo "nginx   soft    nofile  10000" | sudo tee -a /etc/security/limits.conf
echo "nginx   hard    nofile  30000" | sudo tee -a /etc/security/limits.conf
sudo openssl dhparam -dsaparam -out /etc/nginx/certs/dhparam.pem 2048
sudo systemctl enable nginx.service
sudo systemctl restart nginx.service

rm -rf /tmp/lemp

# DONE
echo "BAMMMMM ! It's done !"
