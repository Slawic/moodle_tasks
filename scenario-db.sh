#!/bin/bash
# DB Conf >
WEB_SERVER1=$1
WEB_SERVER2=$2
# <
# DB SQL Params >
DB_NAME=$3
DB_USER=$4
DB_PASS=$5
# <
# update the system package >
sudo yum -y update
# <
# install DB postgresql from repositary >
# sudo yum -y install https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/pgdg-centos11-11-2.noarch.rpm
sudo yum -y install https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/pgdg-redhat11-11-2.noarch.rpm
# <
# install postgresql11 >
# sudo yum -y install postgresql-server postgresql-contrib
sudo yum -y install postgresql11 postgresql11-server
# <
# initialize the DB >
sudo /usr/pgsql-11/bin/postgresql-11-setup initdb
# <
# enable & start DB service >
sudo systemctl enable postgresql-11
sudo systemctl start postgresql-11
# <
# create DB >
sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH ENCRYPTED PASSWORD 'passdbdb';"
sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} WITH OWNER ${DB_USER};"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} to ${DB_USER};"
# <
# check the service status: command: systemctl status postgresql-11
# enable remote ac. to postgreSQL * for all i-faces
# in file: /var/lib/pgsql/11/data/postgresql.conf >
sudo sed -i -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/11/data/postgresql.conf
sudo sed -i -e "s/#port = 5432/port = 5432/g" /var/lib/pgsql/11/data/postgresql.conf
# <
# accept remote connections >
sudo cat <<EOF | sudo tee -a /var/lib/pgsql/11/data/pg_hba.conf
host    all             all              ${WEB_SERVER1}/32        password
host    all             all              ${WEB_SERVER2}/32        password
EOF
# <

sudo systemctl restart postgresql-11

# install Memcache module >
sudo yum -y install memcached
# <
# start Memcache module and enable boot >
sudo systemctl start memcached
sudo systemctl enable memcached
sudo setenforce 0
# <