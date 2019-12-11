terraform {
  required_version = "0.12.8"
}

provider "google" {
  version = "2.15"
  project = var.project
  region = var.region
}

resource "google_compute_instance" "docker-app" {
  name = "reddit-app-docker"
  machine_type = "g1-small"
  zone = "europe-west1-b"
  tags = ["docker"]
  boot_disk {
    initialize_params {
      image = var.disk_image
    }
  }
  metadata = {
    ssh-keys = "appuser:${file(var.public_key_path)}"
    }
  count = var.instances_count

  network_interface {
    network = "default"
    access_config{}
  }
}

resource "google_compute_firewall" "firewall_puma" {
  name = "allow-puma-default"
  network = "default"
  allow {
    protocol = "tcp" 
    ports = ["9292"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["docker"]
}
