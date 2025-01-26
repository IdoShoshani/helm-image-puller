#!/bin/bash
set -e

echo "Updating package list..."
sudo apt-get update -qq

echo "Installing ShellCheck..."
sudo apt-get install -y -qq shellcheck

echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
rm get-docker.sh

echo "⎈ Installing Helm..."
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh

echo "All dependencies installed successfully!"
