# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "ubuntu-cloud-raring64"
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/raring/current/raring-server-cloudimg-amd64-vagrant-disk1.box"

  config.vm.network :forwarded_port, guest: 3000, host: 3000
  config.vm.network :forwarded_port, guest: 80, host: 8080
  config.ssh.forward_agent
  config.vm.network "private_network", ip: "192.168.50.4"
  
  config.vm.synced_folder "../railsgirls", "/railsgirls"
  config.vm.synced_folder("./puppet/templates", "/tmp/vagrant-puppet/templates")
  
  # vagrant up --provider=virtualbox
  config.vm.provider :virtualbox do |vb, override|
    config.vm.box = "ubuntu-cloud-raring64"
    config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/raring/current/raring-server-cloudimg-amd64-vagrant-disk1.box"
    #vb.gui = true
    vb.customize ["modifyvm", :id, "--memory", "1024"]
    vb.customize ["modifyvm", :id, "--cpus", "2"]   

    # Install Virtual Box additions before provisioning
    # pkg_cmd = "apt-get update -qq; apt-get install -q -y linux-image-generic; "
    # pkg_cmd << "apt-get install -q -y linux-headers-generic-lts-raring dkms; " \
    #   "echo 'Downloading VBox Guest Additions...'; " \
    #   "wget -q http://dlc.sun.com.edgesuite.net/virtualbox/4.2.18/VBoxGuestAdditions_4.2.18.iso; "
    # # Prepare the VM to add guest additions after reboot
    # pkg_cmd << "echo -e 'mount -o loop,ro /home/vagrant/VBoxGuestAdditions_4.2.12.iso /mnt\n" \
    #   "echo yes | /mnt/VBoxLinuxAdditions.run\numount /mnt\n" \
    #     "rm /root/guest_additions.sh; ' > /root/guest_additions.sh; " \
    #   "chmod 700 /root/guest_additions.sh; " \
    #   "sed -i -E 's#^exit 0#[ -x /root/guest_additions.sh ] \\&\\& /root/guest_additions.sh#' /etc/rc.local; " \
    #   "echo 'Installation of VBox Guest Additions is proceeding in the background.'; " \
    #   "echo '\"vagrant reload\" can be used in about 2 minutes to activate the new guest additions.'; "
    # # Activate new kernel
    # pkg_cmd << "shutdown -r +1; "
    # config.vm.provision :shell, :inline => pkg_cmd
    config.vm.provision :puppet,
      module_path: "puppet/modules",
      manifests_path: "puppet/manifests",
      options: ["--templatedir","/tmp/vagrant-puppet/templates"]


  end

  # vagrant plugin install vagrant-vmware-fusion
  # vagrant plugin license vagrant-vmware-fusion license.lic
  config.vm.provider :vmware_fusion do |f, override|
    override.vm.box = "precise64_vmware"
    override.vm.box_url ="http://files.vagrantup.com/precise64_vmware_fusion.box"
    #override.vm.synced_folder ".", "/vagrant", disabled: true
    f.vmx["memsize"] = "1024"
    f.vmx["numvcpus"] = "2"
    config.vm.provision :puppet,
      module_path: "puppet/modules",
      manifests_path: "puppet/manifests",
      options: ["--templatedir","/tmp/vagrant-puppet/templates"]

  end


end
