resource "aws_vpc" "eks_ricardo_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "Name" = "${var.cluster_name}-vpc"
    "kubernetes.io/cluster/${var.cluster_name}"= "shared"
  }
}

# https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
resource "aws_subnet" "eks_ricardo_vpc_internal_subnet" {
  count = length(var.aws_availability_zones)

  availability_zone       = var.aws_availability_zones[count.index]
  cidr_block              = "10.0.${count.index}.0/24"
  map_public_ip_on_launch = false
  vpc_id                  = aws_vpc.eks_ricardo_vpc.id

  tags = {
    "Name"= "${var.cluster_name}-vpc-subnet"
    "kubernetes.io/cluster/${var.cluster_name}"= "shared"
    "kubernetes.io/role/internal-elb"= 1
  }
}

# https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
resource "aws_subnet" "eks_ricardo_vpc_public_subnet" {
  count = length(var.aws_availability_zones)

  availability_zone       = var.aws_availability_zones[count.index]
  cidr_block              = "10.0.10${count.index}.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.eks_ricardo_vpc.id

  tags = {
    "Name"= "${var.cluster_name}-vpc-subnet"
    "kubernetes.io/cluster/${var.cluster_name}"= "shared"
    "kubernetes.io/role/elb"= 1
  }
}

# Internet gateway
resource "aws_internet_gateway" "eks_ricardo_vpc_ig" {
  vpc_id = aws_vpc.eks_ricardo_vpc.id

  tags = {
    Name = "${var.cluster_name}-vpc-ig"
  }
}

# NAT Gateway
resource "aws_eip" "eks_ricardo_vpc_nat_eip" {
  tags = {
    Name = "${var.cluster_name}-vpc-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  count = length(var.aws_availability_zones)

  allocation_id = aws_eip.eks_ricardo_vpc_nat_eip.id
  subnet_id     = aws_subnet.eks_ricardo_vpc_public_subnet[count.index].id
  tags = {
    Name = "${var.cluster_name}-vpc-nat-gw"
  }

  depends_on = [ aws_internet_gateway.eks_ricardo_vpc_ig ]
}

resource "aws_route_table" "eks_ricardo_vpc_ig_table" {
  vpc_id = aws_vpc.eks_ricardo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_ricardo_vpc_ig.id
  }
}

resource "aws_route_table_association" "eks_ricardo_vpc_ig_table_internal" {
  count = length(var.aws_availability_zones)

  subnet_id      = aws_subnet.eks_ricardo_vpc_internal_subnet.*.id[count.index]
  route_table_id = aws_route_table.eks_ricardo_vpc_ig_table.id
}

resource "aws_route_table_association" "eks_ricardo_vpc_ig_table_public" {
  count = length(var.aws_availability_zones)

  subnet_id      = aws_subnet.eks_ricardo_vpc_public_subnet.*.id[count.index]
  route_table_id = aws_route_table.eks_ricardo_vpc_ig_table.id
}