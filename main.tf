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
    access_config {}
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


module "network_firewall-rules" {
  source  = "terraform-google-modules/network/google//modules/firewall-rules"
  version = "9.0.0"

  project_id = "dynamic-density-246618"
  network_name = data.google_compute_network.default.name

  ingress_rules = [{
    name          = "allow-http-ingress"
    description   = "Allow http and https in."
    source_ranges = ["0.0.0.0/0"]
    allow = [{
      protocol = "tcp"
      ports    = [80, 443]
    }]
  }]

  egress_rules = [{
    name               = "allow-all-egress"
    description        = "Allow everything out."
    destination_ranges = ["0.0.0.0/0"]
    allow = [{
      protocol = "all"
    }]
  }]
}
