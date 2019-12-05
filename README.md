# Kubernetes Cluster Setup Guide

A complete setup guide for setting up a kubernetes cluster from scratch. Starting from deploying VMs using **Vagrant** and **VirtualBox** up to enabling the _master node_ with **calico** *as CNI* and adding *worker nodes* to the cluster.

**Kubernetes cluster structure**
- 1 master node
- 2 worker nodes
- 2 additional master node (for high availability)

### Kubernetes Cluster Setup Pre-requisites
- **Spawn 3 VMs (5 for HA)**. Easiest way is to use Vagrant.
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

3. **(For high availability) From the additional master node **, download the [additional_master setup script](https://raw.githubusercontent.com/rolinj/setup-kubernetes-cluster/master/kubernetes-nth-master-setup.sh) and modify permission with `chmod 755 <script_name>`.

- **Notice that we have to supply an argument, which is the Gateway IP of our eth1 interface.**
![Master Setup](/images/master_setup.png)

-  **Make sure to do this steps in joining the additional master node on the control plane** -

   Complete the setp up by joining the cluster using --control-plane tag like ff sample command...

   `kubeadm join <your_master_node>:6443 --token iooi7w.bb0oos74heefvnie \
   --discovery-token-ca-cert-hash sha256:caeb991ed48810de91005f00f25d8e470dc60324dbe5bc44812beb22f8a93a21 \
   --control-plane --certificate-key b4b4f6d276ffddc0c457795cc4539b747cd04d0e6c9929794b3d7b52612cc946`

   Then this command to do cluster commands like kubectl etc...
   
   `mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config`

   After joining make sure to run the following command twice (2) to reset your network routing...

   ` systemctl restart network`

- To verify status of the new master node, run below commands: 
    1. `kubectl get nodes -o wide` to check that master node is UP and READY.
    2. `kubectl get pods --all-namespaces` to check that all pods are RUNNING.
    
3. **Validating the Cluster**
Create deployments and verify that they are running and have been assigned to the worker nodes of the cluster.
![Validation](/images/validation.png)

### Installed packages and versions details

| Package Name         | Version                                          |
|----------------------|--------------------------------------------------|
| CentOS               | 7                                                |
| Docker               | 18.9.9 *Latest validated version as of writing.* |
| Kubeadm              | 1.16.2                                           |
| Kubelet              | 1.16.2                                           |
| Kubectl              | 1.16.2                                           |
| Calico               | 3.8                                              |
| Virtual Box          | 6.0.12                                           |
| metrics-server       | TBD                                              |
| Kubernetes-dashboard | TBD                                              |
| HA-Proxy             | 1.5.18                                           |

