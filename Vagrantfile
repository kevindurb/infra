# -*- mode: ruby -*-
# vi: set ft=ruby :
#
Vagrant.configure("2") do |config|
  config.vm.define "homelab" do |manager|
    manager.vm.box = "ubuntu/focal64"
    manager.vm.hostname = "homelab"
    manager.ssh.port = 2200
    manager.vm.network :forwarded_port, guest: 22, host: 2200, id: 'ssh'
    manager.vm.network :forwarded_port, guest: 80, host: 8080, id: 'web'
    manager.vm.network :forwarded_port, guest: 443, host: 4443, id: 'websecure'
  end

  config.vm.provision :ansible do |ansible|
    ansible.playbook = "./playbooks/base_provision.yaml"
  end

  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"
  end
end
