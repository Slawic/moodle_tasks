#!/bin/bash
# WEB Params >
# DBNAME=$1
# DBUSER=$2
# DBPASS=$3
# DBHOST=$4
# LBHOST=$5
DBNAME="moodle"
DBUSER="UserDB"
DBPASS="PassDB"
DBHOST="192.168.56.101"
LBHOST="192.168.56.100"
# <

# packets update >
sudo yum clean all
sudo yum -y update
# <
# install Apache >
sudo yum -y install httpd
sudo systemctl start httpd
sudo systemctl enable httpd
# <
# install PHP7.2 >
sudo yum -y install epel-release
sudo rpm -Uhv https://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum -y install yum-utils
sudo yum-config-manager --enable remi-php72
sudo yum -y install php php-mysql php-xml php-xmlrpc php-gd php-intl php-mbstring php-soap php-zip 
sudo yum -y install php-opcache php-cli php-pgsql php-pdo php-fileinfo php-curl php-common php-fpm
sudo systemctl restart httpd.service
# <

# Install App moodle 3.6 >
curl https://download.moodle.org/download.php/direct/stable36/moodle-latest-36.tgz -o moodle-latest-36.tgz -s
sudo tar -xvzf moodle-latest-36.tgz -C /var/www/html/
sudo mkdir /var/moodledata
sudo chmod 777 /var/moodledata
sudo touch /var/www/html/config.php
sudo chmod 777 /var/www/html/config.php
# <

# install MOODLE >
sudo systemctl stop firewalld.service

sudo /usr/bin/php /var/www/html/moodle/admin/cli/install.php --chmod=2770 \
 --lang=uk \
 --chmod=2770 \
 --dbtype=pgsql \
 --wwwroot=http://$LBHOST/ \
 --dataroot=/var/moodledata \
 --dbhost=$DBHOST \
 --dbname=$DBNAME \
 --dbuser=$DBUSER \
 --dbpass=$DBPASS \
 --dbport=5432 \
 --fullname=MoodleYMD \
 --shortname=ymd \
 --summary=MOODLE \
 --adminpass=Admin1 \
 --non-interactive \
 --agree-license
sudo chown -R apache:apache /var/www/html/moodle


# sudo systemctl start firewalld.service
# sudo firewall-cmd --permanent --zone=public --add-rich-rule='
#   rule family="ipv4"
#   source address="${LBHOST}/32"
#   port protocol="tcp" port="80" accept'
# sudo firewall-cmd --reload

sudo systemctl restart httpd
