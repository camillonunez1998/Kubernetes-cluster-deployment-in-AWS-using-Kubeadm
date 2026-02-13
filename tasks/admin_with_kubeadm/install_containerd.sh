#!/bin/bash
set -e

echo "--- 1. Loading Kernel Modules ---"
sudo modprobe overlay
sudo modprobe br_netfilter
cat <<EOF_K8S | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF_K8S

echo "--- 2. Setting up Networking ---"
cat <<EOF_SYS | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF_SYS
sudo sysctl --system

echo "--- 3. Installing containerd ---"
sudo apt-get update
sudo apt-get install -y containerd

echo "--- 4. Configuring SystemdCgroup ---"
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

echo "--- 5. Restarting Service ---"
sudo systemctl restart containerd
sudo systemctl enable containerd

echo "DONE! Check status with: systemctl status containerd"
