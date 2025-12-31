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

data "aws_iam_policy_document" "eks_s3_mountpoint_role_assume_role_policy" {
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
  vpc_id = aws_vpc.main.id

  filter {
    name   = "group-name"
    values = ["default"]
  }
}

# EKS

data "tls_certificate" "main" {
  url = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# EC2

data "aws_ami" "linux" {
  owners      = ["amazon"]
  most_recent = true

  filter {
    name   = "image-id"
    values = [var.ec2_helper_ami_id]
  }
}

# Tailscale data

data "tailscale_acl" "network_acl" {}

data "tailscale_device" "eks_operator" {
  hostname = "tailscale-operator"
}