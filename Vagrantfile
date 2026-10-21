# -*- mode: ruby -*-
# vim: set ft=ruby :

# Указываем зеркало для скачивания образов
ENV['VAGRANT_SERVER_URL'] = 'https://vagrant.elab.pro'

Vagrant.configure("2") do |config|

  # ============================================
  # 1. vpnserver (AlmaLinux 9)
  # ============================================
  config.vm.define "vpnserver" do |serv|
    serv.vm.box = "almalinux/9"
    serv.vm.hostname = "vpnserver"
    serv.vm.provider "virtualbox" do |v|
      v.memory = 2048
      v.cpus = 2
    end

    serv.vm.network "private_network", ip: "192.168.50.10", adapter: 2, netmask: "255.255.255.0"
    serv.vm.network "private_network", ip: "10.0.10.1", adapter: 3, netmask: "255.255.255.252", virtualbox__intnet: "r1"
    serv.vm.network "private_network", ip: "10.0.12.1", adapter: 4, netmask: "255.255.255.252", virtualbox__intnet: "r3"
    serv.vm.network "private_network", ip: "192.168.10.1", adapter: 5, netmask: "255.255.255.0", virtualbox__intnet: "net1"

    serv.vm.provision "shell",
      run: "always",
      inline: <<-SHELL
        # тут будет провижинг
    SHELL
  end

  # ============================================
  # 2. vpnclient (AlmaLinux 9)
  # ============================================
  config.vm.define "vpnclient" do |client|
    client.vm.box = "almalinux/9"
    client.vm.hostname = "router2"
    client.vm.provider "virtualbox" do |v|
      v.memory = 2048
      v.cpus = 2
    end

    client.vm.network "private_network", ip: "192.168.51.10", adapter: 2, netmask: "255.255.255.0"
    client.vm.network "private_network", ip: "10.0.10.2", adapter: 3, netmask: "255.255.255.252", virtualbox__intnet: "r1"
    client.vm.network "private_network", ip: "10.0.11.2", adapter: 4, netmask: "255.255.255.252", virtualbox__intnet: "r2"
    client.vm.network "private_network", ip: "192.168.20.1", adapter: 5, netmask: "255.255.255.0", virtualbox__intnet: "net2"

    client.vm.provision "shell",
      run: "always",
      inline: <<-SHELL
        # тут будет провижинг
SHELL
  end
end
