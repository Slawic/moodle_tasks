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
# moodle conf file : >
CFG='$CFG'
cat <<EOF | sudo tee -a /var/www/html/moodle/config.php 
<?php 

unset($CFG);
global $CFG;
$CFG = new stdClass();

$CFG->dbtype    = 'pgsql';
$CFG->dblibrary = 'native';
$CFG->dbhost    = '${DB_HOST}';
$CFG->dbname    = '${DB_NAME}';
$CFG->dbuser    = '${DB_USER}';
$CFG->dbpass    = '${DB_PASS}';
$CFG->prefix    = 'mdl_';
$CFG->dboptions = array (
  'dbpersist' => 0,
  'dbport' => 5432,
  'dbsocket' => '',
  'dbcollation' => 'utf8mb4_general_ci',
);
$CFG->wwwroot   = 'http://${LB_HOST}';
$CFG->dataroot  = '/var/moodledata';
$CFG->admin     = 'admin';
$CFG->directorypermissions = 02777;
require_once(__DIR__ . '/lib/setup.php');
EOF
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
