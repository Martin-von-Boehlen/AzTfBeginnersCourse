#!/bin/bash

# ************************************************************************
# function 4 server config
#
configure_mysqlserver() {
    sudo sed -i -e '1,$s/bind\-address.*127\.0\.0\.1/bind\-address\ \ \=\ 0\.0\.0\.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
    sudo systemctl restart mysql
}


# ************************************************************************
# configure admin user
#
sudo apt install mysql-server-5.7 -y
sudo mkdir -p /var/run/mysqld
sudo chown mysql:mysql /var/run/mysqld
sudo systemctl enable mysql
sudo echo "CREATE USER 'sqladmin'@'%' IDENTIFIED BY 'blackmaria';" | mysql -u root
sudo echo "GRANT ALL on *.* TO 'sqladmin'@'%' WITH GRANT OPTION;" | mysql -u root
sudo echo "FLUSH PRIVILEGES;" | mysql -u root
# ************************************************************************
# server config
#
configure_mysqlserver
