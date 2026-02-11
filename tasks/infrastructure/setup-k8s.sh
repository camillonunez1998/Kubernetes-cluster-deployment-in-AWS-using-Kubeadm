#!/bin/bash
set -e

echo "1. Configurando el repositorio de Kubernetes..."
cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.30/rpm/repodata/repomd.xml.key
EOF

echo "2. Instalando kubeadm, kubelet y kubectl..."
sudo yum clean all
sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

echo "3. Cargando módulos del kernel..."
sudo modprobe overlay
sudo modprobe br_netfilter

echo "4. Configurando sysctl..."
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sudo sysctl --system

echo "5. Habilitando kubelet..."
sudo systemctl enable --now kubelet

echo "6. ¡Listo! Ya puedes correr kubeadm init."
