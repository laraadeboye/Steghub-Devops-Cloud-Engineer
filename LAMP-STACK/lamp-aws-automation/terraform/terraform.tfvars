region               = "us-east-1"
vpc_cidr_block       = "10.0.0.0/16"
env_prefix           = "dev"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.3.0/24", "10.0.4.0/24"]
azs                  = ["us-east-1a", "us-east-1c"]
ingress_ports        = [80, 443]
egress_ports         = [80, 443]
specific_ssh_ip      = "35.205.10.137/32"
public_key_location  = "keys/gitpod_ec2_key.pub"
ami_id               = "ami-0e86e20dae9224db8"
instance_type        = "t2.micro"
db_password          = "password123#"
db_username          = "lampdbadmin"