# IAM roles

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
    "arn:aws:iam::aws:policy/AdministratorAccess" # warning! this is highly privileged and only to be used temporarily
  ]

}

resource "aws_iam_instance_profile" "ec2_ssm_iam_instance_profile" {
  name = "EC2SSMInstanceProfile"
  role = aws_iam_role.ec2_ssm_role.name
}

# VPC 

resource "aws_vpc" "main" {
  cidr_block = "172.31.0.0/16"

  tags = {
    "Name" = "main"
  }
}

resource "aws_subnet" "main" {
  count                   = var.aws_desired_az_num
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "172.31.${count.index * 16}.0/20"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main-rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }
}

resource "aws_route_table_association" "main-rt" {
  count = var.aws_desired_az_num

  subnet_id      = aws_subnet.main.*.id[count.index]
  route_table_id = aws_route_table.main-rt.id
}

resource "aws_vpc_endpoint" "ssm_endpoint" {
  for_each = toset([
    "ssm",
    "ec2",
    "kms",
    "logs",
    "ssmmessages",
    "ec2messages"
  ])

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.main[*].id
  security_group_ids = [
    aws_security_group.ssm_endpoint.id
  ]
}

# EKS cluster

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

resource "aws_eks_access_entry" "ec2_k8s_helper" {
  cluster_name      = aws_eks_cluster.main.name
  principal_arn     = aws_iam_role.ec2_ssm_role.arn
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "ec2_k8s_helper_cluster_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.ec2_ssm_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type       = "cluster"
  }
}

# EC2 nodegroups

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

# EC2 helper instance

# To first set up the tailscale k8s operator, we'll need some way to connect 
# to the cluster in the first place, since we have opted to set our control 
# plane API to private access. The simplest way to do this is by connecting 
# via SSM to an EC2 on the private VPC and granting that EC2 access to the
# k8s control plane via security groups and IAM policies.
resource "aws_instance" "k8s_helper" {
  ami                  = data.aws_ami.linux.id
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_ssm_iam_instance_profile.id
  user_data            = templatefile("${path.module}/userdata.tpl", {
    aws_account = var.aws_account,
    aws_region = var.aws_region,
    aws_sso_login_url = var.aws_sso_login_url
  })

  security_groups = [
    aws_security_group.ec2_ssm_sg.name
  ]

  tags = {
    Name = "k8s-helper-instance"
  }

  depends_on = [
    aws_iam_role.ec2_ssm_role
  ]
}

# Security groups

resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg-main-3343801"
  description = "EKS created security group applied to ENI that is attached to EKS Control Plane master nodes, as well as any managed workloads."
  vpc_id      = aws_vpc.main.id

  tags = {
    "Name" = "eks-cluster-sg-main-3343801"
  }
}

resource "aws_vpc_security_group_egress_rule" "eks_cluster_sg_rule_allow_all_outbound" {
  security_group_id = aws_security_group.eks_cluster_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "eks_cluster_sg_rule_allow_self_inbound" {
  security_group_id            = aws_security_group.eks_cluster_sg.id
  ip_protocol                  = "-1"
  referenced_security_group_id = "sg-09522919c060f28fd"
}

resource "aws_vpc_security_group_ingress_rule" "eks_cluster_sg_rule_allow_ec2_helper_inbound" {
  security_group_id            = aws_security_group.eks_cluster_sg.id
  ip_protocol                  = "-1"
  referenced_security_group_id = aws_security_group.ec2_ssm_sg.id
}

resource "aws_security_group" "ec2_ssm_sg" {
  name        = "k8s-helper-instance-sg"
  description = "Security group for EC2 helper instance"
  vpc_id      = aws_vpc.main.id

}

resource "aws_vpc_security_group_egress_rule" "ec2_ssm_sg_rule_allow_all_outbound" {
  security_group_id = aws_security_group.ec2_ssm_sg.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "ssm_endpoint" {
  name        = "vps-ssm-endpoint-sg"
  description = "Allow inbound TCP/443 traffic from our VPC"
  vpc_id      = aws_vpc.main.id
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_ssm_allow_inbound_443" {
  security_group_id = aws_security_group.ssm_endpoint.id
  ip_protocol       = "tcp"
  cidr_ipv4         = "172.31.0.0/16"
  to_port           = 443
  from_port         = 443
}

# Tailscale

resource "tailscale_acl" "main" {
  acl = file("${path.module}/tailscale-acl.jsonc")
}