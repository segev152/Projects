# -------------------- Security Groups --------------------
resource "aws_security_group" "eks_nodes_sg" {
  name        = "eks-nodes-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.project_vpc.id

  ingress {
    description = "Allow nodes to communicate with cluster"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description = "Allow nodes to reach API server"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Allow control plane to communicate with nodes"
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    description = "Allow ELB to access Kubernetes NodePorts"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # tfsec:ignore:aws-ec2-no-public-egress-sgr
  egress {
    description = "Allow outbound traffic for image pulling and updates"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-nodes-sg"
  }
}

# -------------------- EKS Cluster --------------------
# tfsec:ignore:aws-eks-no-public-cluster-access
# tfsec:ignore:aws-eks-no-public-cluster-access-to-cidr
# tfsec:ignore:aws-eks-encrypt-secrets
resource "aws_eks_cluster" "project_eks" {
  name     = "project-eks"
  role_arn = aws_iam_role.eks_cluster_role.arn

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids = [
      aws_subnet.public_subnet_1.id,
      aws_subnet.public_subnet_2.id, 
    ]
    
    endpoint_public_access  = true
    endpoint_private_access = true
  }
}

# -------------------- EKS Addons --------------------
resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.project_eks.name
  addon_name   = "coredns"
  
  depends_on   = [aws_eks_node_group.primary]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.project_eks.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.project_eks.name
  addon_name   = "vpc-cni"
}

# -------------------- Node Group --------------------
resource "aws_eks_node_group" "primary" {
  cluster_name    = aws_eks_cluster.project_eks.name
  node_group_name = "primary"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = [aws_subnet.private_subnet_1.id]
  
  scaling_config {
    desired_size = 3
    min_size     = 3
    max_size     = 4
  }

  instance_types = ["t3.micro"] 
  capacity_type  = "ON_DEMAND"

  depends_on = [
    aws_iam_role_policy_attachment.node_group_policy,
    aws_iam_role_policy_attachment.node_cni_policy,
    aws_iam_role_policy_attachment.node_registry_policy,
    aws_nat_gateway.nat,
    aws_route.private_internet,
    aws_route_table_association.private_assoc
  ]
}