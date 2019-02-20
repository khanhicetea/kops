#!/bin/bash

if [ -z "$3" ]
then
    echo "Please try again with full arguments : [username] [domain] [email for letencrypt] [webroot?]"
    exit 1
fi

USERNAME="$1"
DOMAIN="$2"
LE_EMAIL="$3"
DOC_ROOT=${4:-public}

if [ ! -d "/home/$USERNAME" ]; then
    ./create_user.sh $USERNAME
fi

sudo mkdir /home/$USERNAME/$DOMAIN
sudo chown -R $USERNAME:www-data /home/$USERNAME/$DOMAIN

sudo tee -a /etc/caddy/Caddyfile <<EOF
${DOMAIN}:80,
www.${DOMAIN}:80 {
        tls off
        redir 301 {
                /  https://${DOMAIN}{uri}
        }
}

${DOMAIN}:443 {
        gzip
        timeouts 1m
        tls ${LE_EMAIL}
        root ${DOC_ROOT}
        log stdout
        fastcgi / /run/php/php7.3-fpm.${USERNAME}.sock php
        rewrite {
                to {path} {path}/ /index.php?{query}
        }
}
EOF
sudo systemctl reload caddy.service

if [ $# -eq 5 ]
then
    DB="$5"
    DB_NAME=${USERNAME}_${DB}
    mysql -e "CREATE SCHEMA \`$DB_NAME\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
fi

# Done
echo -e "\nDone ! Enjoy it !"
