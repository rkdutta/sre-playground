#!/bin/bash
set -eo pipefail


# install netcat, apache,git and kubectl
sudo apt update && sudo apt install -y netcat apache2 kubectl git

# install helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# install kind
sudo curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
sudo chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind


# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
(echo; echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"') >> $HOME/.profile
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
sudo apt-get install build-essential

sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod a+x /usr/local/bin/yq

# install docker

sudo apt-get -y update
sudo apt-get -y install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null


sudo apt-get -y update
sudo chmod a+r /etc/apt/keyrings/docker.gpg
sudo apt-get -y update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

#testing
sudo docker run hello-world


#install k3s
brew install derailed/k9s/k9s


# troubleshooting step
# https://www.suse.com/support/kb/doc/?id=000020048
sudo echo "sysctl fs.inotify.max_user_instances=8192" >> /etc/sysctl.conf 
sudo echo "fs.inotify.max_user_watches=524288" >> /etc/sysctl.conf
sudo sysctl -p