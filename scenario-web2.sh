#!/bin/bash
# HOSTS IP >
WEB_HOST=$1
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
                    php-devel php-pear php-bcmath php-json php-pdo php-pgsql php-pecl-memcached
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

$CFG->lang      = 'en';
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
$CFG->wwwroot   = 'http://${WEB_HOST}';
$CFG->dataroot  = '/var/moodledata';
$CFG->admin     = 'admin';
$CFG->directorypermissions = 02777;
require_once(__DIR__ . '/lib/setup.php');
EOF
# install Memcache ext-module for php >
sudo yum -y install php-pecl-memcache
# <
# configure parameters for ext-module >
sudo sed -i -e "s/.*session.save_handler.*/session.save_handler=memcached/g" /etc/php.d/50-memcached.ini
sudo sed -i -e "s|.*session.save_path.*|session.save_path=\x22tcp://${DB_HOST}:11211\x22|g" /etc/php.d/50-memcached.ini
sudo sed -i -e "s|.*soap.wsdl_cache_dir.*|soap.wsdl_cache_dir = \x22/var/lib/php/wsdlcache\x22|g" /etc/php.d/50-memcached.ini
#sudo chown -R apache:apache /var/lib/php/wsdlcache
# <
# writing test Memcache-script "memcachetest.php" into the DocumentRoot >
memcache='$memcache'
mversion='$version'
tmp_object='$tmp_object'
mget_result='$get_result'

cat <<EOF | sudo tee -a /var/www/html/moodle/memcachetest.php
<?php
 
if (!class_exists("Memcache"))  exit("Memcached isn't installed");
$memcache = new Memcache;
$memcache->connect('${WEB_HOST}', 11211) or exit("can't connect to the server Memcached ");
 
$mversion = $memcache->getVersion();
echo "Server's version: ".$mversion."<br/>\n";
 
$tmp_object = new stdClass;
$tmp_object->str_attr = 'test';
$tmp_object->int_attr = 123;
 
$memcache->set('key', $tmp_object, false, 10) or die ("Can't to keep chain in Memcached");
echo "Writing a data into the cache Memcached (data will be stored for 10 sec)<br/>\n";
 
$mget_result = $memcache->get('key');
echo "Data, which had been writing in Memcached:<br/>\n";

var_dump($mget_result);

?>
EOF
# <
# info.php scr >
cat <<EOF | sudo tee -a /var/www/html/moodle/info.php
<?php
phpinfo();
?>
EOF
# <

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
