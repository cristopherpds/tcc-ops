variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
    description = "tcc-k8s-cluster"
    type = string
    default = "tcc-autopilot"
}