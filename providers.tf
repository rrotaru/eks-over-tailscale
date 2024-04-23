provider "aws" {
  region = var.aws_region
  assume_role {
    role_arn = "arn:aws:iam::${var.aws_account}:role/TerraformCLI"
  }

  ignore_tags {
    key_prefixes = [
      "kubernetes.io/",
      "alpha.eksctl.io/",
      "eksctl.cluster.k8s.io/",
      "AMPAgentlessScraper"
    ]
  }
}

provider "tailscale" {
  oauth_client_id     = var.tailscale_oauth_client_id
  oauth_client_secret = var.tailscale_oauth_client_secret
}