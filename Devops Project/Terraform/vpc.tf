# -------------------- VPC --------------------
# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "project_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "project-vpc" }
}

# -------------------- Subnets --------------------
# tfsec:ignore:aws-ec2-no-public-ip-subnet
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-west-1a"
  map_public_ip_on_launch = true
  tags = { 
    Name = "public-subnet-1" 
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/project-eks" = "owned" }
}

# tfsec:ignore:aws-ec2-no-public-ip-subnet
resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = "10.0.3.0/24" 
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = true

  tags = {
    Name                                = "public-subnet-2"
    "kubernetes.io/role/elb"            = "1"
    "kubernetes.io/cluster/project-eks" = "owned"
  }
}

resource "aws_route_table_association" "public_2_assosc" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id                  = aws_vpc.project_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "eu-west-1b"
  map_public_ip_on_launch = false
  tags = { 
    Name = "private-subnet-1" 
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/project-eks" = "owned"
  }
}

# -------------------- Internet Gateway --------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.project_vpc.id
  tags = { Name = "project-igw" }
}

# -------------------- Public Route Table --------------------
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.project_vpc.id
  tags = { Name = "public-rt" }
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}

# -------------------- NAT Gateway --------------------
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id
  tags = { Name = "project-nat" }
}

# -------------------- Private Route Table --------------------
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.project_vpc.id
  tags = { Name = "private-rt" }
}

resource "aws_route" "private_internet" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_security_group_rule" "allow_nlb_to_nodes" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/16"] 
  security_group_id = aws_eks_cluster.project_eks.vpc_config[0].cluster_security_group_id
  description       = "Allow NLB to access NodePorts on worker nodes"
}