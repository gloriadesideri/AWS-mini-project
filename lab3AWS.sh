region="us-east-1"
vpc_cidr="10.0.0.0/16"
subnet_cidr_public="10.0.0.0/24"
subnet_cidr_private="10.0.1.0/24"
key_pair_name_web="key-pair-web"
key_pair_name_db="key-pair-db"
key_pair_name_ids="key-pair-ids"
security_group_name_ids="securiry_group_ids"
security_group_name_web="securiry_group_web"
security_group_name_db="securiry_group_db"

instance_type="t2.micro"
ami_id="ami-0b0ea68c435eb488d"
public_subnet_id=""
private_subnet_id=""

vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr  --query 'Vpc.VpcId' --output text --region $region)
echo "created VPC with ID: $vpc_id"

# Create public and private subnets
public_subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $subnet_cidr_public --availability-zone $region"a"  --query 'Subnet.SubnetId' --output text --region $region)
echo "created public subnet with ID: $public_subnet_id"
private_subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block $subnet_cidr_private --availability-zone $region"b" --query 'Subnet.SubnetId' --output text --region $region)
echo "created private subnet with ID: $private_subnet_id" 

# Create Internet Gateway
igw_id=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text --region $region)
aws ec2 attach-internet-gateway --vpc-id $vpc_id --internet-gateway-id $igw_id --region $region
echo "created Internet Gateway with ID: $igw_id" 

# Create a Route Table for the public subnet and associate it
public_route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id  --query 'RouteTable.RouteTableId' --output text --region $region)
echo "created public route table with ID: $public_route_table_id" 
aws ec2 associate-route-table --subnet-id $public_subnet_id --route-table-id $public_route_table_id --region $region
echo "associated public route table"
aws ec2 create-route --route-table-id $public_route_table_id --destination-cidr-block 0.0.0.0/0 --gateway-id $igw_id --region $region
echo "created route for public route table"


# Create a Security Group
security_group_id_web=$(aws ec2 create-security-group --group-name $security_group_name_web --description "Security group for web server" --vpc-id $vpc_id --query 'GroupId' --output text --region $region)
echo "created security group with ID: $security_group_id_web"
security_group_id_db=$(aws ec2 create-security-group --group-name $security_group_name_db --description "Security group for db server" --vpc-id $vpc_id --query 'GroupId' --output text --region $region)
echo "created security group with ID: $security_group_id_db"
security_group_id_ids=$(aws ec2 create-security-group --group-name $security_group_name_ids --description "Security group for web server" --vpc-id $vpc_id --query 'GroupId' --output text --region $region)
echo "created security group with ID: $security_group_id_ids"

# Allow inbound traffic to your instances
aws ec2 authorize-security-group-ingress --group-id $security_group_id_web --protocol all --cidr 0.0.0.0/0 --region $region
echo "allowed inbound traffic to web server"
aws ec2 authorize-security-group-ingress --group-id $security_group_id_db --protocol all --cidr 0.0.0.0/0 --region $region
echo "allowed inbound traffic to db server"
aws ec2 authorize-security-group-ingress --group-id $security_group_id_ids --protocol all --cidr 0.0.0.0/0 --region $region
echo "allowed inbound traffic to ids server"

# Launch EC2 instances in the public and private subnets
aws ec2 create-key-pair --key-name $key_pair_name_web --query 'KeyMaterial' --output text > $key_pair_name_web.pem
aws ec2 create-key-pair --key-name $key_pair_name_db --query 'KeyMaterial' --output text > $key_pair_name_db.pem
aws ec2 create-key-pair --key-name $key_pair_name_ids --query 'KeyMaterial' --output text > $key_pair_name_ids.pem


aws ec2 run-instances --image-id $ami_id --count 1 --instance-type $instance_type --key-name $key_pair_name_db --security-group-ids $security_group_id_db --subnet-id $private_subnet_id --region $region 
echo "launched db server instance"

aws ec2 run-instances --image-id $ami_id --count 1 --instance-type $instance_type --key-name $key_pair_name_ids --security-group-ids $security_group_id_ids --subnet-id $private_subnet_id --region $region 
echo "launched ids server instance"

instance_id_web=$(aws ec2 run-instances --image-id $ami_id --count 1 --instance-type $instance_type --key-name $key_pair_name_web --security-group-ids $security_group_id_web --subnet-id $public_subnet_id --region $region --query 'Instances[0].InstanceId' --output text)
echo "launched web server instance"
aws ec2 wait instance-running --instance-ids $instance_id_web --region $region
echo "Web instance available"


allocation_id_web=$(aws ec2 allocate-address --region $region --query 'AllocationId' --output text)
echo "created elastic ip with id: $allocation_id_web"
aws ec2 associate-address --allocation-id $allocation_id_web --instance-id $instance_id_web

#Leave NACL for later

# # Create NACLs for public and private subnets
# nacl_public_id=$(aws ec2 create-network-acl --vpc-id $vpc_id --query 'NetworkAcl.NetworkAclId' --output text --region $region)
# echo "created public NACL with ID: $nacl_public_id"
# nacl_private_id=$(aws ec2 create-network-acl --vpc-id $vpc_id --query 'NetworkAcl.NetworkAclId' --output text --region $region)
# echo "created private NACL with ID: $nacl_private_id" 

# # Create a rule for the public NACL to allow outbound traffic
# aws ec2 create-network-acl-entry --network-acl-id $nacl_public_id --rule-number 100 --protocol -1 --rule-action allow --egress --cidr-block 0.0.0.0/0 --region $region
# echo "created rule for public NACL"

# # Associate the NACLs with their respective subnets
# nacl_association_id_public=$(aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=$public_subnet_id --query 'NetworkAcls[].Associations[0].NetworkAclAssociationId' --output text --region us-east-1)
# echo "NACL association id public" $nacl_association_id_public

# aws ec2 replace-network-acl-association --association-id $nacl_association_id_public --network-acl-id $nacl_public_id --region $region
# echo "associated public NACL with public subnet"

# nacl_association_id_private=$(aws ec2 describe-network-acls --filters Name=association.subnet-id,Values=$private_subnet_id --query 'NetworkAcls[].Associations[0].NetworkAclAssociationId' --output text --region us-east-1)
# echo "NACL association id private" $nacl_association_id_private
# aws ec2 replace-network-acl-association --association-id $nacl_association_id_private --network-acl-id $nacl_private_id --region $region
# echo "associated private NACL with private subnet"

# Create a NAT Gateway in the public subnet
allocation_id=$(aws ec2 allocate-address --region $region --query 'AllocationId' --output text)
echo "created elastic ip with id: $allocation_id"

nat_gateway_id=$(aws ec2 create-nat-gateway --subnet-id $public_subnet_id --allocation-id $allocation_id --region $region --query 'NatGateway.NatGatewayId' --output text)
echo "created NAT Gateway with ID: $nat_gateway_id"

# Wait for the NAT Gateway to become available
aws ec2 wait nat-gateway-available --nat-gateway-ids $nat_gateway_id --region $region
echo "NAT Gateway is available"

# Create a Route Table for the private subnet and associate it
private_route_table_id=$(aws ec2 create-route-table --vpc-id $vpc_id  --query 'RouteTable.RouteTableId' --output text --region $region)
echo "created private route table with ID: $private_route_table_id"
aws ec2 associate-route-table --subnet-id $private_subnet_id --route-table-id $private_route_table_id --region $region
echo "associated private route table"
aws ec2 create-route --route-table-id $private_route_table_id --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $nat_gateway_id --region $region
echo "created route for private route table"








cat <<EOL > aws_variables.txt
region="$region"
vpc_name="$vpc_name"
vpc_cidr="$vpc_cidr"
subnet_cidr_public="$subnet_cidr_public"
subnet_cidr_private="$subnet_cidr_private"
key_pair_name_web="$key_pair_name_web"
key_pair_name_db="$key_pair_name_db"
security_group_name_web="$security_group_name_web"
security_group_name_db="$security_group_name_db"
instance_type="$instance_type"
ami_id="$ami_id"
public_subnet_id="$public_subnet_id"
private_subnet_id="$private_subnet_id"
nacl_public_id="$nacl_public_id"
nacl_private_id="$nacl_private_id"
nat_gateway_id="$nat_gateway_id"
igw_id="$igw_id"
security_group_id_web="$security_group_id_web"
public_route_table_id_db="$public_route_table_id_db"
vpc_id="$vpc_id"
EOL