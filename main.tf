data "google_compute_image" "my_image" {
  family  = "debian-11"
  project = "debian-cloud"
}

resource "google_compute_instance" "instance-1" {
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

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  machine_type = var.machine_type

  name = "instance-1"

  network_interface {
    access_config {
      network_tier = "PREMIUM"
    }

    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = "projects/dynamic-density-246618/regions/europe-west1/subnetworks/default"
  }

  scheduling {
    automatic_restart           = false
    on_host_maintenance         = "TERMINATE"
    preemptible                 = true
    provisioning_model          = "SPOT"
    instance_termination_action = "STOP"
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  zone = "europe-west1-b"

  metadata = {
    startup-script = "apt update && apt install -yq nginx"
  }
}
