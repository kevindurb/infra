# -*- mode: ruby -*-
# vi: set ft=ruby :
#
Vagrant.configure("2") do |config|
  # config.vm.network "private_network", type: "dhcp"

  config.vm.define "manager" do |manager|
    manager.vm.box = "ubuntu/focal64"
    manager.vm.network "private_network", ip: "172.28.128.20"
    manager.ssh.port = 2200
    manager.vm.network :forwarded_port, guest: 22, host: 2200, id: 'ssh'
    manager.vm.network :forwarded_port, guest: 80, host: 8080, id: 'web'
    manager.vm.network :forwarded_port, guest: 80, host: 4443, id: 'websecure'
  end

  config.vm.define "node01" do |node01|
    node01.vm.box = "ubuntu/focal64"
    node01.vm.network "private_network", ip: "172.28.128.21"
    node01.ssh.port = 2201
    node01.vm.network :forwarded_port, guest: 22, host: 2201, id: 'ssh'
  end

  config.vm.define "node02" do |node02|
    node02.vm.box = "ubuntu/focal64"
    node02.vm.network "private_network", ip: "172.28.128.22"
    node02.ssh.port = 2202
    node02.vm.network :forwarded_port, guest: 22, host: 2202, id: 'ssh'
  end

  config.vm.provision :ansible do |ansible|
    ansible.playbook = "./playbooks/base_provision.yaml"
  end

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end
end
