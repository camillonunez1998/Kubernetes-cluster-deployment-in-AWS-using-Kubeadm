# Project

The objective of this project is to develop the tutorials in the official documentation of Kubernetes.

# To improve

- Definir una VPC propia.

## Preliminaries

You will normally require a very demanding infrastructure when administering a cluster with *kubeadm*, in that case you can use the infrastructure defined in `tasks/infrastructure/main.tf`.

# Administer a cluster

## Administering with kubeadm

### Installing kubeadm

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

- Check the MAC address of each node with `ip link show ens5` (or the name of the network interface indicated in the welcome banner of the ssh connection). You will obtian a number like *06:2b:c0:02:56:93*.

- Check the product_UUID with `sudo cat /sys/class/dmi/id/product_uuid`. All the MACs and product_UUID's must be different.

- To disable Swap memory use `sudo swapoff -a`, although normally it is disabled by default. You can check it with `swapon --show`, if there is no answer swap is off.

- Run the script `./admin_with_kubeadm/install_containerd.sh` in the main node to install the container runtime. Use `chmod +x install_containerd.sh` and `sudo bash install_containerd.sh` (or just `./install_containerd.sh`) to allow execution and execute respectively. Do it in every node.

- Run the script `./admin_with_kubeadm/install_k8s_tools.sh` in every node to install the combo *kubectl + kubelet + kubeadm*.

- Configure a *cgroup driver*: We need to make sure te container runtime and the kubelet component match the *cgroup* driver.

### Creating cluster with kubeadm

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

#### Install a single control plane K8s cluster

- Initialize your control plane node 

    `sudo kubectl init`


#### Install a Pod network in the cluster so that the Pods can talk to each other

## Author


[Camilo Nuñez](https://github.com/camillonunez1998)


## License


[MIT](./LICENSE)