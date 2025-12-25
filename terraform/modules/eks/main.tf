locals {
  cluster_name = var.cluster_name
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "${local.cluster_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_security_group" "eks_cluster_sg" {
  name        = "${local.cluster_name}-cluster-sg"
  description = "EKS cluster security group"
  vpc_id      = var.vpc_id

  # Allow Prometheus to scrape node-exporter on port 9100
  ingress {
    description = "Allow Prometheus to scrape node-exporter from VPC"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eks_cluster" "this" {
  name     = local.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSVPCResourceController,
  ]
}

# Node group
resource "aws_iam_role" "eks_node_role" {
  name = "${local.cluster_name}-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
  node_group_name = "${local.cluster_name}-ng"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.subnet_ids

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  instance_types = [var.node_instance_type]
  disk_size      = var.node_disk_size

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
  ]
}

# Data source to find the auto-created security group for the node group
# EKS automatically creates a security group with specific tags
data "aws_security_groups" "eks_node_sg" {
  filter {
    name   = "tag:aws:eks:cluster-name"
    values = [aws_eks_cluster.this.name]
  }

  filter {
    name   = "tag:kubernetes.io/cluster/${aws_eks_cluster.this.name}"
    values = ["owned"]
  }

  depends_on = [aws_eks_node_group.this]
}

# Local to safely get the security group ID
locals {
  eks_node_sg_id = length(data.aws_security_groups.eks_node_sg.ids) > 0 ? data.aws_security_groups.eks_node_sg.ids[0] : null
}

# Add security group rule to allow Prometheus to scrape node-exporter
resource "aws_security_group_rule" "eks_node_prometheus_sg" {
  count                    = local.eks_node_sg_id != null ? 1 : 0
  type                     = "ingress"
  from_port                = 9100
  to_port                  = 9100
  protocol                 = "tcp"
  source_security_group_id = var.prometheus_security_group_id
  security_group_id        = local.eks_node_sg_id
  description              = "Allow Prometheus to scrape node-exporter"
}

# Also allow from VPC CIDR as fallback
resource "aws_security_group_rule" "eks_node_prometheus_cidr" {
  count             = local.eks_node_sg_id != null ? 1 : 0
  type              = "ingress"
  from_port         = 9100
  to_port           = 9100
  protocol          = "tcp"
  cidr_blocks       = [var.vpc_cidr_block]
  security_group_id = local.eks_node_sg_id
  description       = "Allow node-exporter from VPC"
}

# Allow NodePort 30007 for Netflix frontend access from internet
resource "aws_security_group_rule" "eks_node_nodeport_frontend" {
  count             = local.eks_node_sg_id != null ? 1 : 0
  type              = "ingress"
  from_port         = 30007
  to_port           = 30007
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = local.eks_node_sg_id
  description       = "Allow NodePort 30007 for Netflix frontend access"
}

# Allow NodePort 30008 for Netflix backend access from internet
resource "aws_security_group_rule" "eks_node_nodeport_backend" {
  count             = local.eks_node_sg_id != null ? 1 : 0
  type              = "ingress"
  from_port         = 30008
  to_port           = 30008
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = local.eks_node_sg_id
  description       = "Allow NodePort 30008 for Netflix backend access"
}

resource "aws_security_group_rule" "eks_node_nodeport_node_exporter" {
  count             = local.eks_node_sg_id != null ? 1 : 0
  type              = "ingress"
  from_port         = 30100
  to_port           = 30100
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = local.eks_node_sg_id
  description       = "Allow NodePort 30100 for node-exporter access"
}

