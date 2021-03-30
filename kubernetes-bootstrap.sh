#!/bin/bash

KUBERNETES_VERSION=1.20.5-00

echo "Kubernetes=$KUBERNETES_VERSION"
echo "OS=Tested on Ubuntu 20.04.2 LTS (Focal Fossa)"

echo "[TASK-01] Disable and turn off swap"
sed -i '/swap/d' /etc/fstab
swapoff -a

echo "[TASK-02] Stop and Disable UFW firewall"
systemctl disable --now ufw > /dev/null 2>&1

echo "[TASK-03] [containerd] Enable and Load Kernel modules"
cat >>/etc/modules-load.d/containerd.conf<<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

echo "[TASK-04] Add Kernel settings"
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system >/dev/null 2>&1

echo "[TASK-05] Install containerd runtime"
apt update -qq >/dev/null 2>&1
apt install -y containerd apt-transport-https >/dev/null 2>&1
mkdir /etc/containerd
containerd config default > /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd >/dev/null 2>&1

echo "[TASK-06] Add apt repo for kubernetes"
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - >/dev/null 2>&1
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main" >/dev/null 2>&1

echo "[TASK-07] Install Kubernetes components $KUBERNETES_VERSION (kubeadm, kubelet and kubectl)"
apt install -y kubeadm=$KUBERNETES_VERSION kubelet=$KUBERNETES_VERSION kubectl=$KUBERNETES_VERSION >/dev/null 2>&1

echo "[TASK-08] Enable ssh password authentication"
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd

