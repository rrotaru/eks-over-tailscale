run "valid_s3_bucket_config" {

  command = plan

  assert {
    condition     = aws_s3_bucket.eks_persistent_storage.bucket == "eks-persistent-storage-mountpoint"
    error_message = "S3 bucket does not match the expected name"
  }

  assert {
    condition = aws_s3_bucket_public_access_block.private_s3_bucket_config.block_public_acls == true
    error_message = "S3 bucket does not have Block Public ACLs enabled"
  }

  assert {
    condition = aws_s3_bucket_public_access_block.private_s3_bucket_config.block_public_policy == true
    error_message = "S3 bucket does not have Block Public Policies enabled"
  }

  assert {
    condition = aws_s3_bucket_public_access_block.private_s3_bucket_config.ignore_public_acls == true
    error_message = "S3 bucket does not have Ignore Public ACLs enabled"
  }

  assert {
    condition = aws_s3_bucket_public_access_block.private_s3_bucket_config.restrict_public_buckets == true
    error_message = "S3 bucket does not have Restrict Public Buckets enabled"
  }

  assert {
    condition = length(aws_s3_bucket_server_side_encryption_configuration.encrypted_s3_bucket_config.rule) > 0
    error_message = "S3 bucket does not have server side encryption configured"
  }
}