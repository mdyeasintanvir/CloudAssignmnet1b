#!/bin/bash
# Assignment 2 – PrivateSubnetsNACL, private route to NAT, target group, ALB, ASG + scaling policy.
# COST: the ALB (~$0.80/day incl. its public IPs) keeps billing after End Lab -> delete it after screenshots.
export AWS_PAGER=""
DEV_IP=10.0.2.57/32
VPC=$(aws ec2 describe-vpcs --filters Name=tag:Name,Values=YTanvirVPC --query 'Vpcs[0].VpcId' --output text)
sub() { aws ec2 describe-subnets --filters Name=vpc-id,Values=$VPC Name=tag:Name,Values=$1 --query 'Subnets[0].SubnetId' --output text; }
sg()  { aws ec2 describe-security-groups --filters Name=vpc-id,Values=$VPC Name=group-name,Values=$1 --query 'SecurityGroups[0].GroupId' --output text; }
PUB1=$(sub PublicSubnet1); PUB2=$(sub PublicSubnet2); PRIV1=$(sub PrivateSubnet1); PRIV2=$(sub PrivateSubnet2)
ELBSG=$(sg ELBSG)
NAT=$(aws ec2 describe-instances --filters Name=tag:Name,Values=NATServer Name=instance-state-name,Values=running --query 'Reservations[0].Instances[0].InstanceId' --output text)
echo "VPC=$VPC PUB=$PUB1,$PUB2 PRIV=$PRIV1,$PRIV2 ELBSG=$ELBSG NAT=$NAT"
for v in "$PUB1" "$PUB2" "$PRIV1" "$PRIV2" "$ELBSG" "$NAT"; do [ "$v" = "None" ] && { echo "STOP: something not found"; exit 1; }; done

echo "== 1/5 PrivateSubnetsNACL (block ICMP to/from Dev server $DEV_IP, allow the rest)"
NACL=$(aws ec2 describe-network-acls --filters Name=vpc-id,Values=$VPC Name=tag:Name,Values=PrivateSubnetsNACL --query 'NetworkAcls[0].NetworkAclId' --output text)
if [ "$NACL" = "None" ]; then
  NACL=$(aws ec2 create-network-acl --vpc-id $VPC --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=PrivateSubnetsNACL}]' --query 'NetworkAcl.NetworkAclId' --output text)
  for dir in --ingress --egress; do
    aws ec2 create-network-acl-entry --network-acl-id $NACL $dir --rule-number 100 --protocol 1 --icmp-type-code Code=-1,Type=-1 --cidr-block $DEV_IP --rule-action deny
    aws ec2 create-network-acl-entry --network-acl-id $NACL $dir --rule-number 200 --protocol -1 --cidr-block 0.0.0.0/0 --rule-action allow
  done
fi
for s in $PRIV1 $PRIV2; do
  ASSOC=$(aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=$s --query "NetworkAcls[0].Associations[?SubnetId=='$s'].NetworkAclAssociationId" --output text)
  aws ec2 replace-network-acl-association --association-id $ASSOC --network-acl-id $NACL > /dev/null
done
echo "   $NACL associated with PrivateSubnet1+2"

echo "== 2/5 private route table: 0.0.0.0/0 -> NAT instance"
RT=$(aws ec2 describe-route-tables --filters Name=association.subnet-id,Values=$PRIV1 --query 'RouteTables[0].RouteTableId' --output text)
aws ec2 create-route --route-table-id $RT --destination-cidr-block 0.0.0.0/0 --instance-id $NAT > /dev/null 2>&1 \
  || aws ec2 replace-route --route-table-id $RT --destination-cidr-block 0.0.0.0/0 --instance-id $NAT
echo "   $RT -> $NAT"

echo "== 3/5 target group PhotoAlbumTG (health check /photoalbum/album.php)"
TG=$(aws elbv2 create-target-group --name PhotoAlbumTG --protocol HTTP --port 80 --vpc-id $VPC --target-type instance \
  --health-check-path /photoalbum/album.php --health-check-interval-seconds 15 --healthy-threshold-count 2 \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

echo "== 4/5 Application Load Balancer PhotoAlbumALB (public subnets, ELBSG)"
ALB=$(aws elbv2 create-load-balancer --name PhotoAlbumALB --type application --scheme internet-facing \
  --subnets $PUB1 $PUB2 --security-groups $ELBSG --query 'LoadBalancers[0].LoadBalancerArn' --output text)
aws elbv2 create-listener --load-balancer-arn $ALB --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$TG > /dev/null
DNS=$(aws elbv2 describe-load-balancers --load-balancer-arns $ALB --query 'LoadBalancers[0].DNSName' --output text)

echo "== 5/5 Auto Scaling group PhotoAlbumASG (min 2, max 3, private subnets) + target tracking 30 req/target"
aws autoscaling create-auto-scaling-group --auto-scaling-group-name PhotoAlbumASG \
  --launch-template LaunchTemplateName=PhotoAlbumLT,Version='$Latest' --min-size 2 --max-size 3 --desired-capacity 2 \
  --vpc-zone-identifier "$PRIV1,$PRIV2" --target-group-arns $TG --health-check-type ELB --health-check-grace-period 120 \
  --tags Key=Name,Value=PhotoAlbumWebServer,PropagateAtLaunch=true
LABEL="$(echo $ALB | sed 's#.*:loadbalancer/##')/$(echo $TG | sed 's#.*:##')"
aws autoscaling put-scaling-policy --auto-scaling-group-name PhotoAlbumASG --policy-name RequestCountPerTarget30 \
  --policy-type TargetTrackingScaling --target-tracking-configuration \
  "{\"PredefinedMetricSpecification\":{\"PredefinedMetricType\":\"ALBRequestCountPerTarget\",\"ResourceLabel\":\"$LABEL\"},\"TargetValue\":30}" > /dev/null
echo
echo "Website (ready in ~3-5 minutes): http://$DNS/photoalbum/album.php"
echo "DONE"
