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

if [ -d "/home/$USERNAME" ]
then
    sudo mkdir /home/$USERNAME/$DOMAIN
    sudo chown -R $USERNAME:www-data /home/$USERNAME/$DOMAIN
    sudo openssl req -new -x509 -nodes -days 3650 -newkey rsa:2048 -subj "/C=US/ST=Nil/L=Nil/O=Nil/CN=$DOMAIN" -keyout /etc/nginx/ssl/$DOMAIN.key -out /etc/nginx/ssl/$DOMAIN.crt
    cat >/tmp/new_nginx_site.conf <<EOF
server {
        listen 80;
        server_name ${DOMAIN};

        location ^~ /.well-known/acme-challenge/ {
            alias /home/${USERNAME}/lego/acme-challenge/;
        }

        return 301 https://\$server_name\$request_uri;
}

server {
        listen 443 ssl http2;
        server_name ${DOMAIN};
        root /home/${USERNAME}/${DOMAIN}/${DOC_ROOT};
        index index.html index.htm index.php;

        ssl_certificate /etc/nginx/ssl/${DOMAIN}.crt;
        ssl_certificate_key /etc/nginx/ssl/${DOMAIN}.key;
        ssl_prefer_server_ciphers on;
        ssl_ciphers EECDH+CHACHA20:EECDH+AES128:RSA+AES128:EECDH+AES256:RSA+AES256:EECDH+3DES:RSA+3DES:!MD5;
        
        location ~* ^.+\\.(?:css|cur|js|jpe?g|gif|htc|ico|png|html|xml|otf|ttf|eot|woff|svg)\$ {
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
                fastcgi_pass unix:/run/php/php7.1-fpm.${USERNAME}.sock;
                fastcgi_read_timeout 60;
        }

        location ~ /\\.ht {
                deny all;
        }
}
EOF
    sudo mv /tmp/new_nginx_site.conf /etc/nginx/conf.d/$DOMAIN.conf
    sudo systemctl reload nginx.service
    sudo /usr/local/bin/lego --accept-tos --email="$LE_EMAIL" --path "/var/lego" --domains="$DOMAIN" --domains="www.$DOMAIN" --webroot="/usr/share/nginx/acme-challenge" run && sudo sed -i 's/\/etc\/nginx\/ssl/\/var\/lego\/certificates/' && sudo systemctl reload nginx.service
    sudo touch /etc/cron.d/letencrypt
    echo "0 0 1 * * root /usr/local/bin/lego --accept-tos --email=$LE_EMAIL --path /var/lego --domains=$DOMAIN --domains=www.$DOMAIN --webroot=/usr/share/nginx/acme-challenge renew && /bin/systemctl reload nginx.service" | sudo tee /etc/cron.d/letencrypt
else
    ./create_user.sh $USERNAME
fi

