#!/bin/bash
# HOSTS IP >
LB_HOST=$1
DB_HOST=$2
# <
# DB SQL Params >
DB_NAME=$3
DB_USER=$4
DB_PASS=$5
# <
# packets update >
sudo yum clean all
sudo yum -y update
# <
# install Apache >
sudo yum -y install httpd
sudo sed -i -e 's+DocumentRoot "/var/www/html"+DocumentRoot "/var/www/html/moodle"+g' /etc/httpd/conf/httpd.conf
sudo sed -i -e 's+DirectoryIndex index.html+DirectoryIndex index.php index.html index.htm+g' /etc/httpd/conf/httpd.conf
sudo setsebool -P httpd_can_network_connect=1
sudo systemctl enable httpd
sudo systemctl start httpd
# <
# install PHP7.3 >
sudo yum -y install epel-release.noarch
sudo yum -y install https://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum -y install yum-utils
sudo yum-config-manager --disable remi-php54
sudo yum-config-manager --enable remi-php73
sudo yum -y install php php-mcrypt php-cli php-gd php-curl php-ldap php-zip php-fileinfo
sudo yum -y install php-xml php-intl php-mbstring php-xmlrpc php-soap php-fpm \
                    php-devel php-pear php-bcmath php-json php-pdo php-pgsql
# <

# Install App moodle 3.6 >
curl https://download.moodle.org/download.php/direct/stable36/moodle-latest-36.tgz -o moodle-latest-36.tgz -s
sudo tar -xvzf moodle-latest-36.tgz -C /var/www/html/
sudo mkdir /var/moodledata
# 
sudo php /var/www/html/moodle/admin/cli/install.php --chmod=2770 \
--lang=uk \
--wwwroot=http://${LB_HOST} \
--dataroot=/var/moodledata \
--dbtype=pgsql \
--dbhost=${DB_HOST} \
--dbname=${DB_NAME} \
--dbuser=${DB_USER} \
--dbpass=${DB_PASS} \
--dbport=5432 \
--fullname=Moodle \
--shortname=ymd \
--summary=Moodle \
--adminuser=admin \
--adminpass=admpass \
--non-interactive \
--agree-license
sudo chmod o+r /var/www/html/moodle/config.php
sudo chcon -R -t httpd_sys_rw_content_t /var/moodledata
sudo chown -R apache:apache /var/www/
sudo chown -R apache:apache /var/moodledata
# <

# restart Apache >
sudo systemctl restart httpd
# <
# Setup&Config Firewall
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --zone=public --add-service=ssh
sudo firewall-cmd --permanent --zone=public --add-service=http 
sudo firewall-cmd --permanent --zone=public --add-service=https
sudo firewall-cmd --reload
