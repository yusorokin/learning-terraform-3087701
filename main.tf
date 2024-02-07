data "google_compute_image" "my_image" {
  family  = "debian-11"
  project = "debian-cloud"
}

module "blog_vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.0"

  project_id   = var.project_id
  network_name = "dev"

  subnets = [
    {
      subnet_name   = "subnet-01"
      subnet_ip     = "10.10.10.0/24"
      subnet_region = var.region
    },
  ]

  routes = [
    {
      name              = "egress-internet"
      description       = "route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      tags              = "egress-inet"
      next_hop_internet = "true"
    },
    {
      name                   = "app-proxy"
      description            = "route through proxy to reach app"
      destination_range      = "10.50.10.0/24"
      tags                   = "app-proxy"
      next_hop_instance      = "app-proxy-instance"
      next_hop_instance_zone = var.region
    },
  ]
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
    network    = module.blog_vpc.network_id
    subnetwork = module.blog_vpc.subnets_ids[0]
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
