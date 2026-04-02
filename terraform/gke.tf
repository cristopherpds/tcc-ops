resource "google_container_cluster" "autopilot" {
  name     = "tcc-autopilot"            # Nombre del cluster
  location = var.region                 # Usamos la región desde las variables

  # Habilitamos el modo Autopilot
  enable_autopilot = true

  # Configuraciones de red (opcional, usa las predeterminadas si no es necesario)
  network    = "default"
  subnetwork = "default"
}