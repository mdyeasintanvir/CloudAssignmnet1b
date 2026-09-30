cat > userdata.sh <<'UD_EOF'
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
UD_EOF
AMI=resolve:ssm:/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64
WEB=$(aws ec2 run-instances --image-id $AMI --instance-type t3.micro --key-name vockey \
  --subnet-id subnet-041e48cadf794c973 --security-group-ids sg-04c95e2290ce3a971 \
  --associate-public-ip-address --user-data file://userdata.sh \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=WebServer}]' \
  --query 'Instances[0].InstanceId' --output text)
TEST=$(aws ec2 run-instances --image-id $AMI --instance-type t3.micro --key-name vockey \
  --subnet-id subnet-0827b114a73517a60 --security-group-ids sg-010bf92e683cfb23c \
  --no-associate-public-ip-address \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=TestInstance}]' \
  --query 'Instances[0].InstanceId' --output text)
echo "WebServer=$WEB  TestInstance=$TEST  (waiting for running...)"
aws ec2 wait instance-running --instance-ids $WEB $TEST
ALLOC=$(aws ec2 allocate-address --domain vpc \
  --tag-specifications 'ResourceType=elastic-ip,Tags=[{Key=Name,Value=WebServerEIP}]' \
  --query AllocationId --output text)
aws ec2 associate-address --instance-id $WEB --allocation-id $ALLOC > /dev/null
aws ec2 describe-instances --instance-ids $WEB $TEST \
  --query 'Reservations[].Instances[].{Name:Tags[?Key==`Name`]|[0].Value,Subnet:SubnetId,PrivateIP:PrivateIpAddress,PublicIP:PublicIpAddress}' \
  --output table
