#!/bin/bash

if [ -z "$3" ]
then
    echo "Please try again with full arguments : [username] [domain] [webroot?]"
    exit 1
fi

USERNAME="$1"
DOMAIN="$2"
DOC_ROOT=${3:-public}

if [ ! -d "/home/$USERNAME" ]; then
    ./create_user.sh $USERNAME
fi

sudo mkdir /home/$USERNAME/$DOMAIN
sudo chown -R $USERNAME:nginx /home/$USERNAME/$DOMAIN

cat >/tmp/new_nginx_site.conf <<EOF
server {
        listen 80;
        server_name ${DOMAIN};

        root /home/${USERNAME}/${DOMAIN}/${DOC_ROOT};
        index index.php index.html index.htm;
        
        location ~* ^.+\\.(?:css|cur|js|jpe?g|gif|htc|ico|png|xml|otf|ttf|eot|woff|svg)\$ {
                try_files \$uri =404;
                access_log off;
                expires 30d;
        }

        location ~* \\.(eot|ttf|woff)\$ {
                add_header Access-Control-Allow-Origin '*';
        }

        location / {
                try_files \$uri /index.php\$is_args\$args;
        }

        location ~ \\.php\$ {
                include fastcgi_snippets;
                fastcgi_pass unix:/run/php/php7.3-fpm.${USERNAME}.sock;
                fastcgi_read_timeout 60;
        }
        
        location ~ /\\.  {
            deny all;
        }
}
EOF
sudo mv /tmp/new_nginx_site.conf /etc/nginx/conf.d/$DOMAIN.conf
sudo systemctl reload nginx.service

if [ $# -eq 4 ]
then
    DB="$4"
    DB_NAME=${USERNAME}_${DB}
    mysql -e "CREATE SCHEMA \`$DB_NAME\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
fi

# Done
echo -e "\nDone ! Enjoy it !"
