#!/bin/bash

set -e

echo "=========================================="
echo " Zomato DevOps - Jenkins Server Setup"
echo "=========================================="

# ------------------------------------------
# 1. Update system
# ------------------------------------------
echo "[1/8] Updating Ubuntu..."

sudo apt update
sudo apt upgrade -y

# ------------------------------------------
# 2. Install dependencies, Java and Git
# ------------------------------------------
echo "[2/8] Installing dependencies, Java 21 and Git..."

sudo apt install -y \
    ca-certificates \
    curl \
    gnupg \
    unzip \
    wget \
    git \
    fontconfig \
    openjdk-21-jre

# ------------------------------------------
# 3. Install Docker
# ------------------------------------------
echo "[3/8] Installing Docker..."

sudo install -m 0755 -d /etc/apt/keyrings

sudo curl -fsSL \
    https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc

sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
"Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc" | \
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null

sudo apt update

sudo apt install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
OBOBOB    docker-compose-plugin

sudo systemctl enable docker
OBOBOBsudo systemctl start docker

# Add users to Docker group
OBOBOBsudo usermod -aG docker ubuntu

# ------------------------------------------
OBOBOB# 4. Install AWS CLI v2
# ------------------------------------------
echo "[4/8] Installing AWS CLI..."

curl -fsSL \
    "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
    -o awscliv2.zip

unzip -q awscliv2.zip

sudo ./aws/install

rm -rf aws awscliv2.zip

# ------------------------------------------
# 5. Install kubectl
# ------------------------------------------
echo "[5/8] Installing kubectl..."

sudo mkdir -p -m 755 /etc/apt/keyrings

curl -fsSL \
OBOBOB    https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key | \
    sudo gpg --dearmor \
OBOBOB    -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg

OBOBOBecho \
"deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /" | \
sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null
OBOBOB
sudo apt update

sudo apt install -y kubectl

# ------------------------------------------
# 6. Install Jenkins
# ------------------------------------------
echo "[6/8] Installing Jenkins..."

sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
    https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
OBOBOB
echo \
OBOBOB"deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
OBOBOBhttps://pkg.jenkins.io/debian-stable binary/" | \
sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update

sudo apt install -y jenkins
OBOBOB
# Allow Jenkins to use Docker
sudo usermod -aG docker jenkins

# Start Jenkins
sudo systemctl enable jenkins
sudo systemctl restart jenkins

# ------------------------------------------
# 7. Verification
# ------------------------------------------
echo ""
echo "=========================================="
echo " INSTALLATION VERIFICATION"
echo "=========================================="
OBOBOB
OBOBOBecho ""
echo "===== JAVA ====="
OBOBOBjava -version

echo ""
OBOBOBecho "===== GIT ====="
git --version

echo ""
echo "===== DOCKER ====="
docker --version
sudo systemctl is-active docker

echo ""
echo "===== AWS CLI ====="
aws --version

echo ""
echo "===== KUBECTL ====="
OBOBOBkubectl version --client

OBOBOBecho ""
echo "===== JENKINS ====="
sudo systemctl is-active jenkins
OBOBOBsudo systemctl is-enabled jenkins

echo ""
OBOBOBecho "===== JENKINS PACKAGE ====="
sudo dpkg -l | grep jenkins

echo ""
echo "===== IAM ROLE ====="
aws sts get-caller-identity

echo ""
echo "=========================================="
echo " SETUP COMPLETED SUCCESSFULLY"
echo "=========================================="
