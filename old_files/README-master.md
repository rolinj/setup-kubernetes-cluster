**Below is the step by step guide on how to setup the master node for Kubernetes cluster.**

1. **SSH to the master node.**
```
vagrant ssh k8smaster
```

2. **Switch to root.**
- `Note:` password for vagrant VMs, by default, is *vagrant*.
```
sudo su
```

3. **Update packages.**
```
yum -y update
```

4. **Modify `/etc/hosts` file with the names and IPs of the VMs created.** *(change values as necessary)*
```
192.168.2.50 k8smaster k8smaster
192.168.2.51 k8sworker1 k8sworker1
192.168.2.52 k8sworker2 k8sworker2 
```

- *Then comment out the localhost resolution to your VM names.*
```
#127.0.0.1 k8smaster k8smaster 
```

5. **Disable SELinux and make the change persistent.**
```
setenforce 0
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
```

6. **Ensure traffic is routed correctly and not blocked by iptables.**
``` 
modprobe br_netfilter
echo '1' > /proc/sys/net/bridge/bridge-nf-call-iptables 
echo '1' > /proc/sys/net/ipv4/ip_forward
```

7. **Disable swap for the kubelet to work properly.**
``` 
swapoff -a
vi /etc/fstab  #then comment out the entry for swap to make the change persistent.
```

8. **Add docker repository.**
```
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
```

9. **Install docker and its dependencies.**
```
yum install -y yum-utils device-mapper-persistent-data lvm2 
yum list docker-ce --showduplicates | sort -r  #this command will list all available versions
yum -y install docker-ce-18.09.9-3.el7  #install the latest verified docker version
```

10. **Add kubernetes repository.**
``` 
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
```

11. **Install kubelet, kubeadm, kubectl.**
```
yum -y install kubelet kubeadm kubectl
```

12. **Start and enable docker/kubelet service upon boot up.**
```
systemctl start docker && systemctl enable docker && \
systemctl start docker && systemctl enable kubelet
```

13. **Download calico.yaml file - `Calico` will be the CNI for our cluster.**
```
curl https://docs.projectcalico.org/v3.8/manifests/calico.yaml > calico.yaml
```

14. **Download kubeadm-config.yaml file - configuration for initializing the cluster.**
```
curl https://raw.githubusercontent.com/rolinj/setup-kubernetes-cluster/master/kubeadm-config.yaml > kubeadm-config.yaml
```

15. **Pull images that will be needed for cluster setup.**
```
kubeadm config images pull
```

16. **Set default routing to your created private network**
- `Note:` This is the most important part. Initializing the cluster or joining a node to a cluster includes a step that it automatically detects the default interface and the IP associated with it.
The problem is, as we are using Vagrant, a default, natted interface (eth0) will be 
automatically created across our VMs.. and they will have **identical IPs of 10.0.2.15**.
This will cause **IP conflict on our cluster**.
You can check this by doing `ip a` and `ip route` commands.
We will override the default gateway before initiliazing the cluster so we can use the private IP we have declared on our Vagrantfile then revert the changes afterwards. 

  - *Install routing package.*
  ```
  yum -y install net-tools
  ```

  - *Delete the default gateway which is 10.0.2.2.*
  ```
  route del default
  ```

  - *Determine the gateway of our private segment IP (192.168.2.50). In our case, can check via ping. It could be 192.168.2.1 or 192.168.2.2*

  - *Add our new default gateway. We will pass the gw IP and the interface name.*
  ```
  route add default gw 192.168.2.1 eth1
  ```

  `Sample output after performing steps:`
  ```
  [root@k8smaster ~]# ip route
  default via 192.168.2.1 dev eth1 
  10.0.2.0/24 dev eth0 proto kernel scope link src 10.0.2.15 metric 100 
  172.17.0.0/16 dev docker0 proto kernel scope link src 172.17.0.1 
  192.168.2.0/24 dev eth1 proto kernel scope link src 192.168.2.50 metric 101 
  [root@k8smaster ~]#
  ```

17. **Initialize the cluster using the kubeadm-config.yaml included in this repository.**
- `Note:` We have added '--v=5" for more verbosity. Observe the steps taken during the initialization.
Also take note of the last part of output as we need that `kubeadm join` command for joining our workers.
```
kubeadm init --config=kubeadm-config.yaml --upload-certs --v=5 | tee kubeadm-init.out
```

18. **Complete the cluster setup.**
```
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

19. **Apply the calico settings.**
```
kubectl apply -f calico.yaml
```

20. **Revert IP routing to its original settings.**
```
route del default #delete the current default first
systemctl restart network 
ip route  #verify that the original setup was back
```
