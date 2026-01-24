#!/bin/bash
set -e

echo "🚀 RSSB Project Setup - Ubuntu 25.10"
echo "==================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check SSH key exists
if [ ! -f ~/.ssh/rssb_project ]; then
    echo -e "${YELLOW}🔑 Generating SSH key for project...${NC}"
    ssh-keygen -t ed25519 -f ~/.ssh/rssb_project -N ""
    chmod 600 ~/.ssh/rssb_project
    chmod 644 ~/.ssh/rssb_project.pub
    echo -e "${GREEN}✅ SSH key generated${NC}"
    
    echo -e "${YELLOW}📋 Your SSH Public Key for GitHub Secrets:${NC}"
    echo "=========================================="
    cat ~/.ssh/rssb_project.pub
    echo "=========================================="
    echo -e "${YELLOW}⚠️  Add this to GitHub → Settings → Secrets → SSH_PUBLIC_KEY${NC}"
    read -p "Press Enter after adding to GitHub Secrets..."
fi

# Check prerequisites
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"
check_command() {
    if ! command -v $1 >/dev/null 2>&1; then
        echo -e "${RED}❌ $1 not found${NC}"
        return 1
    fi
    echo -e "${GREEN}✅ $1 installed${NC}"
    return 0
}

check_command terraform || { echo "Install: sudo apt install terraform"; exit 1; }
check_command ansible || { echo "Install: sudo apt install ansible"; exit 1; }
check_command docker || { echo "Install: sudo apt install docker.io"; exit 1; }
check_command kubectl || { 
    echo -e "${YELLOW}📦 Installing kubectl...${NC}"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm kubectl
}
check_command jq || { echo "Install: sudo apt install jq"; exit 1; }
check_command virsh || { echo "Install: sudo apt install qemu-kvm libvirt-daemon-system"; exit 1; }

# Check libvirt service
if ! systemctl is-active --quiet libvirtd; then
    echo -e "${YELLOW}⚠️  Starting libvirt service...${NC}"
    sudo systemctl start libvirtd
    sudo systemctl enable libvirtd
fi

# Check user groups
if ! groups $USER | grep -q '\blibvirt\b'; then
    echo -e "${YELLOW}⚠️  Adding user to libvirt group...${NC}"
    sudo usermod -aG libvirt $USER
    echo -e "${RED}⚠️  Please log out and back in, then run this script again${NC}"
    exit 1
fi

if ! groups $USER | grep -q '\bdocker\b'; then
    echo -e "${YELLOW}⚠️  Adding user to docker group...${NC}"
    sudo usermod -aG docker $USER
    echo -e "${RED}⚠️  Please log out and back in, then run this script again${NC}"
    exit 1
fi

echo -e "${GREEN}✅ All prerequisites satisfied${NC}"

# Terraform setup
echo -e "${YELLOW}🏗️  Initializing Terraform...${NC}"
cd terraform

# Create terraform.tfvars
cat > terraform.tfvars << TFVARS
ssh_public_key = "$(cat ~/.ssh/rssb_project.pub)"
master_memory = 2048
worker_memory = 2048
master_cpu = 2
worker_cpu = 2
network_cidr = "10.17.3.0/24"
TFVARS

terraform init

# Apply Terraform
echo -e "${YELLOW}🔧 Creating virtual machines (this may take 5-10 minutes)...${NC}"
terraform apply -auto-approve

# Get IP addresses
MASTER_IP=$(terraform output -raw master_ip 2>/dev/null || echo "10.17.3.10")
WORKER_IPS=$(terraform output -json worker_ips 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "10.17.3.11 10.17.3.12")

echo -e "${GREEN}📡 Master IP: $MASTER_IP${NC}"
echo -e "${GREEN}📡 Worker IPs: $WORKER_IPS${NC}"

# Create Ansible inventory
echo -e "${YELLOW}📝 Creating Ansible inventory...${NC}"
cd ..
cat > ansible/inventory/hosts.ini << INVENTORY
[master]
k8s-master ansible_host=$MASTER_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/rssb_project

[workers]
INVENTORY

COUNT=0
for IP in $WORKER_IPS; do
    echo "k8s-worker-$COUNT ansible_host=$IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/rssb_project" >> ansible/inventory/hosts.ini
    COUNT=$((COUNT+1))
done

cat >> ansible/inventory/hosts.ini << INVENTORY

[k8s_cluster:children]
master
workers

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
INVENTORY

# Test SSH connection
echo -e "${YELLOW}🔑 Testing SSH connection...${NC}"
ssh -i ~/.ssh/rssb_project -o ConnectTimeout=10 -o StrictHostKeyChecking=no ubuntu@$MASTER_IP "echo 'SSH connection successful'" || {
    echo -e "${YELLOW}⚠️  SSH not ready yet, waiting 30 seconds...${NC}"
    sleep 30
}

# Run Ansible playbooks
echo -e "${YELLOW}⚙️  Setting up Kubernetes cluster...${NC}"
cd ansible

# Install k3s
if [ ! -f playbooks/k8s-setup.yml ]; then
    echo -e "${RED}❌ k8s-setup.yml not found${NC}"
    exit 1
fi

ansible-playbook -i inventory/hosts.ini playbooks/k8s-setup.yml

# Security hardening
if [ -f playbooks/security-hardening.yml ]; then
    echo -e "${YELLOW}🔒 Applying security hardening...${NC}"
    ansible-playbook -i inventory/hosts.ini playbooks/security-hardening.yml
fi

# Get kubeconfig
echo -e "${YELLOW}📋 Getting kubeconfig...${NC}"
scp -i ~/.ssh/rssb_project -o StrictHostKeyChecking=no ubuntu@$MASTER_IP:/etc/rancher/k3s/k3s.yaml ../kubeconfig 2>/dev/null || {
    echo -e "${YELLOW}⚠️  Retrying kubeconfig download...${NC}"
    sleep 10
    scp -i ~/.ssh/rssb_project -o StrictHostKeyChecking=no ubuntu@$MASTER_IP:/etc/rancher/k3s/k3s.yaml ../kubeconfig
}

if [ -f ../kubeconfig ]; then
    sed -i "s/127.0.0.1/$MASTER_IP/g" ../kubeconfig
    chmod 600 ../kubeconfig
    
    echo -e "${GREEN}✅ KUBECONFIG generated${NC}"
    
    # Show KUBECONFIG for GitHub Secrets
    echo ""
    echo "📊 KUBECONFIG for GitHub Secrets (base64):"
    echo "=========================================="
    cat ../kubeconfig | base64 -w0
    echo ""
    echo "=========================================="
    echo "📝 Copy this ENTIRE string to GitHub Secrets as 'KUBECONFIG'"
else
    echo -e "${RED}❌ Failed to get kubeconfig${NC}"
fi

# Set up local kubectl
export KUBECONFIG=$(pwd)/../kubeconfig
if [ -f ../kubeconfig ]; then
    echo -e "${YELLOW}🔍 Testing cluster...${NC}"
    kubectl cluster-info
    kubectl get nodes
    
    echo -e "${GREEN}✅ SETUP COMPLETED SUCCESSFULLY!${NC}"
    echo ""
    echo "🔧 Next steps:"
    echo "1. Add KUBECONFIG to GitHub Secrets (see base64 above)"
    echo "2. Run: kubectl get pods -A"
    echo "3. Deploy monitoring: ./scripts/deploy-monitoring.sh"
else
    echo -e "${RED}❌ Setup completed with errors${NC}"
fi
