resource "aws_iam_role" "eks_ricardo_node_role" {
  name = "${var.cluster_name}-node-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_ricardo_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_ricardo_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_ricardo_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_ricardo_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_ricardo_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_ricardo_node_role.name
}

resource "aws_eks_node_group" "eks_ricardo_ng" {
  cluster_name    = aws_eks_cluster.eks_ricardo.name
  node_group_name = "${var.cluster_name}-ng"
  node_role_arn   = aws_iam_role.eks_ricardo_role.arn
  subnet_ids      = setunion(aws_subnet.eks_ricardo_vpc_internal_subnet[*].id, aws_subnet.eks_ricardo_vpc_public_subnet[*].id)
  instance_types  = ["t2.micro"]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.eks_ricardo_node_policy,
    aws_iam_role_policy_attachment.eks_ricardo_cni_policy,
    aws_iam_role_policy_attachment.eks_ricardo_registry_policy,
  ]
}
