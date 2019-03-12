# -*- mode: ruby -*-
# vi: set ft=ruby :
# DB Params >
DB_NAME="moodle"
DB_USER="moodle"
DB_PASS="passdbdb"
ADM_USER="Moodle"
ADM_PASS="Passw0rd"
# <

nodes = [
  { :ip => '192.168.56.101', :host_type => 'db'   },
  { :ip => '192.168.56.102', :host_type => 'web1' },
  { :ip => '192.168.56.103', :host_type => 'web2' }, 
  { :ip => '192.168.56.100', :host_type => 'lb'   },  
]

Vagrant.configure("2") do |config|

config.vm.provider "virtualbox" do |vb|
  vb.memory="1024"
end


# nodes >
(0..nodes.size-1).each do |i|
  config.vm.define "node#{i}" do |node|
    node.vm.box = "centos/7"
    node.vm.hostname = nodes[i][:hostname]
    node.vm.network "private_network", ip: "#{nodes[i][:ip]}"
    case nodes[i][:host_type]
    when "db"
      node.vm.provision "shell", path: "scenario-#{nodes[i][:host_type]}.sh", \
       :args => [nodes[1][:ip],nodes[2][:ip],DB_NAME,DB_USER,DB_PASS]
    when "web1","web2"
      node.vm.provision "shell", path: "scenario-#{nodes[i][:host_type]}.sh", \
       :args => [nodes[i][:ip],nodes[0][:ip],DB_NAME,DB_USER,DB_PASS]
    when "lb"
      node.vm.provision "shell", path: "scenario-#{nodes[i][:host_type]}.sh", \
      :args => [nodes[3][:ip],nodes[1][:ip],nodes[2][:ip]]
    end
  end
end
# <

end
