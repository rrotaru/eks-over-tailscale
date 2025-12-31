# EKS cluster and related resources

resource "aws_eks_cluster" "main" {
  name     = "main"
  role_arn = aws_iam_role.eks_cluster_role.arn
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator"
  ]

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = false
    security_group_ids      = [data.aws_security_group.default.id]
    subnet_ids              = aws_subnet.main[*].id
  }

  encryption_config {
    provider {
      key_arn = data.aws_kms_key.eks_main.arn
    }
    resources = ["secrets"]
  }

  depends_on = [
    aws_iam_role.eks_cluster_role
  ]
}

resource "aws_iam_openid_connect_provider" "main" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.main.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

resource "aws_eks_addon" "eks_addon_vpc_cni" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "vpc-cni"
  service_account_role_arn = aws_iam_role.eks_vpc_cni_role.arn
}

resource "aws_eks_addon" "eks_addon_kube_proxy" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "eks_addon_pod_id" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "eks-pod-identity-agent"
}

resource "aws_eks_addon" "eks_addon_coredns" {
  cluster_name = aws_eks_cluster.main.name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "eks_addon_mountpoint_s3" {
  cluster_name             = aws_eks_cluster.main.name
  addon_name               = "aws-mountpoint-s3-csi-driver"
  service_account_role_arn = aws_iam_role.eks_s3_mountpoint_role.arn
}

resource "aws_eks_access_entry" "ec2_k8s_helper" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.ec2_ssm_role.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "ec2_k8s_helper_cluster_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.ec2_ssm_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

# EKS node groups

resource "aws_eks_node_group" "default" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "default-nodegroup"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.main[*].id

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 1
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role.eks_node_role
  ]
}
