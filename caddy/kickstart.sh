#!/bin/bash

# To temp dir
mkdir /tmp/lemp
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
sudo ufw limit OpenSSH
sudo ufw --force enable

# SSH disable password authentication (make sure you configured authorized keys)
test -f ~/.ssh/authorized_keys && sudo sed -i -e 's/.*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config && sudo service ssh restart

# Upgrade system
sudo add-apt-repository universe
sudo apt update
sudo apt list --upgradable
sudo apt upgrade -y

# Install tools
sudo apt install git screen vim curl software-properties-common -y
echo "hardstatus alwayslastline" | sudo tee -a /etc/screenrc
echo "hardstatus string '%{= kG}[ %{G}%H %{g}][%= %{=kw}%?%-Lw%?%{r}(%{W}%n*%f%t%?(%u)%?%{r})%{w}%?%+Lw%?%?%= %{g}][%{B}%Y-%m-%d %{W}%c %{g}]'" | sudo tee -a /etc/screenrc

# Caddy
curl https://getcaddy.com | bash -s personal hook.service,http.cache,http.cors,http.expires,http.geoip,http.git,http.ipfilter,http.locale,http.realip,tls.dns.cloudflare
sudo setcap 'cap_net_bind_service=+ep' /usr/local/bin/caddy

sudo groupadd -g 33 www-data
sudo useradd \
  -g www-data --no-user-group \
  --home-dir /var/www --no-create-home \
  --shell /usr/sbin/nologin \
  --system --uid 33 www-data

sudo mkdir /etc/caddy
sudo chown -R root:root /etc/caddy
sudo mkdir /etc/ssl/caddy
sudo chown -R root:www-data /etc/ssl/caddy
sudo chmod 0770 /etc/ssl/caddy

wget https://raw.githubusercontent.com/mholt/caddy/master/dist/init/linux-systemd/caddy.service
sudo cp caddy.service /etc/systemd/system/
sudo chown root:root /etc/systemd/system/caddy.service
sudo chmod 644 /etc/systemd/system/caddy.service
sudo systemctl daemon-reload

cat >/tmp/caddy_conf <<EOF
:80 {
    status 404 /
}
EOF
sudo mv /tmp/caddy_conf /etc/caddy/Caddyfile

echo "www-data   soft    nofile  10000" | sudo tee -a /etc/security/limits.conf
echo "www-data   hard    nofile  30000" | sudo tee -a /etc/security/limits.conf
sudo systemctl enable caddy.service
sudo systemctl restart caddy.service

# MySQL 5.7
export DEBIAN_FRONTEND=noninteractive
echo "mysql-server-5.7 mysql-server/root_password password passwd" | sudo debconf-set-selections
echo "mysql-server-5.7 mysql-server/root_password_again password passwd" | sudo debconf-set-selections
sudo apt install mysql-server -y
sudo systemctl enable mysql.service
sudo systemctl restart mysql.service
echo -e "[client]\nuser=root\npassword=passwd" > ~/.my.cnf

# Redis server
sudo add-apt-repository ppa:chris-lea/redis-server -y
sudo apt update
sudo apt install redis-server -y
sudo systemctl enable redis-server.service
sudo systemctl restart redis-server.service

# Node 10
curl -sL https://deb.nodesource.com/setup_10.x | sudo -E bash -
sudo apt install -y nodejs

# PHP 7.3 (via PPA)
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install -y php7.3-bz2 php7.3-cli php7.3-common php7.3-curl php7.3-fpm php7.3-gd php7.3-intl php7.3-json php7.3-mbstring php7.3-mysql php7.3-opcache php7.3-readline php7.3-xml php7.3-xmlrpc php7.3-xsl php7.3-zip php-redis
sudo sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.3/cli/php.ini
sudo sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php/7.3/fpm/php.ini
sudo sed -i "s/; max_input_vars =.*/max_input_vars = 5000/" /etc/php/7.3/fpm/php.ini
sudo sed -i "s/upload_max_filesize = .*/upload_max_filesize = 10M/" /etc/php/7.3/fpm/php.ini
sudo sed -i "s/post_max_size = .*/post_max_size = 12M/" /etc/php/7.3/fpm/php.ini
sudo sed -i "s/max_execution_time = .*/max_execution_time = 60/" /etc/php/7.3/fpm/php.ini
sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/7.3/fpm/php.ini
sudo sed -i "s/;opcache.enable=.*/opcache.enable=1/" /etc/php/7.3/fpm/php.ini
sudo sed -i "s/;opcache.use_cwd=.*/opcache.use_cwd=1/" /etc/php/7.3/fpm/php.ini
sudo sed -i "s/;opcache.validate_timestamps=.*/opcache.validate_timestamps=1/" /etc/php/7.3/fpm/php.ini
sudo sed -i "s/;opcache.revalidate_freq=.*/;opcache.revalidate_freq=10/" /etc/php/7.3/fpm/php.ini
sudo systemctl enable php7.3-fpm.service
sudo systemctl restart php7.3-fpm.service
curl https://getcomposer.org/installer > composer-setup.php && php composer-setup.php && sudo mv composer.phar /usr/local/bin/composer && sudo chmod +x /usr/local/bin/composer && rm composer-setup.php

rm -rf /tmp/lemp

# DONE
echo "BAMMMMM ! It's done ! Remind to change MySQL root password !"
