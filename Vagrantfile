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

    serv.vm.provision "shell",
      run: "always",
      inline: <<-SHELL

        # установка пакетов.
        sudo dnf install -y epel-release
        sudo dnf install -y tcpdump net-tools iperf3 openvpn

    SHELL
  end

  # ============================================
  # 2. vpnclient (AlmaLinux 9)
  # ============================================
  config.vm.define "vpnclient" do |client|
    client.vm.box = "almalinux/9"
    client.vm.hostname = "vpnclient"
    client.vm.provider "virtualbox" do |v|
      v.memory = 2048
      v.cpus = 2
    end

    client.vm.network "private_network", ip: "192.168.50.11", adapter: 2, netmask: "255.255.255.0"

    client.vm.provision "shell",
      run: "always",
      inline: <<-SHELL

        # установка пакетов.
        sudo dnf install -y epel-release
        sudo dnf install -y tcpdump net-tools iperf3 openvpn

SHELL
  end
end
