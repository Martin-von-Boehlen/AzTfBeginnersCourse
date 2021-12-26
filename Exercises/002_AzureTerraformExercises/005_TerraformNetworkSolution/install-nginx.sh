#!/bin/bash
sudo apt-get update
sudo apt install nginx -y
sudo snap install core && sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo /bin/sh -v -c "/usr/bin/certbot --test-cert --agree-tos --email <your_email>@somewhere -n --nginx --domains <your_FQDN>"
sudo systemctl restart nginx
