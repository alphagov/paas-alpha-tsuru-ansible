# -*- mode: ruby -*-
# vi: set ft=ruby :

INVENTORY_FILE = "inventory.vagrant"
MEMORY = 384
HOSTS = [
  { name: 'tsuru-i1', ip: '172.18.10.11',
    roles: %w{api mongodb} },
  { name: 'tsuru-i2', ip: '172.18.10.12',
    roles: %w{gandalf redis-master} },
  { name: 'tsuru-i3', ip: '172.18.10.13',
    roles: %w{hipache nodes} },
  { name: 'tsuru-i4', ip: '172.18.10.14',
    roles: %w{nodes} },
]

def generate_inventory(hosts, file)
  roles = {}

  File.open(file, "w") do |f|
    hosts.each do |host|
      host_string = "#{host[:name]} \
internal_ip=#{host[:ip]} \
external_ip=#{host[:ip]} \
ansible_ssh_host=#{host[:ip]}\n"

      f.write(host_string)
      host[:roles].each do |role|
        roles[role] ||= []
        roles[role] << host_string
      end
    end

    roles.each do |role, hosts|
      f.write("\n[#{role}]\n")
      f.write(hosts.join)
    end
  end
end

generate_inventory(HOSTS, INVENTORY_FILE) if %w{up provision}.include?(ARGV[0])

Vagrant.configure(2) do |config|
  config.vm.box = "puppetlabs/ubuntu-14.04-64-nocm"

  HOSTS.each do |host|
    config.vm.define host[:name] do |c|
      c.vm.hostname = host[:name]
      c.vm.network :private_network, ip: host[:ip]
    end
  end

  config.vm.provider :virtualbox do |v|
    v.memory = MEMORY
  end

  config.vm.provider :vmware_fusion do |v|
    v.vmx["memsize"] = MEMORY
  end

  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "site.yml"
    ansible.extra_vars = "globals.yml"
    ansible.inventory_path = INVENTORY_FILE
  end
end
