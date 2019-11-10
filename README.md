# Kubernetes Cluster Setup Guide

A complete setup guide for setting up a kubernetes cluster from scratch. Starting from deploying VMs using **Vagrant** and **VirtualBox** up to enabling the _master node_ with **calico** *as CNI* and adding *worker nodes* to the cluster.

**Kubernetes cluster structure**
- 1 master node
- 2 worker nodes

### Kubernetes Cluster Setup Pre-requisites
- **Spawn 3 VMs**. Easiest way is to use Vagrant.
  - Vagrant installation guide in [Installation Guide](https://www.vagrantup.com/intro/getting-started/install.html)
  - Modify the default Vagrantfile with the contents of this sample [Vagrantfile](https://github.com/rolinj/setup-kubernetes-cluster/blob/master/Vagrantfile)

### Setting up the Kubernetes Cluster
- Once you have prepared the needed VMs, you can follow below steps:
  - [Configuring Master Node](https://github.com/rolinj/setup-kubernetes-cluster/blob/master/README-master.md)
  - [Configuring Worker Node](https://github.com/rolinj/setup-kubernetes-cluster/blob/master/README-worker.md)

### Installed packages and versions details
- CentOS 7
- Docker 18.9.9 `*Latest validated version as of writing.*`
- Kubeadm 1.16.2
- Kubelet 1.16.2
- Kubectl 1.16.2
- Calico 3.8
- VirtualBox 6.0.12

