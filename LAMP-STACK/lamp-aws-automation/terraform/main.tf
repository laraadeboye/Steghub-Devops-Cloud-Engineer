## create a VPC  

resource "aws_vpc" "lampVPC" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "${var.env_prefix}-lampVPC"
  }
}

## Create 2 public subnets and 2 private subnets accross two availability zones
resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.lampVPC.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "${var.env_prefix}-Public subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.lampVPC.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "${var.env_prefix}-Private subnet ${count.index + 1}"
  }
}

## Create Internet gateway
resource "aws_internet_gateway" "lampVPC_IGW" {
  vpc_id = aws_vpc.lampVPC.id

  tags = {
    Name = "${var.env_prefix}-IGW"
  }
}

## Create NAT Gateway Elastic IP
resource "aws_eip" "lampVPC_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.env_prefix}-NAT-EIP"
  }
}

## Create NAT Gateway
resource "aws_nat_gateway" "lampVPC_NATGW" {
  allocation_id = aws_eip.lampVPC_nat_eip.id
  subnet_id     = element(aws_subnet.public_subnets[*].id, 0) # Place NAT in the first public subnet

  tags = {
    Name = "${var.env_prefix}-NAT-GW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.lampVPC_IGW]
}


## Create route table for public subnets
resource "aws_route_table" "lampVPC_public_rt" {
  vpc_id = aws_vpc.lampVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lampVPC_IGW.id
  }


  tags = {
    Name = "${var.env_prefix}-Public-RT"
  }
}

# Create route table associations with public subnets

resource "aws_route_table_association" "lampVPC_public_asso" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.lampVPC_public_rt.id
}


# Create route table for private subnets (using NAT Gateway)
resource "aws_route_table" "lampVPC_private_rt" {
  vpc_id = aws_vpc.lampVPC.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lampVPC_NATGW.id
  }

  tags = {
    Name = "${var.env_prefix}-Private-RT"
  }
}

## Associate route table with private subnets
resource "aws_route_table_association" "lampVPC_private_asso" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  route_table_id = aws_route_table.lampVPC_private_rt.id
}


# Security group

resource "aws_security_group" "lampServer-SG" {
  name   = "${var.env_prefix}-lampServer-SG"
  vpc_id = aws_vpc.lampVPC.id

  # Static ingress rule for SSH from a specific IP
  ingress {
    description = "Allow SSH from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.specific_ssh_ip]
  }

  # Dynamic ingress rule for SSH from a specific IP
  dynamic "ingress" {
    for_each = var.ports
    content {
      description = "Allow traffic on port ${ingress.value}"
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allows all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_prefix}-lampServer-SG"
  }
}

# ssh key-pair
resource "aws_key_pair" "ssh-key" {
  key_name   = "gitpod_ec2_key"
  public_key = file(var.public_key_location)

  tags = {
    Name = "${var.env_prefix}-key-pair"
  }
}