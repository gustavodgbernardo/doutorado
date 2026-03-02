Vagrant.configure("2") do |config|
    # Define a VM Ubuntu 16.04
    config.vm.define "ubuntu16" do |ubuntu16|
      ubuntu16.vm.box = "ubuntu/xenial64"
      ubuntu16.vm.network "public_network", bridge: "enp9s0"
      ubuntu16.vm.network "forwarded_port", guest: 80, host: 8080
      ubuntu16.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
      end
      ubuntu16.vm.provision "file", source: "./get-flow.py", destination: "/home/vagrant/get-flow.py"
      ubuntu16.vm.provision "file", source: "./Dockerfile", destination: "/home/vagrant/Dockerfile"
      ubuntu16.vm.provision "shell", inline: <<-SHELL
        # Update package list and upgrade packages
        sudo apt-get update
        sudo apt-get upgrade -y

        # Install Apache web server
        sudo apt-get install -y apache2
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

        # Add Docker's official GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

        # Add Docker repository
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

        # Update package lists again
        sudo apt-get update -y

        # Install Docker
        sudo apt-get install -y docker-ce

        # Start Docker and enable it to start on boot
        sudo systemctl start docker
        sudo systemctl enable docker

        # Ensure Apache is running
        sudo systemctl enable apache2
        sudo systemctl start apache2

        # Create a simple index.html page
        echo "<html><body><h1>Hello from Ubuntu 16.04!</h1></body></html>" | sudo tee /var/www/html/index.html

        # Configure SSH to allow password authentication
        sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
        sudo sed -i 's/^PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
        sudo systemctl restart sshd

        # Install vsftpd FTP server
        sudo apt-get install -y vsftpd

        # Backup original vsftpd config
        sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.bak

        # Configure vsftpd for user/password access
        sudo sed -i 's/^#local_enable=YES$/local_enable=YES/' /etc/vsftpd.conf
        sudo sed -i 's/^#write_enable=YES$/write_enable=YES/' /etc/vsftpd.conf
        sudo sed -i 's/^#chroot_local_user=YES$/chroot_local_user=YES/' /etc/vsftpd.conf
        sudo sed -i 's/^#allow_writeable_chroot=YES$/allow_writeable_chroot=YES/' /etc/vsftpd.conf

        # Restart vsftpd service
        sudo systemctl restart vsftpd

        # Open ports in the firewall for SSH (22) and FTP (21)
        sudo ufw allow 22/tcp
        sudo ufw allow 21/tcp

        # Enable firewall if it's not enabled
        sudo ufw enable

        # Create a user for FTP access
        echo "Creating FTP user..."

        # Define username and password for FTP access
        FTP_USER="ftpuser"
        FTP_PASS="ftppassword"

        # Create FTP user and set password
        sudo useradd -m $FTP_USER
        echo "$FTP_USER:$FTP_PASS" | sudo chpasswd

        # Ensure the user's home directory has the correct permissions
        sudo chown $FTP_USER:$FTP_USER /home/$FTP_USER

        # Final message
        echo "SSH and FTP configuration completed!"
        echo "SSH access: Use '$FTP_USER' with the password '$FTP_PASS'."
        echo "FTP server configured. You can use the same user credentials to access FTP."
      SHELL
    end

    # Define the Kali Linux VM (no changes made to this part)
    config.vm.define "kali" do |kali|
      kali.vm.box = "kalilinux/rolling"
      kali.vm.network "public_network", bridge: "enp9s0"
      kali.vm.provider :virtualbox do |vb|
        vb.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
      end
      kali.vm.provision "file", source: "./darkweb2017-top10000.txt", destination: "/home/vagrant/darkweb2017-top10000.txt"
      kali.vm.provision "file", source: "./top-usernames-shortlist.txt", destination: "/home/vagrant/top-usernames-shortlist.txt"
      kali.vm.provision "shell", inline: <<-SHELL
        # Update package list and upgrade packages
        sudo apt-get update
        # Additional provisioning steps for Kali Linux (if needed) can go here
        git clone https://github.com/jseidl/GoldenEye.git
        git clone https://github.com/R3DHULK/HULK.git
      SHELL
    end
  end
