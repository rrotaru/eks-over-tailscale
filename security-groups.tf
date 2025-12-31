# Security groups and rules

resource "aws_security_group" "eks_cluster_sg" {
  name        = "eks-cluster-sg-main"
  description = "EKS created security group applied to ENI that is attached to EKS Control Plane master nodes, as well as any managed workloads."
  vpc_id      = aws_vpc.main.id

  tags = {
    "Name" = "eks-cluster-sg-main"
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
  referenced_security_group_id = aws_security_group.eks_cluster_sg.id
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
  name        = "vpc-ssm-endpoint-sg"
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
