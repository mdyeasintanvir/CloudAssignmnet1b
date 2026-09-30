#!/bin/bash
# EC2 User data for the Bastion/Web server (Amazon Linux 2023).
# Paste this whole file into: Launch instance -> Advanced details -> User data.
# Installs Apache + PHP, and downloads phpMyAdmin into /var/www/html/phpmyadmin.

dnf update -y
dnf install -y httpd php php-fpm php-mysqlnd php-pdo php-mbstring php-xml unzip wget

systemctl enable --now php-fpm
systemctl enable --now httpd

# Web app directory required by the assignment
mkdir -p /var/www/html/cos20019/photoalbum

# phpMyAdmin (from "Install phpMyAdmin on EC2" instructions)
cd /var/www/html
wget -q https://files.phpmyadmin.net/phpMyAdmin/5.2.2/phpMyAdmin-5.2.2-english.zip \
  || wget -q https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-english.zip
unzip -q phpMyAdmin-*-english.zip
mv phpMyAdmin-*-english phpmyadmin
rm -f phpMyAdmin-*-english.zip
cp phpmyadmin/config.sample.inc.php phpmyadmin/config.inc.php

# Let ec2-user edit web files
usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

systemctl restart php-fpm httpd
