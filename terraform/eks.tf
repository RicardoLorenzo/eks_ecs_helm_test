# EKS Role
resource "aws_iam_role" "eks_ricardo_role" {
  name = "${var.cluster_name}-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_ricardo_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_ricardo_role.name
}

# Required for OpenID
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "eks_ricardo_vpc_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_ricardo_role.name
}

# EKS cluster
resource "aws_eks_cluster" "eks_ricardo" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_ricardo_role.arn

  vpc_config {
    subnet_ids = setunion(aws_subnet.eks_ricardo_vpc_internal_subnet[*].id, aws_subnet.eks_ricardo_vpc_public_subnet[*].id)
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Cluster handling.
  # Otherwise, EKS will not be able to properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.eks_ricardo_policy,
    aws_iam_role_policy_attachment.eks_ricardo_vpc_policy,
  ]
}
