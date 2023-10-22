Vagrant.configure("2") do |config|
  # Configure the "Master" VM
  config.vm.define "master" do |master|
    master.vm.box = "ubuntu/focal64"  # Define the base box for the "Master" VM
    master.vm.hostname = "master"  # Set the hostname for the "Master" VM
    master.vm.network "private_network", ip: "192.168.58.2"  # Assign a private network IP to the "Master" VM
  end

  # Configure the "Slave" VM
  config.vm.define "slave" do |slave|
    slave.vm.box = "ubuntu/focal64"  # Define the base box for the "Slave" VM
    slave.vm.hostname = "slave"  # Set the hostname for the "Slave" VM
    slave.vm.network "private_network", ip: "192.168.58.4"  # Assign a private network IP to the "Slave" VM
  end

  # Customize provider settings (VirtualBox in this example)
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "1024"  # Adjust the value to allocate more memory to each VM
  end
end

