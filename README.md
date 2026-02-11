# Project

The objective of this project is to develop the tutorials in the official documentation of Kubernetes.

# To improve


## Preliminaries

You will normally require a very demanding infrastructure when administering a cluster with *kubeadm*, in that case you can use the infrastructure defined in `tasks/infrastructure/main.tf`.

# Administer a cluster

## Administering with kubeadm

### Installing kubeadm

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

- Paste the file setup-k8s.sh in the main node.
- Change permissions `chmod +x setup-k8s.sh`
- Generate containerd default configuration (Amazon Linux sometimes creates it differently)

    `sudo mkdir -p /etc/containerd`
    
    `containerd config default | sudo tee /etc/containerd/config.toml`

- Configure the `SystemdCgroup`

    `sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml`

- Restart Containerd

    `sudo systemctl restart containerd`

    `sudo systemctl enable containerd`

- Execute the script `./setup-k8s.sh`

### Creating cluster with kubeadm

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

#### Objectives
- Install a single control plane K8s cluster
- Install a Pod network in the cluster so that the Pods can talk to each other

#### Steps

- Initialize your contorl plane node 

    `sudo kubectl init`

## Author


[Camilo Nuñez](https://github.com/camillonunez1998)


## License


[MIT](./LICENSE)