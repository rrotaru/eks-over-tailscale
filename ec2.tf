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
  user_data = templatefile("${path.module}/userdata.tpl", {
    aws_account       = var.aws_account,
    aws_region        = var.aws_region,
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
