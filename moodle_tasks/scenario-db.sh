#!/bin/bash
# DB Params >
DBNAME="moodle"
DBUSER="UserDB"
DBPASS="PassDB"
ADMUSER="Moodle"
ADMPASS="Passw0rd"
#
# update the system package >
sudo yum -y update
# <
# install DB postgresql from repositary >
sudo yum -y install https://download.postgresql.org/pub/repos/yum/11/redhat/rhel-7-x86_64/pgdg-centos11-11-2.noarch.rpm
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
# check the service status: command: systemctl status postgresql-11
# enable remote ac. to postgreSQL * for all i-faces
# in file: /var/lib/pgsql/11/data/postgresql.conf >
sudo sed -i -e "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/11/data/postgresql.conf
sudo sed -i -e "s/#port = 5432/port = 5432/g" /var/lib/pgsql/11/data/postgresql.conf
# <
# accept remote connections >
sudo cat <<EOF | sudo tee -a /var/lib/pgsql/11/data/pg_hba.conf
host    all             all              192.168.56.102/32        password
host    all             all              192.168.56.103/32        password
EOF
# <
# restart service >
sudo systemctl restart postgresql-11
# <
# create DB :Add PostgreSQL admin user, ...>
sudo -u postgres psql -c "ALTER USER postgres WITH PASSWORD '1qaz2wsx';"
sudo -u postgres psql -c "CREATE USER UserDB WITH ENCRYPTED PASSWORD 'PassDB';"
sudo -u postgres psql -c "CREATE DATABASE moodle WITH OWNER UserDB;"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE moodle to UserDB;"
# <

# configure firewall for postgres >
sudo systemctl start firewalld.service
sudo firewall-cmd --add-service=postgresql --permanent
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
   rule family="ipv4"
   source address="192.168.56.102/32"
   port protocol="tcp" port="5432" accept'
sudo firewall-cmd --permanent --zone=public --add-rich-rule='
   rule family="ipv4"
   source address="192.168.56.103/32"
   port protocol="tcp" port="5432" accept'
sudo firewall-cmd --reload
# <