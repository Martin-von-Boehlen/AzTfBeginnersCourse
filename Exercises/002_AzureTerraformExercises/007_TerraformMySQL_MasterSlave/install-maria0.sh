#!/bin/bash


# ************************************************************************
# globals & macros
#
export ITER="${iter}"
let SRVID=$ITER+1
export MASTER_FQDN="${db_fqdn}"
export DB_USR="${db_user}" 
export DB_PWD="${db_pwd}"
export DB_REP_USR="${db_rep_usr}" 
export DB_REP_PWD="${db_rep_pwd}"

export CFGORG=/etc/mysql/mysql.conf.d/mysqld.cnf.org


# ************************************************************************
# functions 4 mysql server config
#

#
# generate config file
#
configure_mysqld_cnf() {
    sudo mv /etc/mysql/mysql.conf.d/mysqld.cnf $CFGORG
    
sudo tee /etc/mysql/mysql.conf.d/mysqld.cnf <<EOT
# The following values assume you have at least 32M ram

[mysqld_safe]
socket          = /var/run/mysqld/mysqld.sock
nice            = 0

[mysqld]
#
# * Basic Settings
#
user            = mysql
pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
port            = 3306
basedir         = /usr
datadir         = /var/lib/mysql
tmpdir          = /tmp
lc-messages-dir = /usr/share/mysql
skip-external-locking
#
# Instead of skip-networking the default is now to listen only on
# localhost which is more compatible and is not less secure.
bind-address  = 0.0.0.0
#
# * Fine Tuning
#
key_buffer_size         = 16M
max_allowed_packet      = 16M
thread_stack            = 192K
thread_cache_size       = 8
# This replaces the startup script and checks MyISAM tables if needed
# the first time they are touched
myisam-recover-options  = BACKUP
#max_connections        = 100
#table_open_cache       = 64
#thread_concurrency     = 10
#
# * Query Cache Configuration
#
query_cache_limit       = 1M
query_cache_size        = 16M
#
#
server-id = $SRVID
#
#
key_buffer_size         = 16M
max_allowed_packet      = 16M
thread_stack            = 192K
thread_cache_size       = 8
#
myisam-recover-options  = BACKUP
#
query_cache_limit       = 1M
query_cache_size        = 16M
#
log_error = /var/log/mysql/error.log
#
# --------------------- imaster/slave -----------------------
log_bin                 = /mnt/mysql/binlog/mysql-bin
sync_binlog             = 1
expire_logs_days        = 10
max_binlog_size         = 100M
relay_log               = /mnt/mysql/relaylog/mysql-relay-bin
#
EOT
#sudo sed -i -e '1,$s/bind\-address.*127\.0\.0\.1/bind\-address\ \ \=\ 0\.0\.0\.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf
}


#
# setup server process
#
configure_mysqlserver() {
    sudo apt install mysql-server-5.7 -y
    sudo systemctl stop mysql
    sudo mkdir -p /var/run/mysqld
    sudo chown mysql:mysql /var/run/mysqld
    sudo chmod -R 750 /mnt/mysql
    sudo chown -R mysql:mysql /mnt/mysql
    #
    configure_mysqld_cnf
    #
    sudo systemctl enable mysql
    sudo systemctl restart mysql
}

#
# configure admin user
#
configure_adminusers() {
    echo "CREATE USER '"$DB_USR"'@'%' IDENTIFIED BY '"$DB_PWD"';" | mysql -u root
    echo "GRANT ALL on *.* TO '"$DB_USR"'@'%' WITH GRANT OPTION;" | mysql -u root
    echo "GRANT REPLICATION SLAVE, REPLICATION CLIENT ON *.* TO '"$DB_REP_USR"'@'%' IDENTIFIED BY '"$DB_REP_PWD"';" | mysql -u root
    echo "FLUSH PRIVILEGES;" | mysql -u root
}

#
# configure replication ONLY ON slave.
#
configure_slave() {
    # nop
    echo nop
}

# ************************************************************************
# configure server
#
sudo date
sudo rm /etc/localtime
sudo ln -s /usr/share/zoneinfo/Europe/Berlin /etc/localtime
sudo date
sudo date -u

#
# remove apparmor
#
sudo systemctl stop apparmor
sudo systemctl disable apparmor
sudo apt purge apparmor -y
sudo rm -rf /etc/apparmor*
sudo chattr -i /mnt/DATALOSS_WARNING_README.txt
sudo rm /mnt/DATALOSS_WARNING_README.txt

#
# prep log partition
#
sudo mkdir -p /mnt/mysql/binlog
sudo mkdir -p /mnt/mysql/relaylog

# ************************************************************************
# mysql server config
#
configure_mysqlserver
configure_adminusers

