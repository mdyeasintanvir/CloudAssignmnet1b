# Assignment 2 – create ELBSG, NATServerSG, DevServerSG in YTanvirVPC (free).
# WebServerSG and DBServerSG already exist from 1B and are changed later.
export AWS_PAGER=""
VPC=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=YTanvirVPC --query 'Vpcs[0].VpcId' --output text)
WEBSG=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC Name=group-name,Values=WebServerSG --query 'SecurityGroups[0].GroupId' --output text)
echo "VPC=$VPC  WebServerSG=$WEBSG"

ELB=$(aws ec2 create-security-group --group-name ELBSG --description "A2 load balancer - HTTP from internet" --vpc-id $VPC \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=ELBSG}]' --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $ELB --protocol tcp --port 80 --cidr 0.0.0.0/0 > /dev/null

NAT=$(aws ec2 create-security-group --group-name NATServerSG --description "A2 NAT instance - HTTP/HTTPS from web servers only" --vpc-id $VPC \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=NATServerSG}]' --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $NAT --ip-permissions \
  "IpProtocol=tcp,FromPort=80,ToPort=80,UserIdGroupPairs=[{GroupId=$WEBSG}]" \
  "IpProtocol=tcp,FromPort=443,ToPort=443,UserIdGroupPairs=[{GroupId=$WEBSG}]" > /dev/null

DEV=$(aws ec2 create-security-group --group-name DevServerSG --description "A2 Dev server - SSH HTTP ICMP from anywhere" --vpc-id $VPC \
  --tag-specifications 'ResourceType=security-group,Tags=[{Key=Name,Value=DevServerSG}]' --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id $DEV --ip-permissions \
  "IpProtocol=tcp,FromPort=22,ToPort=22,IpRanges=[{CidrIp=0.0.0.0/0}]" \
  "IpProtocol=tcp,FromPort=80,ToPort=80,IpRanges=[{CidrIp=0.0.0.0/0}]" \
  "IpProtocol=icmp,FromPort=-1,ToPort=-1,IpRanges=[{CidrIp=0.0.0.0/0}]" > /dev/null

aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC --query 'SecurityGroups[].[GroupName,GroupId]' --output table
