#!/bin/bash

set -e

# Install kubectl if not exist
echo "Install kubectl..."
#curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/${KUBECTL_VERSION}/2022-10-31/bin/linux/${PLATFORM}/kubectl
curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.27.9/2024-01-04/bin/linux/amd64/kubectl

openssl sha1 -sha256 kubectl # check sha256
chmod +x ./kubectl
mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$PATH:$HOME/bin
echo 'export PATH=$PATH:$HOME/bin' >>~/.bashrc

kubectl version --short --client
echo "Installed kubectl."

echo "Install eksctl..."
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin
eksctl version
echo "Installed eksctl."

cd stacks/kubeflow-manifests/
make install-kustomize
echo "Kustomize installed"

### Install mysqlclient
sudo dnf install -y mariadb105-devel gcc python3-devel
sudo yum install gcc openssl-devel bzip2-devel libffi-devel  zlib-devel
pip install mysqlclient