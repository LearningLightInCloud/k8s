#!/bin/bash

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 1. Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 2.	Create the configuration file for containerd
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

# 3.	Load the modules:
sudo modprobe overlay
sudo modprobe br_netfilter

# 4.	Set the system configurations for Kubernetes networking
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

# 5.	Apply the new settings
sudo sysctl --system

# 6.	Install containerd
sudo apt-get update && sudo apt-get install -y containerd.io

# 7.	Create the default configuration file for containerd
sudo mkdir -p /etc/containerd

# 9.	Generate the default containerd configuration, and save it to the newly created default file
sudo containerd config default | sudo tee /etc/containerd/config.toml

# 10.	Restart containerd to ensure the new configuration file is used
sudo systemctl restart containerd

# Check status by running below command
# sudo systemctl status containerd

# 11.	Disable swap
sudo swapoff -a

# 12.	Install the dependency packages
sudo apt-get update && sudo apt-get install -y apt-transport-https curl

# 13.	Download and add the GPG key
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# 14.	Add Kubernetes to the repository list
cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb [trusted=yes] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /
EOF

# 15.	Update the package listings
sudo apt-get update

# 16.	Install Kubernetes packages
# Note: If you get a dpkg lock message, just wait a minute or two before trying the command again
sudo apt-get install -y kubelet kubeadm kubectl

# 17.	Turn off automatic updates
sudo apt-mark hold kubelet kubeadm kubectl

## How to check logs of GCP VM Auto Start Script
## sudo journalctl -u google-startup-scripts.service -f

## re-run a startup script like this:
## sudo google_metadata_script_runner startup


##############################################################################


# Join the Worker Nodes to the Cluster
# 1.	In the control plane node, create the token and copy the kubeadm join command:
#   	kubeadm token create --print-join-command
#     Note: This output will be used as the next command for the worker nodes.
# 	  Copy the full output from the previous command used in the control plane node. This command starts with kubeadm join.
#
# 2.	In worker nodes, paste the full kubeadm join command to join the cluster. Use sudo to run it as root:
#    	sudo kubeadm join...
#
# 3.  In the control plane node, view the cluster status:
#   	kubectl get nodes


######################

