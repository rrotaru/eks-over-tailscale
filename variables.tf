

# AWS provider vars

variable "aws_account" {
  description = "AWS account"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "aws_sso_login_url" {
  description = "AWS SSO Login start page"
  type        = string
}

variable "aws_desired_az_num" {
  description = "Desired number of availability zones to use"
  type        = number
  default     = 3
}

# Tailscale provider vars

variable "tailscale_oauth_client_id" {
  description = "OAuth client credentails to your tailnet"
  type        = string
}

variable "tailscale_oauth_client_secret" {
  description = "OAuth client credentails to your tailnet"
  type        = string
}