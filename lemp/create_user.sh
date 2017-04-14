#!/bin/bash

USERNAME="$1"

# Create linux user
sudo useradd -m -N -g www-data $USERNAME

# Create lego dir in user home
mkdir -p /home/$USERNAME/lego/acme-challenge && sudo chown -R $USERNAME:www-data /home/$USERNAME/lego

# Composer install plugins
sudo runuser -l $USERNAME -c 'composer global require "hirak/prestissimo:^0.3"'

# Create user php-fpm pool
cat >/tmp/new_phpfpm_pool.conf <<EOF
[${USERNAME}]
user = ${USERNAME}
group = www-data
listen = /run/php/php7.1-fpm.${USERNAME}.sock
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.process_idle_timeout = 30s
pm.max_requests = 1024
request_terminate_timeout = 300s
EOF

sudo mv /tmp/new_phpfpm_pool.conf /etc/php/7.1/fpm/pool.d/$USERNAME.conf
sudo rm -f /etc/php/7.1/fpm/pool.d/www.conf

# Reload php-fpm service
sudo systemctl reload php7.1-fpm.service

# Done
echo "Done !"
