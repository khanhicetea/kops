#!/bin/bash

set -e

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

sudo mkdir -p /home/$USERNAME/$DOMAIN
sudo chown -R $USERNAME:www-data /home/$USERNAME/$DOMAIN
sudo openssl req -new -x509 -nodes -days 3650 -newkey rsa:2048 -subj "/C=US/ST=Nil/L=Nil/O=Nil/CN=$DOMAIN" -keyout /etc/nginx/ssl/$DOMAIN.key -out /etc/nginx/ssl/$DOMAIN.crt
cat >/tmp/new_nginx_site.conf <<EOF
server {
        listen 80;
        server_name ${DOMAIN};
        
        location /.well-known {
            alias /usr/share/nginx/acme-challenge/.well-known;
        }

        location / {
            return 301 https://\$server_name\$request_uri;
        }
}

server {
        listen 443 ssl http2;
        server_name ${DOMAIN};
        root /home/${USERNAME}/${DOMAIN}/${DOC_ROOT};
        index index.php index.html index.htm;

        ssl_certificate /etc/nginx/ssl/${DOMAIN}.crt;
        ssl_certificate_key /etc/nginx/ssl/${DOMAIN}.key;
        ssl_session_timeout 60m;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers 'ECDH+AESGCM:ECDH+AES256:ECDH+AES128:DHE+AES128:!ADH:!AECDH:!MD5';
        ssl_session_cache shared:SSL:30m;
        ssl_prefer_server_ciphers on;
        ssl_dhparam /etc/nginx/certs/dhparam.pem;
        add_header Strict-Transport-Security "max-age=31536000";
        
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
                fastcgi_pass unix:/var/run/php/php7.3-fpm.${USERNAME}.sock;
        }
        
        location ~ /\\.  {
            deny all;
        }
}
EOF
sudo mv /tmp/new_nginx_site.conf /etc/nginx/conf.d/$DOMAIN.conf
sudo systemctl reload nginx.service
sudo /usr/local/bin/lego -a -k rsa2048 --path /var/lego --email $LE_EMAIL --domains $DOMAIN --http --http.webroot="/usr/share/nginx/acme-challenge" run
sudo sed -i 's/\/etc\/nginx\/ssl/\/var\/lego\/certificates/' /etc/nginx/conf.d/$DOMAIN.conf
sudo systemctl reload nginx.service

echo "$DOMAIN|$LE_EMAIL" >> ~/.renew_domains

if [ $# -eq 5 ]
then
    DB="$5"
    DB_NAME=${USERNAME}_${DB}
    mysql -e "CREATE SCHEMA \`$DB_NAME\` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
fi

# Done
echo -e "\nDone ! Enjoy it !"
