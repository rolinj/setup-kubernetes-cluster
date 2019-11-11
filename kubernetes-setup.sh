#!/bin/bash

echo "Performing setup for kubernetes cluster..."
echo "Adding master and worker details to host file..."
# Save initial inputs to variables.
MASTER_HOSTNAME=$1
MASTER_IPADDR=$2
ETH1_GATEWAY=$3

# Retrive machine's hostname and IP.
IPADDR=$(cat /etc/sysconfig/network-scripts/ifcfg-eth1 | grep IPADDR | cut -d "=" -f 2)
HOSTNAME=$(hostname)

# Modifying /etc/hosts
sed -i '1 s/^/#/' /etc/hosts # Comment out the very first line of /etc/hosts.
echo "${MASTER_IPADDR} ${MASTER_HOSTNAME} ${MASTER_HOSTNAME}" >> /etc/hosts # Add master records to host file.
echo "${IPADDR} ${HOSTNAME} ${HOSTNAME}" >> /etc/hosts # Add worker records to host file.
echo "/etc/hosts file has been updated successfully!"
cat /etc/hosts

echo "Updating packages..."
# Perform package updates
# yum -y update
echo "Updating packages complete!"

echo "Disabling SELinux policy persistently..."
# Disable SELinux policy persistently
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
echo "SELinux disabled successfully!"

echo "Ensuring traffic will not be block by iptables..."
# Ensure traffic is route correctly and not blocked by iptables.
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables 
echo '1' > /proc/sys/net/ipv4/ip_forward
echo "Iptables updated successfully!"

echo "Disabling swap for kubelet to work properly..."
# Disabling swap for the kubelet to work properly.
swapoff -a
sed -i -r 's/(.+ swap .+)/#\1/' /etc/fstab
echo "Swap disabled successfully!"
cat /etc/fstab

echo "Installing docker and its dependencies..."
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y yum-utils device-mapper-persistent-data lvm2
yum -y install docker-ce-18.09.9-3.el7
echo "Installed docker successfully"
docker version

echo "Installing kubelet, kubeadm and kubectl..."
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
yum -y install kubelet kubeadm kubectl
echo "Installed kubelet, kubeadm and kubectl successfully"
kubelet --version
kubeadm version
kubectl version

echo "Starting and enabling docker/kubelet services..."
systemctl start docker && systemctl enable docker
systemctl start docker && systemctl enable kubelet
echo "Started and enabled docker/kubelt services upon boot up successfully!"

echo "Pulling images that will be need by the cluster..."
kubeadm config images pull
echo "Pulled necessary images successfully!"

echo "Setting default routing to our private network..."
yum -y install net-tools
route del default
route add default ${ETH1_GATEWAY} eth1
echo "Updated default interface and gateway successfully!"
ip route
