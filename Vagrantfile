# -*- mode: ruby -*-
# vi: set ft=ruby :

prat_repo_path = File.expand_path("#{File.dirname(__FILE__)}")
prat_dir_name = "prat"
host_prat_port = 5000

motd = <<MOTD
Welcome to your Vagrant-built virtual machine for prat.

To start your prat server go into the prat directory and start the two servers:
  cd #{prat_dir_name}
  python -m chat.scripts.event_server &
  python run_server.py

Then open up your host browser to http://localhost:5000
MOTD

init_script = <<SCRIPT
provisioned_file=/etc/vagrant_provisioned_at
zeromq_version=zeromq-3.2.3
zeromq_tarball=${zeromq_version}.tar.gz
zeromq_url=http://download.zeromq.org/${zeromq_tarball}

if [ ! -f "$provisioned_file" ]
then
  echo "Provisioning your prat server.  This can take up to 10 minutes..."
  echo
  sudo locale-gen en_US
  sudo apt-get update
  sudo apt-get -y install python-software-properties python-pip python-dev \
                          build-essential uuid-dev git mongodb redis-server \
                          libtool autoconf automake python g++ make \
                          python-software-properties
  sudo add-apt-repository -y ppa:chris-lea/node.js
  sudo apt-get update
  sudo apt-get -y install nodejs
  wget $zeromq_url
  tar -xvzf $zeromq_tarball
  cd $zeromq_version
  ./configure
  make
  sudo make install
  cd ..
  rm -rf ${zeromq_version}
  cd #{prat_dir_name}
  sudo pip install -r requirements.txt
  npm install
  mongo prat reset_db.js
  node_modules/bower/bin/bower install
  sudo date > /etc/vagrant_provisioned_at
  sudo sh -c 'echo "#{motd}" > /etc/motd.tail'
  echo
  echo "DONE! Your prat box has been provisioned."
  echo "Run 'vagrant ssh' to access it"
  echo
fi
SCRIPT

Vagrant.configure("2") do |config|
  config.vm.box = "precise64"
  config.vm.box_url = "http://files.vagrantup.com/precise64.box"
  config.vm.network :forwarded_port, guest: host_prat_port, host: 5000
  config.vm.synced_folder prat_repo_path, "/home/vagrant/#{prat_dir_name}"
  config.vm.provision :shell, :inline => init_script
end
