## create a VPC  

resource "aws_vpc" "lamp_vpc" {
  cidr_block       = var.vpc_cidr_block
  instance_tenancy = "default"

  tags = {
    Name = "${var.env_prefix}-lamp_vpc"
  }
}

## Create 2 public subnets and 2 private subnets accross two availability zones
resource "aws_subnet" "public_subnets" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.lamp_vpc.id
  cidr_block        = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "${var.env_prefix}-Public subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.lamp_vpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "${var.env_prefix}-Private subnet ${count.index + 1}"
  }
}

## Create Internet gateway
resource "aws_internet_gateway" "lamp_vpc_igw" {
  vpc_id = aws_vpc.lamp_vpc.id

  tags = {
    Name = "${var.env_prefix}-IGW"
  }
}

## Create NAT Gateway Elastic IP
resource "aws_eip" "lamp_vpc_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.env_prefix}-NAT-EIP"
  }
}

## Create NAT Gateway
resource "aws_nat_gateway" "lamp_vpc_natgw" {
  allocation_id = aws_eip.lamp_vpc_nat_eip.id
  subnet_id     = element(aws_subnet.public_subnets[*].id, 0) # Place NAT in the first public subnet

  tags = {
    Name = "${var.env_prefix}-NATGW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.lamp_vpc_igw]
}


## Create route table for public subnets
resource "aws_route_table" "lamp_vpc_public_rt" {
  vpc_id = aws_vpc.lamp_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.lamp_vpc_igw.id
  }


  tags = {
    Name = "${var.env_prefix}-Public-RT"
  }
}

# Create route table associations with public subnets

resource "aws_route_table_association" "lamp_vpc_public_asso" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
  route_table_id = aws_route_table.lamp_vpc_public_rt.id
}


# Create route table for private subnets (using NAT Gateway)
resource "aws_route_table" "lamp_vpc_private_rt" {
  vpc_id = aws_vpc.lamp_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.lamp_vpc_natgw.id
  }

  tags = {
    Name = "${var.env_prefix}-Private-RT"
  }
}

## Associate route table with private subnets
resource "aws_route_table_association" "lamp_vpc_private_asso" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
  route_table_id = aws_route_table.lamp_vpc_private_rt.id
}


# ssh key-pair
resource "aws_key_pair" "ssh-key" {
  key_name   = "gitpod_ec2_key"
  public_key = file(var.public_key_location)

  tags = {
    Name = "${var.env_prefix}-key-pair"
  }
}

# Application Load balancer for EC2 instances

resource "aws_lb" "lamp_server_alb" {
  name               = "${var.env_prefix}-lamp_server_alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = aws_subnet.public_subnets[*].id

 

  tags = {
    Name = "${var.env_prefix}-lamp_server_alb"
  }
}


# # ALB Security Group

# resource "aws_security_group" "lamp_server_albsg" {
#   name   = "${var.env_prefix}-lamp_server_albsg"
#   description = "Security group for ALB"
#   vpc_id = aws_vpc.lamp_vpc.id


#   # Dynamic ingress rule for HTTP/HTTPS from anywhere
#   dynamic "ingress" {
#     for_each = var.ingress_ports
#     content {
#       description = "Allow traffic on port ${ingress.value}"
#       from_port   = ingress.value
#       to_port     = ingress.value
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }

#   egress {
#     description = "Allows traffic to EC2 instances"
#     from_port   = 0
#     to_port     = 65535
#     protocol    = "tcp"
#     security_groups = [aws_security_group.lamp_server_sg.id]
#   }

#   tags = {
#     Name = "${var.env_prefix}-lamp_server_albsg"
#   }
# }

# # EC2 Security group
# resource "aws_security_group" "lamp_server_sg" {
#   description = "Security group for EC2 instances"
#   name   = "${var.env_prefix}-lamp_server_sg"
#   vpc_id = aws_vpc.lamp_vpc.id

#   # Allow traffic from Alb security group
#   ingress {
#     description = "Allow traffic from ALB"
#     from_port   = 0
#     to_port     = 65535
#     protocol    = "tcp"
#     security_groups = [aws_security_group.lamp_server_albsg]
#   }

#   ingress {
#   description = "Allow SSH access for maintenance"
#   from_port   = 22
#   to_port     = 22
#   protocol    = "tcp"
#   cidr_blocks = [var.specific_ssh_ip]  # Replace with your office, VPN, or bastion IP
# }

# # Egress rule to allow traffic to RDS 
# egress {
#   description    = "Allow traffic to RDS"
#   from_port      = 5432  # PostgreSQL (or 3306 for MySQL)
#   to_port        = 5432
#   protocol       = "tcp"
#   security_groups = [aws_security_group.rds_sg.id]  
# }
 
#   # Dynamic egress rule for specific ports 
#   dynamic "egress" {
#     for_each = var.egress_ports
#     content {
#       description = "Allow traffic on port ${egress.value}"
#       from_port   = egress.value
#       to_port     = egress.value
#       protocol    = "tcp"
#       cidr_blocks = ["0.0.0.0/0"]
#     }
#   }

#   tags = {
#     Name = "${var.env_prefix}-lamp_server_sg"
#   }
# }
