# for rhel
#!/bin/bash

sudo yum install -y wget git
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo

sudo dnf install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

sudo systemctl enable --now docker

sudo wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum upgrade
# Add required dependencies for the jenkins package
sudo yum install fontconfig java-21-openjdk -y
sudo yum install jenkins -y

sudo usermod -aG docker jenkins
sudo sh -c "echo 'jenkins ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
sudo newgrp docker

sudo systemctl daemon-reload
sudo systemctl enable --now jenkins



echo "Below is Jenkins WebUI initial Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
