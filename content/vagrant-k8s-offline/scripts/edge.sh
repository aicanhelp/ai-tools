#!/bin/bash
#
# Common setup for all servers (Control Plane and Nodes)

set -euxo pipefail

# Variable Declaration

# DNS Setting
if [ ! -d /etc/systemd/resolved.conf.d ]; then
	sudo mkdir /etc/systemd/resolved.conf.d/
fi
cat <<EOF | sudo tee /etc/systemd/resolved.conf.d/dns_servers.conf
[Resolve]
DNS=${DNS_SERVERS}
EOF

sudo systemctl restart systemd-resolved

# disable swap
sudo swapoff -a

# keeps the swaf off during reboot
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sudo apt-get update -y


# Create the .conf file to load the modules at bootup
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# install cni plugin, 

# $ wget https://github.com/containernetworking/plugins/releases/download/v0.8.2/cni-plugins-linux-amd64-v0.8.2.tgz

# # Extract the tarball
# $ mkdir cni
# $ tar -zxvf v0.2.0.tar.gz -C cni

# $ mkdir -p /opt/cni/bin
# $ cp ./cni/* /opt/cni/bin/


## Install CRIO Runtime, it seems ,crio can not work!!!

# sudo apt-get update -y
# apt-get install -y software-properties-common curl apt-transport-https ca-certificates

# curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key |
#     gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
# echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" |
#     tee /etc/apt/sources.list.d/cri-o.list

# sudo apt-get update -y
# sudo apt-get install -y cri-o

# cat > /etc/crio/crio.conf << EOF
# [crio.image]
# sandbox_image = "registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.9"
# pause_image = "registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.9"
# insecure_registries = ["docker.mirrors.ustc.edu.cn","dockerhub.azk8s.cn","hub-mirror.c.163.com"]
# EOF

# sudo systemctl daemon-reload
# sudo systemctl enable crio --now
# sudo systemctl start crio.service

# echo "CRI runtime installed successfully"

sudo apt-get install -y containerd

cat > /etc/containerd/config.toml << EOF
[plugins."io.containerd.grpc.v1.cri"]
    sandbox_image = "registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.9"
EOF

sudo systemctl resatrt containerd

echo "Containerd runtime installed successfully"

