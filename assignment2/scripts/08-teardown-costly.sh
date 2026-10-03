#!/bin/bash
# Tear down everything that still costs money after Assignment 2 (tutor: "Can delete everything, I just need the screenshot").
# Deletes: 4 EC2 instances, both Elastic IPs, RDS photodb (no final snapshot), PhotoAlbumAMI + its snapshot, NAT route.
# Keeps (free): VPC, subnets, IGW, route tables, SGs, NACLs, S3 bucket, Lambda, launch template, target group.
export AWS_PAGER=""
echo "== 1/5 release Elastic IPs"
for a in $(aws ec2 describe-addresses --query 'Addresses[].AllocationId' --output text); do
  as=$(aws ec2 describe-addresses --allocation-ids $a --query 'Addresses[0].AssociationId' --output text)
  [ "$as" != "None" ] && aws ec2 disassociate-address --association-id $as
  aws ec2 release-address --allocation-id $a && echo "   released $a"
done
echo "== 2/5 terminate EC2 instances (NATServer, WebServer/Dev, TestInstance, 1A instance)"
aws ec2 terminate-instances --instance-ids i-09fb44b46bfb199cd i-01cc5ea28b989ceab i-01d837294b03b356c i-0919f71ec864f60c3 \
  --query 'TerminatingInstances[].[InstanceId,CurrentState.Name]' --output text
echo "== 3/5 delete RDS photodb (no final snapshot)"
aws rds delete-db-instance --db-instance-identifier photodb --skip-final-snapshot --delete-automated-backups \
  --query 'DBInstance.[DBInstanceIdentifier,DBInstanceStatus]' --output text
echo "== 4/5 deregister PhotoAlbumAMI and delete its snapshot"
AMI=$(aws ec2 describe-images --owners self --filters Name=name,Values=PhotoAlbumAMI --query 'Images[0].ImageId' --output text)
if [ "$AMI" != "None" ]; then
  SNAPS=$(aws ec2 describe-images --image-ids $AMI --query 'Images[0].BlockDeviceMappings[].Ebs.SnapshotId' --output text)
  aws ec2 deregister-image --image-id $AMI && echo "   deregistered $AMI"
  for s in $SNAPS; do aws ec2 delete-snapshot --snapshot-id $s && echo "   deleted $s"; done
fi
echo "== 5/5 remove private route to the (terminated) NAT instance"
aws ec2 delete-route --route-table-id rtb-00be7b9b9bf9c924a --destination-cidr-block 0.0.0.0/0 2>/dev/null && echo "   removed"
sleep 30
echo; echo "== audit (should show nothing running, no EIPs, RDS deleting, no LB)"
aws ec2 describe-instances --query 'Reservations[].Instances[].[Tags[?Key==`Name`]|[0].Value,State.Name]' --output table
aws ec2 describe-addresses --query 'Addresses[].PublicIp' --output text
aws rds describe-db-instances --query 'DBInstances[].[DBInstanceIdentifier,DBInstanceStatus]' --output text
aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerName' --output text
echo "DONE"
