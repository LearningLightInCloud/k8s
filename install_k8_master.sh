#!/bin/bash

master-node=$1
worker01=$2
worker02=$3

sudo apt update
sudo apt install docker.io -y
sudo systemctl enable docker
sudo systemctl start docker

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update
sudo apt install -y kubeadm kubelet kubectl
sudo apt-mark hold kubeadm kubelet kubectl
kubeadm version

sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

echo overlay >> /etc/modules-load.d/containerd.conf
echo br_netfilter >> /etc/modules-load.d/containerd.conf

sudo modprobe overlay
sudo modprobe br_netfilter

echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/kubernetes.conf
echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.d/kubernetes.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/kubernetes.conf

sudo sysctl --system
sudo hostnamectl set-hostname master-node
sudo hostnamectl set-hostname worker01

echo "${master-node} master-node" >> /etc/hosts
echo "${worker01} worker01" >> /etc/hosts
echo "${worker02} worker02"  >> /etc/hosts

echo "KUBELET_EXTRA_ARGS=\"--cgroup-driver=cgroupfs\"" >> /etc/default/kubelet
sudo systemctl daemon-reload && sudo systemctl restart kubelet

echo "{
   \"exec-opts\": [\"native.cgroupdriver=systemd\"],
   \"log-driver\": \"json-file\",
   \"log-opts\": {
   \"max-size\": \"100m\"
},
\"storage-driver\": \"overlay2\"
}" >> /etc/docker/daemon.json

sudo systemctl daemon-reload && sudo systemctl restart docker

echo "Environment=\"KUBELET_EXTRA_ARGS=--fail-swap-on=false\"" >> /usr/lib/systemd/system/kubelet.service.d/10-kubeadm.conf

sudo systemctl daemon-reload && sudo systemctl restart kubelet
sudo kubeadm init --control-plane-endpoint=master-node --upload-certs

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl taint nodes --all node-role.kubernetes.io/control-plane-



