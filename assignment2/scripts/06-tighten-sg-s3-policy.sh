#!/bin/bash
# Assignment 2 – least-privilege security groups + S3 bucket policy restricted by HTTP Referer.
# The 1B site (44.217.73.92) keeps working: the Dev server moves to DevServerSG and its referer stays allowed.
export AWS_PAGER=""
DEV=i-01cc5ea28b989ceab
BUCKET=ytanvir-photoalbum-2026
VPC=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=YTanvirVPC --query 'Vpcs[0].VpcId' --output text)
sg() { aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC Name=group-name,Values=$1 --query 'SecurityGroups[0].GroupId' --output text; }
WEBSG=$(sg WebServerSG); DBSG=$(sg DBServerSG); DEVSG=$(sg DevServerSG); ELBSG=$(sg ELBSG)
ALBDNS=$(aws elbv2 describe-load-balancers --names PhotoAlbumALB --query 'LoadBalancers[0].DNSName' --output text | tr 'A-Z' 'a-z')
echo "WebServerSG=$WEBSG DBServerSG=$DBSG DevServerSG=$DEVSG ELBSG=$ELBSG ALB=$ALBDNS"
for v in "$WEBSG" "$DBSG" "$DEVSG" "$ELBSG" "$ALBDNS"; do [ "$v" = "None" ] && { echo "STOP: something not found"; exit 1; }; done

echo "== 1/4 DBServerSG: MySQL 3306 also from DevServerSG (phpMyAdmin on the Dev server)"
aws ec2 authorize-security-group-ingress --group-id $DBSG --protocol tcp --port 3306 --source-group $DEVSG > /dev/null 2>&1 || echo "   (rule already there)"

echo "== 2/4 Dev server $DEV -> DevServerSG only"
aws ec2 modify-instance-attribute --instance-id $DEV --groups $DEVSG

echo "== 3/4 WebServerSG: only HTTP from ELBSG + ICMP from DevServerSG (to test the NACL)"
OLD=$(aws ec2 describe-security-groups --group-ids $WEBSG --query 'SecurityGroups[0].IpPermissions' --output json)
[ "$OLD" != "[]" ] && aws ec2 revoke-security-group-ingress --group-id $WEBSG --ip-permissions "$OLD" > /dev/null
aws ec2 authorize-security-group-ingress --group-id $WEBSG --ip-permissions \
  "IpProtocol=tcp,FromPort=80,ToPort=80,UserIdGroupPairs=[{GroupId=$ELBSG}]" \
  "IpProtocol=icmp,FromPort=-1,ToPort=-1,UserIdGroupPairs=[{GroupId=$DEVSG}]" > /dev/null

echo "== 4/4 S3 bucket policy: GetObject only when Referer is the ELB site (or the 1B Dev server site)"
aws s3api get-bucket-policy --bucket $BUCKET --query Policy --output text > ~/old-bucket-policy.json 2>/dev/null && echo "   old policy saved to ~/old-bucket-policy.json"
cat > /tmp/policy.json <<JSON
{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "AllowGetOnlyFromPhotoAlbumWebsite",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::$BUCKET/*",
    "Condition": { "StringLike": { "aws:Referer": ["http://$ALBDNS/*", "http://44.217.73.92/*"] } }
  }]
}
JSON
aws s3api put-bucket-policy --bucket $BUCKET --policy file:///tmp/policy.json && cat /tmp/policy.json

echo; echo "Security group inbound rules now:"
for g in ELBSG WebServerSG DBServerSG NATServerSG DevServerSG; do
  echo "--- $g"
  aws ec2 describe-security-groups --group-ids $(sg $g) --query 'SecurityGroups[0].IpPermissions[].[IpProtocol,FromPort,ToPort,join(`,`,IpRanges[].CidrIp),join(`,`,UserIdGroupPairs[].GroupId)]' --output text
done
echo "DONE"
