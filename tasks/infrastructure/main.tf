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

# --- 3. Script de Inicialización (User Data) ---
# Este script prepara el OS, instala containerd v1.35 y las herramientas de K8s
locals {
  k8s_setup = <<-EOF
              #!/bin/bash
              # Desactivar Swap
              swapoff -a
              sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

              # Modulos del Kernel
              cat <<EOT | tee /etc/modules-load.d/k8s.conf
              overlay
              br_netfilter
              EOT
              modprobe overlay
              modprobe br_netfilter

              # Sysctl params
              cat <<EOT | tee /etc/sysctl.d/k8s.conf
              net.bridge.bridge-nf-call-iptables  = 1
              net.bridge.bridge-nf-call-ip6tables = 1
              net.ipv4.ip_forward                 = 1
              EOT
              sysctl --system

              # Containerd con SystemdCgroup
              apt-get update && apt-get install -y containerd
              mkdir -p /etc/containerd
              containerd config default | tee /etc/containerd/config.toml
              sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml
              systemctl restart containerd

              # Instalar Kubeadm, Kubelet y Kubectl (v1.35)
              apt-get update && apt-get install -y apt-transport-https ca-certificates curl gpg
              mkdir -p /etc/apt/keyrings
              curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
              echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /' | tee /etc/apt/sources.list.d/kubernetes.list
              apt-get update
              apt-get install -y kubelet kubeadm kubectl
              apt-mark hold kubelet kubeadm kubectl
              EOF
}

# --- EC2 instances ---

# Nodo Control Plane (Master)
resource "aws_instance" "master" {
  ami           = var.ami_id
  instance_type = var.instance_type_master
  key_name      = "daily-key"
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  user_data = local.k8s_setup

  tags = { Name = "k8s-master" }
}

# Nodos Worker
resource "aws_instance" "workers" {
  count         = 2
  ami           = var.ami_id
  instance_type = var.instance_type_worker
  key_name      = "daily-key"
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  user_data = local.k8s_setup

  tags = { Name = "k8s-worker-${count.index}" }
}

# --- 5. Outputs ---
output "master_public_ip" { value = aws_instance.master.public_ip }
output "worker_public_ips" { value = aws_instance.workers[*].public_ip }
