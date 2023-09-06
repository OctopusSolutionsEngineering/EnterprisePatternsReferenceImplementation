#!/bin/bash

# Return the Ubuntu release name in distros like Linux Mint
source /etc/os-release

CODENAME=${VERSION_CODENAME}

if [[ -n ${UBUNTU_CODENAME} ]]
then
  CODENAME=${UBUNTU_CODENAME}
fi

apt-get update
apt-get install -y openssl jq gnupg curl ca-certificates apt-transport-https wget zip unzip
wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor > /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com ${CODENAME} main" > /etc/apt/sources.list.d/hashicorp.list
apt update && apt-get install -y terraform
if [ ! -f /usr/local/bin/kubectl ]
then
  curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
fi
if [ ! -f /usr/local/bin/minikube ]
then
  curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
  install minikube-linux-amd64 /usr/local/bin/minikube
fi
if [ ! -f /usr/local/bin/argocd ]
then
  curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
  install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
  rm argocd-linux-amd64
fi
if [ ! -f /usr/local/bin/octo ]
then
  curl -L -o octo.tar.gz https://github.com/OctopusDeploy/OctopusCLI/releases/download/v9.1.7/OctopusTools.9.1.7.linux-x64.tar.gz
  tar xzf octo.tar.gz
  mv octo /usr/local/bin/octo
fi