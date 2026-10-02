#!/bin/bash
# Assignment 2 – save credit: delete the ALB (bills ~$0.80/day even after End Lab) and the ASG.
# Kept (free/cheap): PhotoAlbumTG, PhotoAlbumLT, PhotoAlbumAMI, NAT instance, NACL, SGs, route.
# Re-create later with 05-nacl-nat-route-alb-asg.sh, then re-run 06 (S3 policy needs the new ALB DNS).
export AWS_PAGER=""
aws autoscaling delete-auto-scaling-group --auto-scaling-group-name PhotoAlbumASG --force-delete && echo "PhotoAlbumASG deleting (its 2 instances terminate)"
ALB=$(aws elbv2 describe-load-balancers --names PhotoAlbumALB --query 'LoadBalancers[0].LoadBalancerArn' --output text 2>/dev/null)
[ -n "$ALB" ] && [ "$ALB" != "None" ] && aws elbv2 delete-load-balancer --load-balancer-arn $ALB && echo "PhotoAlbumALB deleted"
sleep 20
echo; echo "Load balancers left:"; aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerName' --output text
echo "Auto Scaling groups left:"; aws autoscaling describe-auto-scaling-groups --query 'AutoScalingGroups[].[AutoScalingGroupName,Status]' --output text
echo "DONE"
