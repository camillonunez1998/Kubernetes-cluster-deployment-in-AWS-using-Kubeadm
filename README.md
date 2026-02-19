# Project

The objective of this project is to develop the tutorials in the official documentation of Kubernetes.

# To improve

- Definir una VPC propia.

## Preliminaries

You will normally require a very demanding infrastructure when administering a cluster with *kubeadm*, in that case you can use the infrastructure defined in `tasks/infrastructure/main.tf`.

AWS expects credentials in `~/.aws/credentials` in the following format

`[default]`<br>
`aws_access_key_id = *****************`<br>
`aws_secret_access_key = ******************`

# Administer a cluster

## Administering with kubeadm

### Installing kubeadm

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/

- Check the MAC address of each node with `ip link show ens5` (or the name of the network interface indicated in the welcome banner of the ssh connection). You will obtian a number like *06:2b:c0:02:56:93*.

- Check the product_UUID with `sudo cat /sys/class/dmi/id/product_uuid`. All the MACs and product_UUID's must be different.

- To disable Swap memory use `sudo swapoff -a`, although normally it is disabled by default. You can check it with `swapon --show`, if there is no answer swap is off.

- To install the container runtime run the script `./admin_with_kubeadm/install_containerd.sh` in every node. Use `chmod +x install_containerd.sh` and `sudo bash install_containerd.sh` (or just `./install_containerd.sh`) to allow execution and execute respectively.

- To install the combo *kubectl + kubelet + kubeadm*, run the script `./admin_with_kubeadm/install_k8s_tools.sh` in every node.

- Configure a *cgroup driver* (control group): We need to make sure te container runtime and the kubelet component match the *cgroup* driver. For this purpose, the best practice is to specify it in the configuration manifest located in `./tasks/admin_with_kubeadm/kubeadm-config.yaml`. Do it only in the main node.

### Creating cluster with kubeadm

https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/

#### Install a single control plane K8s cluster

- Define a network setup for your pods. We defined this also in `./tasks/admin_with_kubeadm/kubeadm-config.yaml` with the CIDR *192.168.0.0/16* to make it clear that the pod network is fully isolated from the VPC network.

- Install *conntrack* in every node for the prechecks done by kubeadm. This is part of the linux kernel but Ubuntu image doesn't include it.

    `sudo apt update`

    `sudo apt install conntrack -y`

- Initialize your control plane node 

    `sudo kubeadm init --config kubeadm-config.yaml`

- Execute the following lines to configure kubectl

    `mkdir -p $HOME/.kube`<br>
    `sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config`<br>
    `sudo chown $(id -u):$(id -g) $HOME/.kube/config`

- Take a note of the kubeadm join command outputted by kubeadm init. You will need it to join nodes eventually. It look something like this 

    `kubeadm join 10.0.1.163:6443 --token **************** \
        --discovery-token-ca-cert-hash sha256:3e3d81e6e7d2b7baef6571ac2ab21e1e397616b1d671dd828c74be38b84f4fb1 `


#### Install a Pod network in the cluster so that the Pods can talk to each other

- Once the cluster is up, and kubectl is connected to it, install the pod network addon *calico*

    `kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/tigera-operator.yaml`

    `kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.1/manifests/custom-resources.yaml`

- Add your worker nodes by running the *kubeadm join* command in each one of them.

- Now your cluster is ready to host the microservices of your application! To finish your session you can simply destroy your AWS resources with terraform (assuming you have already stopped all the resources from your applications).

## Certificate management with kubeadm

https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/

### PKI certificates and requirements
https://kubernetes.io/docs/setup/best-practices/certificates/ 

#### How certificates are used by your cluster

*Note:* There is a total of 10 mandatory certificates when creating a cluster manually (modulo the number of nodes).

*Dibujo de la dinamica de los certificados*

#### Certificates for user accounts

*Dibujo* (son las cuentas de la componentes internas del cluser + los usuarios humanos).

*Note:* Every service that is created inside the cluster is also assigned a Service Account.


## Author


[Camilo Nuñez](https://github.com/camillonunez1998)


## License


[MIT](./LICENSE)