# Kubernetes Cluster Setup Guide

A complete setup guide for setting up a kubernetes cluster from scratch. Starting from deploying VMs using **Vagrant** and **VirtualBox** up to enabling the _master node_ with **calico** *as CNI* and adding *worker nodes* to the cluster.

**Kubernetes cluster structure**
- 1 master node
- 2 worker nodes

### Kubernetes Cluster Setup Pre-requisites
- **Spawn 3 VMs**. Easiest way is to use Vagrant.
  - Vagrant installation guide in [Installation Guide](https://www.vagrantup.com/intro/getting-started/install.html)
  - Modify the default Vagrantfile with the contents of this sample [Vagrantfile](https://github.com/rolinj/setup-kubernetes-cluster/blob/master/Vagrantfile) then use `vagrant up` command to prepare the VMs.
  ![Vagrant Setup](/images/vagrant_up.png)


### Setting up the Kubernetes Cluster
Once you have prepared the needed VMs, you can follow below steps:
1. **From the master node**, download the [master setup script](https://raw.githubusercontent.com/rolinj/setup-kubernetes-cluster/master/kubernetes-worker-setup.sh) and modify permission with `chmod 755 <script_name>`.
- **Notice that we have to supply an argument, which is the Gateway IP of our eth1 interface.**
![Master Setup](/images/master_setup.png)
- To verify status, run below commands: 
    1. `kubectl get nodes -o wide` to check that master node is UP and READY.
    2. `kubectl get pods --all-namespaces` to check that all pods are RUNNING.

2. **From the worker node**, download the [worker setup script](https://raw.githubusercontent.com/rolinj/setup-kubernetes-cluster/master/kubernetes-worker-setup.sh) and modify permission with `chmod 755 <script_name>`.
- **Notice that we have to supply 3 arguments in order.**
    1. Hostname of the master node
    2. IP address of the mater node
    3. Gateway IP of the eth1 interface
![Worker Setup](/images/worker_setup.png)
- **Not yet done!** We have to run the `kubeadm join` command to make the worker node join the cluster.
    - From the master node, execute `cat kubeadm-init.out` and copy the kubeadm join command from the last line of the output.
    - Once the command is copied, execute the command to our worker node.
- To verify status, run below commands **FROM Master Node**: 
    1. `kubectl get nodes -o wide` to check that worker node is **UP** and **READY** and is indeed **JOINED** to the cluster.
    2. `kubectl get pods --all-namespaces` to check that all pods are RUNNING including the new pods for the worker node.

### Installed packages and versions details
- CentOS 7
- Docker 18.9.9 `*Latest validated version as of writing.*`
- Kubeadm 1.16.2
- Kubelet 1.16.2
- Kubectl 1.16.2
- Calico 3.8
- VirtualBox 6.0.12

