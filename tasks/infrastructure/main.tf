# --- Variables and provider ---
provider "aws" {
  region = "eu-north-1"
}

variable "instance_type_master" { default = "t3.medium" } # 2 vCPUs, 4 GB RAM
variable "instance_type_worker" { default = "t3.small" } # 2 GB RAM
variable "ami_id"               { default = "ami-02e70da87e10e9324"} # Ubuntu AMI

# --- Network Resources ---

# 1. The VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "k8s-vpc" }
}

# 2. Public Subnet
resource "aws_subnet" "k8s_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true # Ensures instances get public IPs
  availability_zone       = "eu-north-1a"
  tags = { Name = "k8s-subnet" }
}

# 3. Internet Gateway
resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id
  tags   = { Name = "k8s-igw" }
}

# 4. Route Table
resource "aws_route_table" "k8s_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_igw.id
  }
}

# 5. Associate Route Table with Subnet
resource "aws_route_table_association" "k8s_rta" {
  subnet_id      = aws_subnet.k8s_subnet.id
  route_table_id = aws_route_table.k8s_rt.id
}

# --- Security Group ---

resource "aws_security_group" "k8s_sg" {
  name        = "k8s-cluster-sg"
  description = "Permit SSH and inner traffic within the cluster"
  vpc_id      = aws_vpc.k8s_vpc.id # Crucial: Point to the new VPC

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
# Full network connectivity between all the nodes in the cluster  
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Key Pair ---
resource "aws_key_pair" "daily-key" {
  key_name   = "daily-key"
  public_key = file("~/.ssh/daily-key.pub")
}

# --- EC2 instances (Updated with subnet_id) ---

resource "aws_instance" "master" {
  ami                    = var.ami_id
  instance_type          = var.instance_type_master
  key_name               = aws_key_pair.daily-key.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  subnet_id              = aws_subnet.k8s_subnet.id # Launch in new subnet

  tags = { Name = "k8s-master" }
}

resource "aws_instance" "workers" {
  count                  = 2
  ami                    = var.ami_id
  instance_type          = var.instance_type_worker
  key_name               = aws_key_pair.daily-key.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
  subnet_id              = aws_subnet.k8s_subnet.id # Launch in new subnet

  tags = { Name = "k8s-worker-${count.index}" }
}

# --- Outputs ---
output "master_public_ip" { value = aws_instance.master.public_ip }
output "worker_public_ips" { value = aws_instance.workers[*].public_ip }