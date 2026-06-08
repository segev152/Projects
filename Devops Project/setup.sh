#!/bin/bash
'

'

############################
# 1. Check & Install Tools
############################
echo "Checking prerequisites..."

if ! command -v terraform >/dev/null 2>&1; then
  echo "Installing Terraform 1.14.2..."
  wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt update && sudo apt install terraform

 else


  echo "Terraform is already installed."
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker not found, installing with snap..."
  sudo snap install docker
else
  echo "Docker is already installed."
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "Kubernetes CLI not installed, installing with snap..."
  sudo snap install kubectl --classic
else
  echo "Kubectl is already installed."
fi

if ! command -v helm >/dev/null 2>&1; then
  echo "Helm not installed, installing with snap..."
  sudo snap install helm --classic
else
  echo "Helm is already installed."
fi

if ! command -v aws >/dev/null 2>&1; then
  echo "AWS CLI not found, installing..."
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip awscliv2.zip > /dev/null
  sudo ./aws/install > /dev/null
  rm -rf aws awscliv2.zip
else
  echo "AWS CLI is already installed."
fi

if ! command -v tfsec >/dev/null 2>&1; then
  echo "Installing tfsec (Terraform Security Scanner)..."
  wget -qO tfsec https://github.com/aquasecurity/tfsec/releases/latest/download/tfsec-linux-amd64
  chmod +x tfsec
  sudo mv tfsec /usr/local/bin/
else
  echo "tfsec is already installed."
fi

echo "All tools are ready!"