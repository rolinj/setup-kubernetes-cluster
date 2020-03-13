# Below VM specifications were based on the recommended minimum value.

Vagrant.configure(2) do |config|
  config.vm.define "k8sworker1" do |k8sworker1|
    # OS is set to Centos 7 but you can choose your own linux distro.
    # See list of Vagrant boxes - https://app.vagrantup.com/boxes/search
    k8sworker1.vm.box = "centos/7"
    k8sworker1.vm.network "private_network", ip: "192.168.2.51"
    k8sworker1.vm.hostname = "k8sworker1"
    k8sworker1.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "2048", "--cpus", "2"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant", "1"]
    end
  end
  config.vm.define "k8sworker2" do |k8sworker2|
    k8sworker2.vm.box = "centos/7"
    k8sworker2.vm.network "private_network", ip: "192.168.2.52"
    k8sworker2.vm.hostname = "k8sworker2"
    k8sworker2.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "2048", "--cpus", "2"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant", "1"]
    end
  end
  config.vm.define "k8smaster" do |k8smaster|
    k8smaster.vm.box = "centos/7"
    k8smaster.vm.network "private_network", ip: "192.168.2.50"
    k8smaster.vm.hostname = "k8smaster"
    k8smaster.vm.provider :virtualbox do |vb|
      vb.customize ["modifyvm", :id, "--memory", "4096", "--cpus", "2"]
      vb.customize ["setextradata", :id, "VBoxInternal2/SharedFoldersEnableSymlinksCreate/vagrant", "1"]
    end
  end
end

