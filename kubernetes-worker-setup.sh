#!/bin/bash

echo "Performing setup for kubernetes cluster..."
printf "\nAdding master and worker details to host file...\n"
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

printf "\nUpdating packages...\n"
# Perform package updates
# yum -y update
echo "Updating packages complete!"

printf "\nDisabling SELinux policy persistently...\n"
# Disable SELinux policy persistently
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
echo "SELinux disabled successfully!"

printf "\nDisabling swap for kubelet to work properly...\n"
# Disabling swap for the kubelet to work properly.
swapoff -a
sed -i -r 's/(.+ swap .+)/#\1/' /etc/fstab
echo "Swap disabled successfully!"
cat /etc/fstab

printf "\nInstalling docker and its dependencies...\n"
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y yum-utils device-mapper-persistent-data lvm2
yum -y install docker-ce-18.09.9-3.el7
echo "Installed docker successfully"
docker version

printf "\nInstalling kubelet, kubeadm and kubectl...\n"
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

printf "\nStarting and enabling docker/kubelet services...\n"
systemctl start docker && systemctl enable docker
systemctl start docker && systemctl enable kubelet
echo "Started and enabled docker/kubelt services upon boot up successfully!"

printf "\nPulling images that will be need by the cluster...\n"
kubeadm config images pull
echo "Pulled necessary images successfully!"

printf "\nSetting default routing to our private network...\n"
yum -y install net-tools
route del default
route add default gw ${ETH1_GATEWAY} eth1
echo "Updated default interface and gateway successfully!"
ip route

printf "\nEnsuring traffic will not be block by iptables...\n"
# Ensure traffic is route correctly and not blocked by iptables.
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables 
echo '1' > /proc/sys/net/ipv4/ip_forward
echo "Iptables updated successfully!"

printf "\nRestarting kubelet.service...\n"
systemctl restart kubelet
echo "Restarted kubelet service successfully!"

printf "\To complete the worker node joining to cluster, please perform the following: \n"
printf "\n [1] Revert IP routing to default via systemctl restart network 2 times \n"
printf "\n [2] Restart kubelet service via systemctl restart kubelet \n"
