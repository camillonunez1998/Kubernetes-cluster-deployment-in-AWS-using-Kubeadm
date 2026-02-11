# --- Variables and provider ---
provider "aws" {
  region = "eu-north-1"
}

variable "instance_type_master" { default = "t3.medium" }
variable "instance_type_worker" { default = "t3.small" }
variable "ami_id"               { default = "ami-02781fbdc79017564" } 

# Block to upload the public key to AWS for ssh conection
resource "aws_key_pair" "daily-key" {# Local name
  key_name   = "daily-key"# Physical name
  public_key = file("~/.ssh/daily-key.pub") # Tu ruta local
}

# --- Security group ---
resource "aws_security_group" "k8s_sg" {
  name        = "k8s-cluster-sg"
  description = "Permit SSH and inner traffic within the cluster "

  # SSH for the sysadmin
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Complete inner traffic among the nodes of the cluster
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # Allows the use of kubectl from the outside
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

# --- EC2 instances ---

# Nodo Control Plane (Master)
resource "aws_instance" "master" {
  ami           = var.ami_id
  instance_type = var.instance_type_master
  key_name      = "daily-key"
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]


  tags = { Name = "k8s-master" }
}

# Nodos Worker
resource "aws_instance" "workers" {
  count         = 2
  ami           = var.ami_id
  instance_type = var.instance_type_worker
  key_name      = "daily-key"
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  tags = { Name = "k8s-worker-${count.index}" }
}

# --- 5. Outputs ---
output "master_public_ip" { value = aws_instance.master.public_ip }
output "worker_public_ips" { value = aws_instance.workers[*].public_ip }
