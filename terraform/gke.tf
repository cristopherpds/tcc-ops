#1. Enabling Compute, Container, Cloud Build, Artifact Registry API's
resource "google_project_service" "compute" {
    project = var.project_id
    service = "compute.googleapis.com"
}

resource "google_project_service" "container" {
    service = "container.googleapis.com"
}

resource "google_project_service" "artifact_registry" {
    service = "artifactregistry.googleapis.com"
}

#2. Configuration for VPC network

resource "google_compute_network" "vpc" {
    name = "gke-vpc"
    auto_create_subnetworks = true
    depends_on = [ google_project_service.compute ]
}

resource "google_container_cluster" "autopilot" {
  name     = var.cluster_name # Nombre del cluster
  location = var.region                 # Usamos la región desde las variables

  # Habilitamos el modo Autopilot
  enable_autopilot = true
  network = google_compute_network.vpc.name

  ip_allocation_policy {
      cluster_ipv4_cidr_block = ""
      services_ipv4_cidr_block = ""
    }

    depends_on = [ google_project_service.container ]
}

