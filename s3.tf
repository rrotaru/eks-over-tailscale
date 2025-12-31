# S3 bucket for EKS persistent storage

resource "aws_s3_bucket" "eks_persistent_storage" {
  bucket = "eks-persistent-storage-mountpoint"
}

resource "aws_s3_bucket_public_access_block" "private_s3_bucket_config" {
  bucket = aws_s3_bucket.eks_persistent_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypted_s3_bucket_config" {
  bucket = aws_s3_bucket.eks_persistent_storage.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
  }
}
