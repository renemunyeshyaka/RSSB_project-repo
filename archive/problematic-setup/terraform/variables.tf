variable "ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "master_memory" {
  description = "Memory for master node (MB)"
  type        = number
  default     = 2048
}

variable "worker_memory" {
  description = "Memory for worker nodes (MB)"
  type        = number
  default     = 2048
}

variable "master_cpu" {
  description = "CPU cores for master node"
  type        = number
  default     = 2
}

variable "worker_cpu" {
  description = "CPU cores for worker nodes"
  type        = number
  default     = 2
}

variable "network_cidr" {
  description = "Network CIDR for K8s cluster"
  type        = string
  default     = "10.17.3.0/24"
}