# Architecture Overview

## System Architecture


┌─────────────────────────────────────────────────────────────┐
│ GitHub Repository │
│ RSSB_project-repo │
└─────────────────────────┬───────────────────────────────────┘
│
│ CI/CD (GitHub Actions)
▼
┌─────────────────────────────────────────────────────────────┐
│ Infrastructure Layer │
│ Terraform ───────────▶ Virtual Machines │
│ (Libvirt/VirtualBox) ├── k8s-master │
│ ├── k8s-worker-0 │
│ └── k8s-worker-1 │
└─────────────────────────┬───────────────────────────────────┘
│
│ Ansible Configuration
▼
┌─────────────────────────────────────────────────────────────┐
│ Kubernetes Cluster │
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│ │ Master │ │ Worker 0 │ │ Worker 1 │ │
│ │ │ │ │ │ │ │
│ │ ● API │ │ ● Pods │ │ ● Pods │ │
│ │ ● Scheduler│ │ ● Docker │ │ ● Docker │ │
│ │ ● etcd │ │ │ │ │ │
│ └─────────────┘ └─────────────┘ └─────────────┘ │
└─────────────────────────┬───────────────────────────────────┘
│
│ Kubernetes Manifests
▼
┌─────────────────────────────────────────────────────────────┐
│ Application Layer │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ API Rate Limiter Service │ │
│ │ ┌─────────┐ ┌─────────┐ │ │
│ │ │ App │──────▶│ Redis │ │ │
│ │ │ Pod │ │ Pod │ │ │
│ │ └─────────┘ └─────────┘ │ │
│ └─────────────────────────────────────────────────────┘ │
│ │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ Monitoring Stack │ │
│ │ ┌─────────┐ ┌─────────┐ │ │
│ │ │Prometheus│──────▶│ Grafana │ │ │
│ │ │ Pod │ │ Pod │ │ │
│ │ └─────────┘ └─────────┘ │ │
│ └─────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘



## Network Flow
1. **User Request** → Ingress Controller → API Rate Limiter Service
2. **Rate Limiting** → Redis checks → Allow/Deny request
3. **Monitoring** → Prometheus scrapes metrics → Grafana visualization
4. **CI/CD** → Code push triggers build → Auto-deployment to cluster

## Security Layers
1. **Infrastructure**: SSH key authentication, firewall rules
2. **Kubernetes**: RBAC, Network Policies, Pod Security Standards
3. **Application**: Rate limiting, input validation
4. **Monitoring**: Alerting on security events

## Create these secrets in your GitHub repository (Settings → Secrets and variables → Actions):


SSH_PUBLIC_KEY: # Contents of ~/.ssh/id_rsa.pub
KUBECONFIG: # Contents of kubeconfig file (generated after Ansible run)
DOCKER_USERNAME: # Your Docker Hub/GHCR username
DOCKER_PASSWORD: # Your access token