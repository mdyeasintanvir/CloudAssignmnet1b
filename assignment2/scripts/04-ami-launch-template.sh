#!/bin/bash
# Assignment 2 – custom AMI from the Dev server (1B WebServer) + launch template for the ASG.
# Run in CloudShell:  curl -sL <raw url of this file> | bash
export AWS_PAGER=""
DEV=i-01cc5ea28b989ceab
VPC=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=YTanvirVPC --query 'Vpcs[0].VpcId' --output text)
WEBSG=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC Name=group-name,Values=WebServerSG --query 'SecurityGroups[0].GroupId' --output text)

echo "== 1/2 custom AMI PhotoAlbumAMI from $DEV (no reboot, 1B site stays up)"
AMI=$(aws ec2 describe-images --owners self --filters Name=name,Values=PhotoAlbumAMI --query 'Images[0].ImageId' --output text)
if [ "$AMI" = "None" ]; then
  AMI=$(aws ec2 create-image --instance-id $DEV --name PhotoAlbumAMI --no-reboot \
    --description "A2 web server: Apache, PHP, AWS SDK for PHP, Photo Album in /var/www/html/photoalbum" \
    --tag-specifications 'ResourceType=image,Tags=[{Key=Name,Value=PhotoAlbumAMI}]' --query ImageId --output text)
fi
echo "   AMI=$AMI  (waiting until available, can take 3-10 minutes)"
until [ "$(aws ec2 describe-images --image-ids $AMI --query 'Images[0].State' --output text)" = "available" ]; do sleep 15; echo -n "."; done
echo " available"

echo "== 2/2 launch template PhotoAlbumLT"
aws ec2 create-launch-template --launch-template-name PhotoAlbumLT --version-description "PhotoAlbumAMI, t3.micro, WebServerSG, LabInstanceProfile" \
  --tag-specifications 'ResourceType=launch-template,Tags=[{Key=Name,Value=PhotoAlbumLT}]' \
  --launch-template-data "{\"ImageId\":\"$AMI\",\"InstanceType\":\"t3.micro\",\"KeyName\":\"vockey\",\"IamInstanceProfile\":{\"Name\":\"LabInstanceProfile\"},\"SecurityGroupIds\":[\"$WEBSG\"],\"TagSpecifications\":[{\"ResourceType\":\"instance\",\"Tags\":[{\"Key\":\"Name\",\"Value\":\"PhotoAlbumWebServer\"}]}]}" \
  --query 'LaunchTemplate.[LaunchTemplateName,LaunchTemplateId,LatestVersionNumber]' --output table
echo "DONE"
