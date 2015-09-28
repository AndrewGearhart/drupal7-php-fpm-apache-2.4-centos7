#!/bin/bash

# install apache
yum install nano vim wget curl git httpd -y

# get some repos
rpm -Uvh https://mirror.webtatic.com/yum/el7/epel-release.rpm
rpm -Uvh https://mirror.webtatic.com/yum/el7/webtatic-release.rpm
rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

# get latest mysql
wget http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm
yum localinstall mysql-community-release-el7-5.noarch.rpm -y
yum update -y
yum install mysql-community-server -y

# php
yum install -y php56w php56w-fpm php56w-opcache php56w-cli php56w-common php56w-gd php56w-mbstring php56w-mcrypt php56w-pecl-apcu php56w-pdo php56w-xml php56w-mysqlnd

# varnish
rpm --nosignature -i https://repo.varnish-cache.org/redhat/varnish-4.0.el7.rpm
yum install -y varnish

# VARNISH
cat varnish/default.vcl > /etc/varnish/default.vcl
cat varnish/varnish.params > /etc/varnish/varnish.params

# Varnish can listen
sed -i 's/Listen 80/Listen 8080/g' /etc/httpd/conf/httpd.conf

# PHP
# The first pool
cat php/www.conf > /etc/php-fpm.d/www.conf

#opcache settings
cat php/opcache.ini > /etc/php.d/opcache.ini

#disable mod_php
cat php/php.conf > /etc/httpd/conf.d/php.conf

#disable some un-needed modules.
cat modules/00-base.conf > /etc/httpd/conf.modules.d/00-base.conf
cat modules/00-dav.conf > /etc/httpd/conf.modules.d/00-dav.conf
cat modules/00-lua.conf > /etc/httpd/conf.modules.d/00-lua.conf
cat modules/00-mpm.conf > /etc/httpd/conf.modules.d/00-mpm.conf
cat modules/00-proxy.conf > /etc/httpd/conf.modules.d/00-proxy.conf
cat modules/01-cgi.conf > /etc/httpd/conf.modules.d/01-cgi.conf

# BASIC PERFORMANCE SETTINGS
mkdir /etc/httpd/conf.performance.d/
cat performance/compression.conf > /etc/httpd/conf.performance.d/compression.conf
cat performance/content_transformation.conf > /etc/httpd/conf.performance.d/content_transformation.conf
cat performance/etags.conf > /etc/httpd/conf.performance.d/etags.conf
cat performance/expires_headers.conf > /etc/httpd/conf.performance.d/expires_headers.conf
cat performance/file_concatenation.conf > /etc/httpd/conf.performance.d/file_concatenation.conf
cat performance/filename-based_cache_busting.conf > /etc/httpd/conf.performance.d/filename-based_cache_busting.conf

# BASIC SECURITY SETTINGS
mkdir /etc/httpd/conf.security.d/
cat security/apache_default.conf > /etc/httpd/conf.security.d/apache_default.conf

# our domain config
mkdir /etc/httpd/conf.sites.d
echo IncludeOptional conf.sites.d/*.conf >> /etc/httpd/conf/httpd.conf
cat domains/8080-domain.conf > /etc/httpd/conf.sites.d/test.conf

# our performance config
echo IncludeOptional conf.performance.d/*.conf >> /etc/httpd/conf/httpd.conf

# our security config
echo IncludeOptional conf.security.d/*.conf >> /etc/httpd/conf/httpd.conf

# fix date timezone errors
sed -i 's#;date.timezone =#date.timezone = "America/New_York"#g' /etc/php.ini

# FIREWALL
systemctl start firewalld.service
systemctl enable firewalld.service
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --permanent --add-port=22/tcp

# Make sue services stay on after reboot

systemctl enable httpd.service
systemctl enable mysqld.service
systemctl enable php-fpm.service
systemctl enable varnish.service

# Start all the services we use.
systemctl start php-fpm.service
systemctl start  mysqld.service
systemctl start httpd.service
systemctl start varnish.service

# Install Drush globally.
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
ln -s /usr/local/bin/composer /usr/bin/composer
