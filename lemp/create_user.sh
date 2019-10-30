#!/bin/bash

set -e

USERNAME="$1"

# Create linux user
sudo useradd -m -N -g www-data $USERNAME
sudo chsh -s /bin/bash $USERNAME
echo "umask 027" | sudo tee -a /home/$USERNAME/.bashrc

mkdir /home/$USERNAME/logs
chmod 775 /home/$USERNAME/logs

# Jobber
sudo systemctl restart jobber
sudo runuser -l $USERNAME -c 'jobber init'
cat >/tmp/user_jobber <<EOF
version: 1.4

prefs:
    logPath: logs/jobber.main.log
    runLog:
        type: file
        path: /home/${USERNAME}/logs/jobber.run.log
        maxFileLen: 50m
        maxHistories: 2

jobs:
EOF
sudo mv /tmp/user_jobber /home/$USERNAME/.jobber
sudo chown -R $USERNAME:www-data /home/$USERNAME/.jobber
sudo chmod 600 /home/$USERNAME/.jobber
sudo runuser -l $USERNAME -c 'jobber reload'

# Composer install plugins
sudo runuser -l $USERNAME -c 'composer global require "hirak/prestissimo:^0.3"'

# Create user php-fpm pool
cat >/tmp/new_phpfpm_pool.conf <<EOF
[${USERNAME}]
user = ${USERNAME}
group = www-data
listen.owner = www-data
listen.group = www-data
listen = /run/php/php7.3-fpm.${USERNAME}.sock

pm = dynamic
pm.max_children = 10
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.process_idle_timeout = 30s
pm.max_requests = 1024
request_terminate_timeout = 120s

php_flag[display_errors] = off
php_admin_value[error_log] = /home/${USERNAME}/logs/fpm-php.error.log
php_admin_flag[log_errors] = on
EOF

sudo mv /tmp/new_phpfpm_pool.conf /etc/php/7.3/fpm/pool.d/$USERNAME.conf
sudo rm -f /etc/php/7.3/fpm/pool.d/www.conf

# Reload php-fpm service
sudo systemctl reload php7.3-fpm.service

# Create MySQL user
RANDOM_PASS=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16 ; echo ''`
mysql -e "CREATE USER '$1'@'%' IDENTIFIED BY '$RANDOM_PASS'; GRANT ALL PRIVILEGES ON \`$1\\_%\`.* TO '$1'@'%'; FLUSH PRIVILEGES"
echo "MySQL user password is $RANDOM_PASS"

# Done
echo "Done !"
