data "google_compute_image" "my_image" {
  family  = "debian-11"
  project = "debian-cloud"
}

data "google_compute_network" "default" {
  name = "default"
}

resource "google_compute_instance" "blog" {
  name         = "instance-1"
  machine_type = var.machine_type
  zone         = "europe-west1-b"

  boot_disk {
    auto_delete = true
    device_name = "instance-1"

    initialize_params {
      image = data.google_compute_image.my_image.self_link
      size  = 10
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  network_interface {
    network = data.google_compute_network.default.id
  }

  scheduling {
    automatic_restart           = false
    on_host_maintenance         = "TERMINATE"
    preemptible                 = true
    provisioning_model          = "SPOT"
    instance_termination_action = "STOP"
  }

  metadata = {
    startup-script = "apt update && apt install -yq nginx"
  }
}

resource "google_compute_firewall" "rules_ingress" {
  name        = "allow-http-ingress"
  description = "Allow http and https in."

  network   = data.google_compute_network.default.id
  direction = "INGRESS"

  allow {
    protocol = "tcp"
    ports    = [80, 443]
  }

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "rules_egress" {
  name        = "allow-all-egress"
  description = " Allow everything out."

  network   = data.google_compute_network.default.id
  direction = "EGRESS"

  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}
