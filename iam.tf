# IAM roles and policies

resource "aws_iam_role" "eks_node_role" {
  name               = "AmazonEKSNodeRole"
  description        = "Amazon EKS - Node role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_role_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  ]
}

resource "aws_iam_role" "eks_vpc_cni_role" {
  name               = "AmazonEKSVPCCNIRole"
  assume_role_policy = data.aws_iam_policy_document.eks_vpc_cni_role_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  ]
}

resource "aws_iam_policy" "eks_s3_mountpoint_policy" {
  name        = "AmazonEKS_S3_CSI_DriverPolicy"
  description = "Least privilege policy for EKS S3 CSI driver"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.eks_persistent_storage.arn,
          "${aws_s3_bucket.eks_persistent_storage.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "eks_s3_mountpoint_role" {
  name               = "AmazonEKS_S3_CSI_DriverRole"
  assume_role_policy = data.aws_iam_policy_document.eks_s3_mountpoint_role_assume_role_policy.json
  managed_policy_arns = [
    aws_iam_policy.eks_s3_mountpoint_policy.arn
  ]
}

resource "aws_iam_role" "eks_cluster_role" {
  name               = "EKSClusterRole"
  description        = "Allows access to other AWS service resources that are required to operate clusters managed by EKS."
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_role_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  ]
}

resource "aws_iam_role" "ec2_ssm_role" {
  name               = "EC2SSMRole"
  assume_role_policy = data.aws_iam_policy_document.ec2_ssm_role_assume_role_policy.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
    "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation",
  ]

}

resource "aws_iam_instance_profile" "ec2_ssm_iam_instance_profile" {
  name = "EC2SSMInstanceProfile"
  role = aws_iam_role.ec2_ssm_role.name
}
