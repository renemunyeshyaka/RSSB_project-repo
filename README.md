# Author: Jean René MUNYESHYAKA
# Don't forget to Fork

Certainly, some files are missing for the project to function correctly on your computer after cloning from GitHub. To obtain all the necessary files, you need to fork this project.

# RSSB_project-repo

## Task 3: Automation & Monitoring
3.1 Implement a Kubernetes cluster deployed on a local machine or within a virtualized environment, using GitHub for version control and a CI/CD pipeline. Apply automation tools such as Terraform, Ansible, and Kubernetes manifests where applicable to provision the infrastructure, configure the cluster, and enforce security, consistency, and scalability. The solution should support hosting an example application, such as an API Rate Limiter hosted on GitHub or any other application of your choice.

3.2 Install a monitoring tool to monitor the health, performance, and security of the entire infrastructure (Network devices, Hosts, storage, Virtual Environment, Dockers, etc.), ensuring proactive issue resolution.


# RSSB_project-repo – Detailed Implementation Plan
1. Project Overview
Objective: Implement an automated, secure, scalable Kubernetes cluster on a local/virtualized environment with CI/CD, monitoring, and a sample application.
Tools: Terraform, Ansible, Kubernetes (K3s/Kind), GitHub Actions, Prometheus + Grafana, Docker.
Application Example: API Rate Limiter (Go/Python microservice).
Repo Name: RSSB_project-repo (public/private GitHub repository)..

2. Repository Structure

RSSB_project-repo/
│
├── .github/workflows/          # CI/CD pipelines
├── terraform/                  # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── ansible/                    # Configuration management
│   ├── playbooks/
│   │   ├── k8s-setup.yml
│   │   ├── node-config.yml
│   │   └── security-hardening.yml
│   └── inventory/
├── k8s-manifests/              # Kubernetes resources
│   ├── api-rate-limiter/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── configmap.yaml
│   ├── monitoring/
│   │   ├── prometheus.yaml

# RSSB Project Repository

This repository provides a comprehensive solution for deploying, configuring, and managing the RSSB project infrastructure and applications. It leverages Kubernetes, Ansible, Terraform, and Go-based microservices to deliver a robust and scalable environment.

---

## Table of Contents

- [Repository Structure](#repository-structure)
- [Getting Started](#getting-started)
- [Application Overview](#application-overview)
- [Monitoring & Observability](#monitoring--observability)
- [Contributing](#contributing)
- [License](#license)

---

## Repository Structure

- **ansible/**: Ansible playbooks and inventory for cluster setup and configuration
- **app/**: Application source code (e.g., API rate limiter)
- **archive/**: Archived or deprecated setup files
- **docs/**: Documentation and architecture diagrams
- **k8s-manifests/**: Kubernetes manifests for deployments, services, and monitoring
- **kind-setup/**: KIND (Kubernetes in Docker) setup files
- **scripts/**: Utility scripts for deployment and setup
- **terraform/**: Terraform configuration for infrastructure provisioning

---

## Getting Started

### Prerequisites

Ensure the following tools are installed on your system:

- Docker
- Kubernetes (KIND or another distribution)
- Ansible
- Terraform
- Go (for building application code)

### Setup Instructions

1. **Clone the repository:**
	
	git clone <repo-url>
	cd RSSB_project-repo
	```
2. **Provision infrastructure with Terraform:**
	
	cd terraform
	terraform init
	terraform apply
	```
3. **Configure and set up the Kubernetes cluster using Ansible:**
	
	cd ../ansible
	ansible-playbook -i inventory/hosts.ini playbooks/k8s-setup.yml
	```
4. **Deploy application and monitoring components:**
	
	cd ../k8s-manifests
	kubectl apply -f api-rate-limiter/
	kubectl apply -f monitoring/
	```

---

## Application Overview

- **API Rate Limiter:**
  - A Go-based microservice for API rate limiting, deployed via Kubernetes manifests.

---

## Monitoring & Observability

- **Prometheus** and **Grafana** are deployed for monitoring and observability. Configuration files are available in `k8s-manifests/monitoring/`.

---

## Contributing

Contributions are welcome! Please open an issue or submit a pull request for any improvements or bug fixes.

---

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
Push image to Docker Hub/GitHub Container Registry.

Update Kubernetes manifests with new image tag.

Deploy to Kubernetes

Use kubectl apply or Helm to deploy updated manifests.

Rollback strategy on failure.

Sample Application: API Rate Limiter

Develop a simple Go/Python service with Redis for rate limiting.

Expose via Kubernetes Service (NodePort/LoadBalancer).

Phase 5: Monitoring Stack Deployment
Deploy Prometheus & Grafana

Use Helm charts or manifests in k8s-manifests/monitoring/.

Monitor: Node metrics, Pod health, network, storage.

Alerting & Dashboards

Configure Prometheus alerts for CPU, memory, disk, pod restarts.

Import Kubernetes dashboard in Grafana.

Logging (Optional)

Deploy EFK stack (Elasticsearch, Fluentd, Kibana) or Loki.

Phase 6: Security & Compliance
Network Policies

Restrict pod-to-pod communication.

Secrets Management

Use Kubernetes Secrets or HashiCorp Vault (optional).

Scanning

Integrate Trivy in CI to scan images for vulnerabilities.

Phase 7: Documentation & Validation
Update README with:

Setup instructions

How to access Grafana, API endpoint

Troubleshooting guide

Validation Scripts

Scripts to verify cluster health, application response, monitoring.

4. Timeline Estimates

5. Deliverables
GitHub Repository with full IaC and application code.

Working Kubernetes cluster on local/virtualized environment.

CI/CD pipeline automatically deploying updates.

Monitoring dashboard (Grafana) with key metrics.

API Rate Limiter service accessible via endpoint.

Documentation for setup, usage, and maintenance.

6. Optional Extensions
Implement GitOps with ArgoCD for continuous deployment.

Add HAProxy/Ingress-NGINX for ingress control.

Backup/restore strategy for cluster state (Velero).

Multi-environment setup (dev/staging/prod).


## Project Overview
Automated Kubernetes cluster deployment with CI/CD, monitoring, and security hardening. Hosts an API Rate Limiter as a sample application.

## Architecture
![Architecture Diagram](docs/architecture.svg)

##  Quick Start

### Prerequisites
- VirtualBox 6.1+ / Multipass / Libvirt
- Terraform v1.5+
- Ansible 2.14+
- kubectl & Helm
- Docker

### Deployment Steps
1. Clone the repository
2. Configure variables in `terraform/variables.tf`
3. Run `terraform init && terraform apply`
4. Run Ansible playbooks
5. Deploy monitoring stack
6. Deploy sample application

## Repository Structure


## Components
- **Infrastructure**: Terraform for VM provisioning
- **Configuration**: Ansible for K8s cluster setup
- **Application**: API Rate Limiter (Go/Redis)
- **CI/CD**: GitHub Actions for automated pipelines
- **Monitoring**: Prometheus + Grafana stack

##  Monitoring
Access Grafana dashboard:

kubectl port-forward svc/grafana 3000:3000 -n monitoring