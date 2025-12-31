# Outputs

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "eks_cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.eks_cluster_sg.id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "subnet_ids" {
  description = "List of subnet IDs"
  value       = aws_subnet.main[*].id
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for EKS persistent storage"
  value       = aws_s3_bucket.eks_persistent_storage.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket for EKS persistent storage"
  value       = aws_s3_bucket.eks_persistent_storage.arn
}

output "ec2_helper_instance_id" {
  description = "ID of the EC2 helper instance"
  value       = aws_instance.k8s_helper.id
}

output "oidc_provider_arn" {
  description = "ARN of the OIDC provider for EKS"
  value       = aws_iam_openid_connect_provider.main.arn
}
