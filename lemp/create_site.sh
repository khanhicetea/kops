#!/bin/bash

USERNAME="$1"
DOMAIN="$2"

if [ -d "/home/$USERNAME" ]
then
    sudo mkdir /home/$USERNAME/$DOMAIN
    sudo chown -R $USERNAME:www-data /home/$USERNAME/$DOMAIN
    cat >/tmp/new_nginx_site.conf <<EOF
server {
        listen 80;
        server_name ${DOMAIN};

        root /home/${USERNAME}/${DOMAIN}/public;
#        return         301 https://\$server_name\$request_uri;
}

#server {
#        listen 443 ssl http2;
#        server_name ${DOMAIN};
#        root /home/${USERNAME}/${DOMAIN}/public;
#        index index.html index.htm index.php;
#
#        ssl_certificate /home/${USERNAME}/lego/certificates/${DOMAIN}.crt;
#        ssl_certificate_key /home/${USERNAME}/lego/certificates/${DOMAIN}.key;
#        ssl_prefer_server_ciphers on;
#        ssl_ciphers EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
#        
#        location ~* ^.+\\.(?:css|cur|js|jpe?g|gif|htc|ico|png|html|xml|otf|ttf|eot|woff|svg)\$ {
#                try_files \$uri =404;
#                access_log off;
#                expires 30d;
#        }
#
#        location ~* \\.(eot|ttf|woff)\$ {
#                add_header Access-Control-Allow-Origin '*';
#        }
#
#        location / {
#                try_files \$uri /index.php\$is_args\$args;
#        }
#
#        location ~ \\.php\$ {
#                include snippets/fastcgi-php.conf;
#                fastcgi_pass unix:/run/php/php7.1-fpm.${USERNAME}.sock;
#                fastcgi_read_timeout 60;
#        }
#
#        location ~ /\\.ht {
#                deny all;
#        }
#    }
EOF
    sudo mv /tmp/new_nginx_site.conf /etc/nginx/sites-available/${DOMAIN}
else
    ./create_user.sh $USERNAME
    echo -e "\nPlease add ssh key to repository before re-running this !"
fi

