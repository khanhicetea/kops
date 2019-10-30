#/bin/bash

echo -e "\n===== Automated Renew Certificates ====="

while IFS='|' read -r domain email
do
    echo -e "\n- Trying to renew domain $domain of $email"
    sudo /usr/local/bin/lego -a --path /var/lego --email $email --domains $domain --http --http.webroot=/usr/share/nginx/acme-challenge renew --days 30
done < ~/.renew_domains

echo -e "\n===== Reload NGINX server ====="
sudo systemctl reload nginx

echo -e "\n===== DONE ====="