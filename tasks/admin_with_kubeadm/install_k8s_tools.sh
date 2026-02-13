#!/bin/bash
set -e

echo "--- 1. Updating system and installing dependencies ---"
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gpg

echo "--- 2. Setting up Kubernetes keyring directory ---"
sudo mkdir -p -m 755 /etc/apt/keyrings

echo "--- 3. Downloading Kubernetes GPG key ---"
# We use the latest stable v1.31 repository
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "--- 4. Adding Kubernetes repository to sources list ---"
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "--- 5. Installing the Combo: kubelet, kubeadm, kubectl ---"
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl

echo "--- 6. Freezing versions to prevent accidental updates ---"
sudo apt-mark hold kubelet kubeadm kubectl

echo "----------------------------------------------------"
echo "SUCCESS! Kubeadm, Kubelet, and Kubectl are installed."
echo "Verified versions:"
kubectl version --client --output=yaml | grep gitVersion
echo "----------------------------------------------------"
