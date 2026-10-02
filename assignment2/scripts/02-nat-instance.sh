# Assignment 2 – launch NAT instance in PublicSubnet1 (console search hides this deprecated AMI).
export AWS_PAGER=""
VPC=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=YTanvirVPC --query 'Vpcs[0].VpcId' --output text)
SUB=$(aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC Name=tag:Name,Values=PublicSubnet1 --query 'Subnets[0].SubnetId' --output text)
NATSG=$(aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC Name=group-name,Values=NATServerSG --query 'SecurityGroups[0].GroupId' --output text)
echo "VPC=$VPC  PublicSubnet1=$SUB  NATServerSG=$NATSG"
NATID=$(aws ec2 run-instances --image-id ami-00a36856283d67c39 --instance-type t3.micro --key-name vockey \
  --network-interfaces "DeviceIndex=0,SubnetId=$SUB,Groups=$NATSG,AssociatePublicIpAddress=true" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=NATServer}]' --query 'Instances[0].InstanceId' --output text)
echo "NATServer=$NATID  (waiting until running...)"
aws ec2 wait instance-running --instance-ids $NATID
aws ec2 modify-instance-attribute --instance-id $NATID --no-source-dest-check
aws ec2 describe-instances --instance-ids $NATID --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value,InstanceId,State.Name,InstanceType,PrivateIpAddress,PublicIpAddress,SourceDestCheck]' --output table
