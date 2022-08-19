resource "google_compute_network" "network1" {
  name                    = "network1"
  routing_mode            = "GLOBAL"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "network1_subnet1" {
  name          = "ha-vpn-subnet-1"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.network1.id
  secondary_ip_range {
    range_name    = "pod"
    ip_cidr_range = "10.200.0.0/20"
  }
  secondary_ip_range {
    range_name    = "svc"
    ip_cidr_range = "10.202.0.0/20"
  }
}

resource "google_container_cluster" "cluster" {
  name               = "cluster"
  location           = "${var.region}"
  initial_node_count = "1"

  network = google_compute_network.network1.id
  subnetwork = google_compute_subnetwork.network1_subnet1.id

  ip_allocation_policy {
    cluster_secondary_range_name  = "pod"
    services_secondary_range_name = "svc"
  }

  private_cluster_config {
    enable_private_nodes = true
    enable_private_endpoint = true
    master_ipv4_cidr_block = "172.16.2.32/28"
  }

  binary_authorization {
    evaluation_mode = PROJECT_SINGLETON_POLICY_ENFORCE  
  }

  node_config {
    machine_type = "n1-standard-4"
    disk_size_gb  = "10"
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
  depends_on = [google_compute_network.network1]
}