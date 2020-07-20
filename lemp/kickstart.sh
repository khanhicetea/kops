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

# SSH disable password authentication (make sure you configured authorized keys)
test -f ~/.ssh/authorized_keys && sudo sed -i -e 's/.*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config && sudo systemctl restart ssh

# Upgrade system
sudo add-apt-repository universe
sudo apt update
sudo apt list --upgradable
sudo apt upgrade -y

# Install tools
sudo apt install ufw wget git screen vim curl zip unzip software-properties-common gnupg -y
wget https://github.com/xenolf/lego/releases/download/v3.5.0/lego_v3.5.0_linux_amd64.tar.gz && mkdir lego_linux && tar xf lego_v3.5.0_linux_amd64.tar.gz -C lego_linux && chmod +x lego_linux/lego && sudo mv lego_linux/lego /usr/local/bin/lego && rm -f lego_v3.5.0_linux_amd64.tar.gz && rm -rf lego_linux
echo "hardstatus alwayslastline" | sudo tee -a /etc/screenrc
echo "hardstatus string '%{= kG}[ %{G}%H %{g}][%= %{=kw}%?%-Lw%?%{r}(%{W}%n*%f%t%?(%u)%?%{r})%{w}%?%+Lw%?%?%= %{g}][%{B}%Y-%m-%d %{W}%c %{g}]'" | sudo tee -a /etc/screenrc

# Firewall
sudo sed -i -e 's/IPV6=yes/IPV6=no/' /etc/default/ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw limit OpenSSH
sudo ufw --force enable

# Install Jobber
wget https://github.com/dshearer/jobber/releases/download/v1.4.0/jobber_1.4.0-1_amd64.deb && sudo dpkg -i jobber_1.4.0-1_amd64.deb && rm -f jobber_1.4.0-1_amd64.deb
sudo systemctl enable jobber.service
jobber init
cat >~/.jobber <<EOF
version: 1.4

prefs:
    logPath: jobber-log
    runLog:
        type: file
        path: /tmp/jobber-root.run.log
        maxFileLen: 50m
        maxHistories: 2

jobs:
    RenewCerts:
        cmd: ~/kops/scripts/renew_certs.sh
        time: '0 0 0 * * *'
        onError: Continue
EOF
jobber reload

# NGINX (mainline branch)
sudo apt install nginx -y

cat >/tmp/nginx_conf <<EOF
user www-data;
worker_processes auto;
error_log  /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;

events {
    worker_connections 1024;
    use epoll;
    multi_accept on;
}

http {
    include /etc/nginx/mime.types;
    include /etc/nginx/conf.d/*.conf;
}
EOF
sudo mv /tmp/nginx_conf /etc/nginx/nginx.conf

cat >/tmp/nginx_conf_0 <<EOF
default_type application/octet-stream;

log_format   main '$remote_addr - $remote_user [$time_local]  $status '
    '"$request" $body_bytes_sent "$http_referer" '
    '"$http_user_agent" "$http_x_forwarded_for"';
access_log  /var/log/nginx/access.log main;

keepalive_timeout 120;
keepalive_requests 1024;
sendfile on;
tcp_nopush on;
tcp_nodelay on;

reset_timedout_connection on;
client_body_buffer_size 128k;
client_max_body_size 10m;
client_header_buffer_size 8k;
large_client_header_buffers 4 4k;
output_buffers 4 64k;
postpone_output 1460;
client_header_timeout 3m;
client_body_timeout 3m;
send_timeout 3m;

types_hash_max_size 2048;
server_tokens off;

gzip on;
gzip_disable "msie6";
gzip_min_length 1000;
gzip_vary on;
gzip_proxied any;
gzip_comp_level 1;
gzip_buffers 16 8k;
gzip_http_version 1.1;
gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript application/javascript;
EOF
sudo mv /tmp/nginx_conf_0 /etc/nginx/conf.d/00-nginx.conf
cat >/tmp/nginx_fastcgi_snipets <<EOF
fastcgi_split_path_info ^(.+\\.php)(/.+)$;
try_files \$fastcgi_script_name =404;

set \$path_info \$fastcgi_path_info;
fastcgi_param PATH_INFO \$path_info;
fastcgi_param HTTP_PROXY "";

fastcgi_index index.php;
fastcgi_read_timeout 60;
fastcgi_buffering on;
fastcgi_buffer_size 64k;
fastcgi_buffers 8 64k;

include fastcgi.conf;
EOF
sudo mv /tmp/nginx_fastcgi_snipets /etc/nginx/fastcgi_snippets

openssl rand 2048 > ~/.rnd
sudo mkdir /etc/nginx/ssl
sudo mkdir /etc/nginx/certs
sudo mkdir /usr/share/nginx/acme-challenge
echo "nginx   soft    nofile  10000" | sudo tee -a /etc/security/limits.conf
echo "nginx   hard    nofile  30000" | sudo tee -a /etc/security/limits.conf
sudo openssl dhparam -dsaparam -out /etc/nginx/certs/dhparam.pem 2048
sudo systemctl enable nginx.service
sudo systemctl restart nginx.service

# MySQL 8
export DEBIAN_FRONTEND=noninteractive
wget https://dev.mysql.com/get/mysql-apt-config_0.8.15-1_all.deb
sudo dpkg -i mysql-apt-config_0.8.15-1_all.deb
sudo apt update

sudo apt install mysql-server mysql-client -y
sudo systemctl enable mysql.service
sudo systemctl restart mysql.service
echo -e "[client]\nuser=root\npassword=passwd" > ~/.my.cnf
chmod 600 ~/.my.cnf

# Redis server
sudo apt install redis-server -y
sudo systemctl enable redis-server.service
sudo systemctl restart redis-server.service

# Node 10
curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt install -y nodejs
sudo npm install -g yarn
sudo npm install -g pm2

# PHP 7.4 (via PPA)
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install -y php7.4-bz2 php7.4-cli php7.4-common php7.4-curl php7.4-fpm php7.4-gd php7.4-intl php7.4-json php7.4-mbstring php7.4-mysql php7.4-opcache php7.4-readline php7.4-xml php7.4-xmlrpc php7.4-xsl php7.4-zip php-redis
sudo sed -i "s/;date.timezone =.*/date.timezone = Asia\/Ho_Chi_Minh/" /etc/php/7.4/cli/php.ini
sudo sed -i "s/;date.timezone =.*/date.timezone = Asia\/Ho_Chi_Minh/" /etc/php/7.4/fpm/php.ini
sudo sed -i "s/; max_input_vars =.*/max_input_vars = 10000/" /etc/php/7.4/fpm/php.ini
sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 10M/" /etc/php/7.4/fpm/php.ini
sudo sed -i "s/post_max_size = .*/post_max_size = 12M/" /etc/php/7.4/fpm/php.ini
sudo sed -i "s/max_execution_time = .*/max_execution_time = 60/" /etc/php/7.4/fpm/php.ini
sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.4/fpm/php.ini
sudo sed -i "s/;opcache.enable=.*/opcache.enable=1/" /etc/php/7.4/fpm/php.ini
sudo sed -i "s/;opcache.use_cwd=.*/opcache.use_cwd=1/" /etc/php/7.4/fpm/php.ini
sudo sed -i "s/;opcache.validate_timestamps=.*/opcache.validate_timestamps=1/" /etc/php/7.4/fpm/php.ini
sudo sed -i "s/;opcache.revalidate_freq=.*/;opcache.revalidate_freq=20/" /etc/php/7.4/fpm/php.ini
sudo systemctl enable php7.4-fpm.service
sudo systemctl restart php7.4-fpm.service

sudo chown -R $USER:$USER ~/.config
curl https://getcomposer.org/installer > composer-setup.php && php composer-setup.php && sudo mv composer.phar /usr/local/bin/composer && sudo chmod +x /usr/local/bin/composer && rm composer-setup.php

rm -rf /tmp/lemp

# DONE
echo "BAMMMMM ! It's done ! Remind to change MySQL root password !"
sudo mysql_secure_installation
