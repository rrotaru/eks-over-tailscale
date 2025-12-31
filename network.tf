# VPC and networking resources

resource "aws_vpc" "main" {
  cidr_block = "172.31.0.0/16"

  tags = {
    "Name" = "main"
  }
}

resource "aws_network_interface" "main" {
  count           = var.aws_desired_az_num
  subnet_id       = aws_subnet.main.*.id[count.index]
  security_groups = [data.aws_security_group.default.id]
}

resource "aws_subnet" "main" {
  count                   = var.aws_desired_az_num
  vpc_id                  = aws_vpc.main.id
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = "172.31.${count.index * 16}.0/20"
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "main_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
}

resource "aws_route_table_association" "main_rt" {
  count = var.aws_desired_az_num

  subnet_id      = aws_subnet.main.*.id[count.index]
  route_table_id = aws_route_table.main_rt.id
}

resource "aws_vpc_endpoint" "ssm_endpoint" {
  for_each = toset([
    "ssm",
    "ec2",
    "kms",
    "logs",
    "ssmmessages",
    "ec2messages"
  ])

  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = aws_subnet.main[*].id
  security_group_ids = [
    aws_security_group.ssm_endpoint.id
  ]
}
