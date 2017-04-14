#!/bin/bash

# Disable IPv6
echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
echo "net.ipv6.conf.lo.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Firewall
sudo sed -i -e 's/IPV6=yes/IPV6=no/' /etc/default/ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# SSH disable password authentication (make sure you configured authorized keys)
test -f ~/.ssh/authorized_keys && sudo sed -i -e 's/.*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config && sudo service restart ssh

# Upgrade system
sudo apt update
sudo apt list --upgradable
sudo apt upgrade -y

# Install tools
sudo apt install git screen vim curl software-properties-common -y
wget https://github.com/xenolf/lego/releases/download/v0.3.1/lego_linux_amd64.tar.xz && tar xf lego_linux_amd64.tar.xz && chmod +x lego/lego && sudo mv lego/lego /usr/local/bin/lego && rm -rf lego && rm -f lego_linux_amd64.tar.xz
echo "hardstatus alwayslastline" | sudo tee -a /etc/screenrc
echo "hardstatus string '%{= kG}[ %{G}%H %{g}][%= %{=kw}%?%-Lw%?%{r}(%{W}%n*%f%t%?(%u)%?%{r})%{w}%?%+Lw%?%?%= %{g}][%{B}%Y-%m-%d %{W}%c %{g}]'" | sudo tee -a /etc/screenrc

# NGINX
sudo apt install nginx -y
sudo sed -i "s/worker_processes .*;/worker_processes auto;/" /etc/nginx/nginx.conf
sudo sed -i "s/# multi_accept on;/multi_accept on;/" /etc/nginx/nginx.conf
sudo sed -i "s/# gzip_/gzip_/" /etc/nginx/nginx.conf

# Set up cronjob to restart NGINX if /tmp/nginx.reload exists (after renewing Lets Encrypt)
echo "0 * * * * root [ -f /tmp/nginx.reload ] && /bin/systemctl reload nginx.service && rm -f /tmp/nginx.reload" | sudo tee /etc/cron.d/reload_nginx

# MariaDB 10.1
sudo apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
sudo add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://download.nus.edu.sg/mirror/mariadb/repo/10.1/ubuntu xenial main'
sudo apt update
export DEBIAN_FRONTEND=noninteractive
debconf-set-selections <<< 'mariadb-server-10.1 mysql-server/root_password password passwd'
debconf-set-selections <<< 'mariadb-server-10.1 mysql-server/root_password_again password passwd'
sudo apt install mariadb-server mariadb-client -y
sudo service mysql start

# PHP 7.1 (via PPA)
sudo add-apt-repository ppa:ondrej/php -y
sudo apt update
sudo apt install -y php7.1-bz2 php7.1-cli php7.1-common php7.1-curl php7.1-fpm php7.1-gd php7.1-intl php7.1-json php7.1-mbstring php7.1-mcrypt php7.1-mysql php7.1-opcache php7.1-readline php7.1-xml php7.1-xmlrpc php7.1-xsl php7.1-zip
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
curl https://getcomposer.org/installer > composer-setup.php && php composer-setup.php && sudo mv composer.phar /usr/local/bin/composer && rm composer-setup.php
sudo composer global require "hirak/prestissimo:^0.3"

# DONE
echo "BAMMMMM ! It's done !"

