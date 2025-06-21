#!/bin/bash
#
# Setup for Control Plane (Master) servers

set -euxo pipefail

NODENAME=$(hostname -s)


sudo kubeadm config images pull --image-repository registry.cn-hangzhou.aliyuncs.com/google_containers

echo "Preflight Check Passed: Downloaded All Required Images"

sudo kubeadm config images list

# controlplane: registry.k8s.io/kube-apiserver:v1.29.4
# controlplane: registry.k8s.io/kube-controller-manager:v1.29.4
# controlplane: registry.k8s.io/kube-scheduler:v1.29.4
# controlplane: registry.k8s.io/kube-proxy:v1.29.4
# controlplane: registry.k8s.io/coredns/coredns:v1.11.1
# controlplane: registry.k8s.io/pause:3.9
# controlplane: registry.k8s.io/etcd:3.5.10-0

echo "CONTROL_IP:    $CONTROL_IP "
echo "POD_CIDR:      $POD_CIDR "
echo "SERVICE_CIDR:  $SERVICE_CIDR "
echo "NODENAME:      $NODENAME "

echo sudo kubeadm init --image-repository registry.cn-hangzhou.aliyuncs.com/google_containers --apiserver-advertise-address=$CONTROL_IP --apiserver-cert-extra-sans=$CONTROL_IP --pod-network-cidr=$POD_CIDR --service-cidr=$SERVICE_CIDR --node-name "$NODENAME" --ignore-preflight-errors Swap

sudo kubeadm init --image-repository registry.cn-hangzhou.aliyuncs.com/google_containers --apiserver-advertise-address=$CONTROL_IP --apiserver-cert-extra-sans=$CONTROL_IP --pod-network-cidr=$POD_CIDR --service-cidr=$SERVICE_CIDR --node-name "$NODENAME" --ignore-preflight-errors Swap

#sudo kubeadm init --image-repository registry.cn-hangzhou.aliyuncs.com/google_containers --pod-network-cidr=$POD_CIDR --service-cidr=$SERVICE_CIDR --node-name "$NODENAME" --ignore-preflight-errors Swap

#sudo kubeadm init --image-repository registry.cn-hangzhou.aliyuncs.com/google_containers --apiserver-advertise-address=10.0.0.10 --apiserver-cert-extra-sans=10.0.0.10 --pod-network-cidr=172.16.1.0/16 --service-cidr=172.17.1.0/18 --node-name controlplane --ignore-preflight-errors Swap

mkdir -p "$HOME"/.kube
sudo cp -i /etc/kubernetes/admin.conf "$HOME"/.kube/config
sudo chown "$(id -u)":"$(id -g)" "$HOME"/.kube/config

# Save Configs to shared /Vagrant location

# For Vagrant re-runs, check if there is existing configs in the location and delete it for saving new configuration.

config_path="/vagrant/configs"

if [ -d $config_path ]; then
  rm -f $config_path/*
else
  mkdir -p $config_path
fi

cp -i /etc/kubernetes/admin.conf $config_path/config
touch $config_path/join.sh
chmod +x $config_path/join.sh

kubeadm token create --print-join-command > $config_path/join.sh

# Install Calico Network Plugin

# curl https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VERSION}/manifests/calico.yaml -O

kubectl apply -f /vagrant/calico.yaml

sudo -i -u vagrant bash << EOF
whoami
mkdir -p /home/vagrant/.kube
sudo cp -i /vagrant/configs/config /home/vagrant/.kube/
sudo chown 1000:1000 /home/vagrant/.kube/config
EOF

# Install Metrics Server

# kubectl apply -f https://raw.githubusercontent.com/techiescamp/kubeadm-scripts/main/manifests/metrics-server.yaml
kubectl apply -f /vagrant/metrics-server.yaml

