# IAM

data "aws_iam_policy_document" "eks_node_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

locals {
  oidc_url = replace(aws_iam_openid_connect_provider.main.url, "https://", "")
}

data "aws_iam_policy_document" "eks_vpc_cni_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]


    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_url}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.main.arn]
    }
  }
}

data "aws_iam_policy_document" "eks_cluster_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "ec2_ssm_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# KMS

data "aws_kms_key" "eks_main" {
  key_id = "alias/eks_main"
}

# Networking

data "aws_availability_zones" "available" {}

# Security Groups

data "aws_security_group" "default" {
  id = "********"
}

# EKS

data "aws_eks_cluster" "main_eks" {
  name = "main"
}

data "aws_eks_node_group" "main_eks_nodegroup" {
  cluster_name    = "main"
  node_group_name = "default-nodegroup"
}

data "tls_certificate" "main" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# EC2

data "aws_ami" "linux" {
  owners      = ["amazon"]
  most_recent = true

  # todo: leverage the latest amazon linux 2023 image
  # filter {
  #   name   = "name"
  #   values = ["al2023-ami-*"]
  # }

  filter {
    name   = "image-id"
    values = ["ami-09b90e09742640522"]
  }
}

# Tailscale data

data "tailscale_acl" "network_acl" {}

data "tailscale_device" "eks_operator" {
  hostname = "tailscale-operator"
}