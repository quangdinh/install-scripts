#!/usr/bin/env bash

echo "Installing docker\n"
# change cgroup driver to systemd
sudo mkdir -p /etc/docker
sudo cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    software-properties-common

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian \
   $(lsb_release -cs) \
   stable"

sudo apt-get update

sudo apt-get install docker-ce

echo "Installing kubeadm\n"
sudo apt-get install apt-transport-https gnupg2 curl

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install iptables arptables ebtables
sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
sudo update-alternatives --set arptables /usr/sbin/arptables-legacy
sudo update-alternatives --set ebtables /usr/sbin/ebtables-legacy
sudo apt-get install kubeadm kubelet kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo kubeadm init --apiserver-advertise-address=10.5.1.1 --pod-network-cidr=10.244.0.0/16 >> cluster_initialized.txt

# Copy kube admin to user directory
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# For single node
kubectl taint nodes --all node-role.kubernetes.io/master-

echo "Install Helm\n"
wget https://get.helm.sh/helm-v3.2.0-linux-amd64.tar.gz
tar xvpf helm-v3.2.0-linux-amd64.tar.gz
sudo cp linux-amd64/helm /usr/local/bin
rm -rf helm-v3.2.0-linux-amd64.tar.gz
rm -rf linux-amd64
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo update

echo "Install traefik v2\n"
helm repo add traefik https://containous.github.io/traefik-helm-chart
helm repo update
# Create traefik namespace
kubectl create ns traefik
helm install --namespace=traefik --set="externalIPs=[10.5.1.1]" traefik traefik/traefik