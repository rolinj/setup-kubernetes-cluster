#!/bin/bash

echo "Performing setup for kubernetes cluster..."
printf "\nAdding details to host file...\n"
# Save initial inputs to variables.
ETH1_GATEWAY=$1

# Retrive machine's hostname and IP.
IPADDR=$(cat /etc/sysconfig/network-scripts/ifcfg-eth1 | grep IPADDR | cut -d "=" -f 2)
HOSTNAME=$(hostname)

# Modifying /etc/hosts
sed -i '1 s/^/#/' /etc/hosts # Comment out the very first line of /etc/hosts.
echo "${IPADDR} ${HOSTNAME} ${HOSTNAME}" >> /etc/hosts # Add records to host file.
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

echo "Disabling swap for kubelet to work properly...\n"
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
yum repolist
yum -y install kubelet kubeadm kubectl
echo "Installed kubelet, kubeadm and kubectl successfully"
kubelet --version
kubeadm version

printf "\nStarting and enabling docker/kubelet services...\n"
systemctl start docker && systemctl enable docker
systemctl start docker && systemctl enable kubelet
echo "Started and enabled docker/kubelt services upon boot up successfully!"

printf "\nDownloading calico file for CNI setup...\n"
curl https://docs.projectcalico.org/v3.8/manifests/calico.yaml > calico.yaml
echo "Downloaded calico file successfully!"

printf "\nDownloading kubeadm configuration file...\n"
curl https://raw.githubusercontent.com/rolinj/setup-kubernetes-cluster/master/kubeadm-config.yaml > kubeadm-config.yaml
echo "Downloaded kubeadm-config successfully!"

printf "\nPulling images that will be need by the cluster...\n"
kubeadm config images pull
docker pull k8s.gcr.io/kube-apiserver:v1.16.2
docker pull k8s.gcr.io/kube-controller-manager:v1.16.2
docker pull k8s.gcr.io/kube-scheduler:v1.16.2
docker pull k8s.gcr.io/kube-proxy:v1.16.2
docker pull k8s.gcr.io/coredns:1.6.2
echo "Pulled necessary images successfully!"

printf "\nSet time and date to local rtc and set ntp to yes...\n"
timedatectl set-local-rtc yes
timedatectl set-ntp yes
echo "Successfully set to local rtc and set ntp!"

printf "\nDownloading ntp and ntpdate for time configuration to sync...\n"
yum install -y ntp ntpdate
echo "Downloaded ntp and ntpdate succesfully!"

printf "\nStart ntp service and set date to centos ntp pool...\n"
systemctl start ntpd
systemctl enable ntpd
ntpdate -u -s 0.centos.pool.ntp.org 1.centos.pool.ntp.org 2.centos.pool.ntp.org
systemctl restart ntpd
echo "Setting of ntpdate succesfully set to centos pool ntp org!"

timedatectl

printf "\nSetting default routing to our private network...\n"
# **Set default routing to your created private network**
# - `Note:` This is the most important part. Initializing the cluster or joining a node to a cluster includes a 
# step that it automatically detects the default interface and the IP associated with it.
# The problem is, as we are using Vagrant, a default, natted interface (eth0) will be 
# automatically created across our VMs.. and they will have **identical IPs of 10.0.2.15**.
# This will cause **IP conflict on our cluster**.
# You can check this by doing `ip a` and `ip route` commands.
# We will override the default gateway before initiliazing the cluster so we can use the private IP we have 
# declared on our Vagrantfile then revert the changes afterwards. 
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

printf "\nInitializing the kubernetes cluster...\n" 
# Output will be saved on kubeadm-init.out file.
kubeadm init --config=kubeadm-config.yaml --upload-certs --v=5 | tee kubeadm-init.out

printf "\nCompleting cluster setup...\n"
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
echo "Cluster setup completed!"

printf "Applying calico settings...\n"
kubectl apply -f calico.yaml
echo "Applied calico settings successfully!"

printf "\nReverting routing to default setting...\n"
systemctl restart network
systemctl restart network
echo "Reverted routing settings to default successfully!"

printf "\nKubernetes Cluster setup complete!\n"
