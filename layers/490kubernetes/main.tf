/*

490kubernetes - main.tf

Required layers:
000base

Required modules:
****TBC****

*/

locals {
  tags = {
    environment = var.environment
    layer       = var.layer
    terraform   = "true"
  }
}


## ----------------------------------
## EKS IAM role

resource "aws_iam_role" "eks_role" {
  name               = "MyEKSRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": {
    "Effect": "Allow",
    "Principal": {"Service": "eks.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }
}
EOF
}

resource "aws_iam_role_policy_attachment" "ssmrole_attach" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

## ----------------------------------
## EKS Cluster

resource "aws_eks_cluster" "test_eks_cluster" {
  name     = "test_eks_cluster"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = data.terraform_remote_state.state_000base.outputs.subnet_private
  }
}

## ----------------------------------
## EKS Cluster Node Group IAM role

resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group_role.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group_role.name
}

## ----------------------------------
## EKS Cluster Node Latest AMI

data "aws_ssm_parameter" "eks_ami_release_version" {
  name = "/aws/service/eks/optimized-ami/${aws_eks_cluster.test_eks_cluster.version}/amazon-linux-2/recommended/release_version"
}


## ----------------------------------
## EKS Cluster Node Group

resource "aws_eks_node_group" "test_eks_cluster_node_group" {
  cluster_name    = aws_eks_cluster.test_eks_cluster.name
  node_group_name = "test_eks_cluster_node_group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = data.terraform_remote_state.state_000base.outputs.subnet_private
  release_version = nonsensitive(data.aws_ssm_parameter.eks_ami_release_version.value)
  instance_types = [
    "t3.medium"
  ]
  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 2
  }

  update_config {
    max_unavailable = 1
  }

}