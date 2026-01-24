# Author: Jean René MUNYESHYAKA
terraform {
  required_version = ">= 1.5.0"
}

# Local provider for running commands
provider "local" {}

# Create KIND cluster configuration
resource "local_file" "kind_config" {
  filename = "${path.module}/kind-config.yaml"
  content = <<-EOT
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 30000
    hostPort: 30000
    protocol: TCP
- role: worker
- role: worker
EOT
}

# Install KIND if not present
resource "null_resource" "install_kind" {
  triggers = {
    always_run = timestamp()
  }
  
  provisioner "local-exec" {
    command = <<-EOT
      if ! command -v kind &> /dev/null; then
        echo "Installing KIND..."
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
      fi
    EOT
  }
}

# Create KIND cluster
resource "null_resource" "create_cluster" {
  depends_on = [local_file.kind_config, null_resource.install_kind]
  
  triggers = {
    config_hash = sha256(local_file.kind_config.content)
  }
  
  provisioner "local-exec" {
    command = "kind create cluster --name rssb-cluster --config ${local_file.kind_config.filename}"
  }
  
  provisioner "local-exec" {
    when    = destroy
    command = "kind delete cluster --name rssb-cluster"
  }
}

output "cluster_info" {
  value = "KIND cluster 'rssb-cluster' created with 3 nodes (1 control-plane, 2 workers)"
}
