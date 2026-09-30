NACL=$(aws ec2 create-network-acl --vpc-id vpc-0b276269b60f2e3f3 \
  --tag-specifications 'ResourceType=network-acl,Tags=[{Key=Name,Value=PublicSubnet2NACL}]' \
  --query NetworkAcl.NetworkAclId --output text)
e(){ aws ec2 create-network-acl-entry --network-acl-id $NACL --rule-action allow "$@"; }
e --ingress --rule-number 100 --protocol tcp  --port-range From=22,To=22       --cidr-block 0.0.0.0/0
e --ingress --rule-number 110 --protocol tcp  --port-range From=80,To=80       --cidr-block 0.0.0.0/0
e --ingress --rule-number 120 --protocol icmp --icmp-type-code Type=-1,Code=-1 --cidr-block 10.0.4.0/24
e --ingress --rule-number 130 --protocol tcp  --port-range From=1024,To=65535  --cidr-block 0.0.0.0/0
e --egress  --rule-number 100 --protocol tcp  --port-range From=1024,To=65535  --cidr-block 0.0.0.0/0
e --egress  --rule-number 110 --protocol tcp  --port-range From=3306,To=3306   --cidr-block 10.0.3.0/24
e --egress  --rule-number 120 --protocol tcp  --port-range From=3306,To=3306   --cidr-block 10.0.4.0/24
e --egress  --rule-number 130 --protocol icmp --icmp-type-code Type=-1,Code=-1 --cidr-block 10.0.4.0/24
e --egress  --rule-number 140 --protocol tcp  --port-range From=22,To=22       --cidr-block 10.0.4.0/24
e --egress  --rule-number 150 --protocol tcp  --port-range From=80,To=80       --cidr-block 0.0.0.0/0
e --egress  --rule-number 160 --protocol tcp  --port-range From=443,To=443     --cidr-block 0.0.0.0/0
ASSOC=$(aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=subnet-041e48cadf794c973 \
  --query "NetworkAcls[0].Associations[?SubnetId=='subnet-041e48cadf794c973'].NetworkAclAssociationId" --output text)
aws ec2 replace-network-acl-association --association-id $ASSOC --network-acl-id $NACL > /dev/null
echo "PublicSubnet2NACL = $NACL (attached to PublicSubnet2)"
