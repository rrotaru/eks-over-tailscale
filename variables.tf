

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

  validation {
    condition     = var.aws_desired_az_num >= 2 && var.aws_desired_az_num <= 6
    error_message = "Must specify between 2 and 6 availability zones"
  }
}

# Tailscale provider vars

variable "tailscale_oauth_client_id" {
  description = "OAuth client credentials to your tailnet"
  type        = string
}

variable "tailscale_oauth_client_secret" {
  description = "OAuth client credentials to your tailnet"
  type        = string
}

# EC2 vars

variable "ec2_helper_ami_id" {
  description = "AMI ID for the EC2 helper instance"
  type        = string
  default     = "ami-09b90e09742640522"
}