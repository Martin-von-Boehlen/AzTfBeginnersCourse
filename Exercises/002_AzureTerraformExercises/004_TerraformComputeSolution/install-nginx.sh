#!/bin/bash
sudo apt-get update
sudo apt install nginx -y
sudo snap install core && sudo snap refresh core
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo /bin/sh -v -c "/usr/bin/certbot --agree-tos --email mvb4711@gmail.com -n --nginx --domains mvb4711.westeurope.cloudapp.azure.com"
sudo systemctl restart nginx
