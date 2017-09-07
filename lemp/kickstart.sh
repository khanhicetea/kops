#!/bin/bash

# To temp dir
sudo mkdir /tmp/lemp
cd /tmp/lemp

# Timezone
sudo timedatectl set-timezone Asia/Ho_Chi_Minh
sudo timedatectl set-ntp on

# Harden linux
echo "kernel.randomize_va_space = 1" | sudo tee -a /etc/sysctl.conf
echo "net.core.somaxconn = 65536" | sudo tee -a /etc/sysctl.conf

echo "net.ipv4.conf.all.rp_filter = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.conf.all.accept_source_route = 0" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.icmp_echo_ignore_broadcasts = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_timestamps = 0" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_syncookies = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog = 2048" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_synack_retries = 3" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_max_tw_buckets = 1440000" | sudo tee -a /etc/sysctl.conf

echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf

echo "fs.file-max = 65536" | sudo tee -a /etc/sysctl.conf

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
test -f ~/.ssh/authorized_keys && sudo sed -i -e 's/.*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config && sudo service ssh restart

# Remove unused packages
sudo apt --yes purge nfs-kernel-server nfs-common portmap rpcbind autofs
sudo apt --yes purge whoopsie

# Upgrade system
sudo apt update
sudo apt list --upgradable
sudo apt upgrade -y

# Install tools
sudo apt install git screen vim curl software-properties-common -y
wget https://github.com/xenolf/lego/releases/download/v0.4.0/lego_linux_amd64.tar.xz && tar xf lego_linux_amd64.tar.xz && chmod +x lego/lego && sudo mv lego/lego /usr/local/bin/lego && rm -rf lego && rm -f lego_linux_amd64.tar.xz
echo "hardstatus alwayslastline" | sudo tee -a /etc/screenrc
echo "hardstatus string '%{= kG}[ %{G}%H %{g}][%= %{=kw}%?%-Lw%?%{r}(%{W}%n*%f%t%?(%u)%?%{r})%{w}%?%+Lw%?%?%= %{g}][%{B}%Y-%m-%d %{W}%c %{g}]'" | sudo tee -a /etc/screenrc

# NGINX (mainline branch)
echo "deb http://nginx.org/packages/mainline/ubuntu/ xenial nginx" | sudo tee -a /etc/apt/sources.list
echo "deb-src http://nginx.org/packages/mainline/ubuntu/ xenial nginx" | sudo tee -a /etc/apt/sources.list
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

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

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

    include /etc/nginx/conf.d/*.conf;
}
EOF
sudo mv /tmp/nginx_conf /etc/nginx/nginx.conf

cat >/tmp/nginx_conf <<EOF
tcp_nopush on;
tcp_nodelay on;
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
gzip_types text/plain text/css application/json application/x-javascript text/xml application/xml application/xml+rss text/javascript;
EOF
sudo mv /tmp/nginx_conf /etc/nginx/conf.d/nginx.conf
cat >/tmp/nginx_fastcgi_snipets <<EOF
fastcgi_split_path_info ^(.+\\.php)(/.+)$;
try_files \$fastcgi_script_name =404;

set \$path_info \$fastcgi_path_info;
fastcgi_param PATH_INFO \$path_info;
fastcgi_param HTTP_PROXY "";

fastcgi_index index.php;
include fastcgi_params;
EOF
sudo mv /tmp/nginx_fastcgi_snipets /etc/nginx/fastcgi_snippets
sudo sed -i 's/fastcgi_param  SCRIPT_NAME.*/fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;/' /etc/nginx/fastcgi_params
sudo mkdir /var/lego
sudo mkdir /etc/nginx/ssl
sudo mkdir /etc/nginx/certs
sudo mkdir /usr/share/nginx/acme-challenge
echo "nginx   soft    nofile  10000" | sudo tee -a /etc/security/limits.conf
echo "nginx   hard    nofile  30000" | sudo tee -a /etc/security/limits.conf
sudo openssl dhparam -out /etc/nginx/certs/dhparam.pem 4096
sudo systemctl enable nginx.service
sudo systemctl restart nginx.service

# MySQL 5.7
export DEBIAN_FRONTEND=noninteractive
echo "mysql-server-5.7 mysql-server/root_password password passwd" | sudo debconf-set-selections
echo "mysql-server-5.7 mysql-server/root_password_again password passwd" | sudo debconf-set-selections
sudo apt install mysql-server -y
sudo systemctl enable mysql.service
sudo systemctl restart mysql.service

# Redis server
sudo add-apt-repository ppa:chris-lea/redis-server -y
sudo apt update
sudo apt install redis-server -y
sudo systemctl enable redis-server.service
sudo systemctl restart redis-server.service

# PHP 7.1 (via PPA)
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install -y php7.1-bz2 php7.1-cli php7.1-common php7.1-curl php7.1-fpm php7.1-gd php7.1-intl php7.1-json php7.1-mbstring php7.1-mcrypt php7.1-mysql php7.1-opcache php7.1-readline php7.1-xml php7.1-xmlrpc php7.1-xsl php7.1-zip php-redis
sudo sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.1/cli/php.ini
sudo sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.1/fpm/php.ini
sudo sed -i "s/; max_input_vars =.*/max_input_vars = 5000/" /etc/php/7.1/fpm/php.ini
sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 10M/" /etc/php/7.1/fpm/php.ini
sudo sed -i "s/post_max_size = .*/post_max_size = 12M/" /etc/php/7.1/fpm/php.ini
sudo sed -i "s/max_execution_time = .*/max_execution_time = 60/" /etc/php/7.1/fpm/php.ini
sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.1/fpm/php.ini
sudo sed -i "s/;opcache.enable=.*/opcache.enable=1/" /etc/php/7.1/fpm/php.ini
sudo sed -i "s/;opcache.use_cwd=.*/opcache.use_cwd=1/" /etc/php/7.1/fpm/php.ini
sudo sed -i "s/;opcache.validate_timestamps=.*/opcache.validate_timestamps=1/" /etc/php/7.1/fpm/php.ini
sudo sed -i "s/;opcache.revalidate_freq=.*/;opcache.revalidate_freq=10/" /etc/php/7.1/fpm/php.ini
sudo systemctl enable php7.1-fpm.service
sudo systemctl restart php7.1-fpm.service
curl https://getcomposer.org/installer > composer-setup.php && php composer-setup.php && sudo mv composer.phar /usr/local/bin/composer && sudo chmod +x /usr/local/bin/composer && rm composer-setup.php

# DONE
echo "BAMMMMM ! It's done ! Remind to change MySQL root password !"
