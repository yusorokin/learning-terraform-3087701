data "google_compute_image" "nginx_image" {
  name    = var.instance_template.image_name
  project = var.project_id
}

module "blog_vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 9.0"

  project_id   = var.project_id
  network_name = "${var.environment.name}-vpc"

  subnets = [
    {
      subnet_name   = "${var.environment.name}-subnet-01"
      subnet_ip     = "${var.environment.network_prefix}.10.0/24"
      subnet_region = var.region
    },
  ]

  routes = [
    {
      name              = "${var.environment.name}-egress-internet"
      description       = "route through IGW to access internet"
      destination_range = "0.0.0.0/0"
      tags              = "egress-inet"
      next_hop_internet = "true"
    },
  ]
  ingress_rules = [
    {
      name          = "${var.environment.name}-allow-http-ingress"
      description   = "Allow http and https in."
      source_ranges = ["0.0.0.0/0"]
      allow = [{
        protocol = "tcp"
        ports    = [80, 443]
      }]
    },
    {
      name          = "${var.environment.name}-allow-ssh-ingress"
      description   = "Allow http and https in."
      source_ranges = ["0.0.0.0/0"]
      allow = [{
        protocol = "tcp"
        ports    = [22]
      }]
    },
  ]

  egress_rules = [{
    name               = "${var.environment.name}-allow-all-egress"
    description        = "Allow everything out."
    destination_ranges = ["0.0.0.0/0"]
    allow = [{
      protocol = "all"
    }]
  }]
}

module "load_balancer" {
  source       = "GoogleCloudPlatform/lb/google"
  version      = "~> 2.0.0"
  region       = var.region
  name         = "${var.environment.name}-blog"
  service_port = 80
  target_tags  = ["${var.environment.name}-lb"]
  network      = module.blog_vpc.network_id
}

module "vm_instance_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "10.1.1"

  machine_type = var.instance_template.machine_type

  tags = ["${var.environment.name}-lb"]

  network    = module.blog_vpc.network_id
  subnetwork = module.blog_vpc.subnets_ids[0]

  source_image = data.google_compute_image.nginx_image.self_link
  disk_size_gb = var.instance_template.disk_size_gb
  disk_type    = var.instance_template.disk_type
  auto_delete  = true

  service_account = {
    email  = "terraform@dynamic-density-246618.iam.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }
}

module "managed_instance_group" {
  source  = "terraform-google-modules/vm/google//modules/mig"
  version = "10.1.1"

  project_id = var.project_id
  region     = var.region

  min_replicas = var.mig_min_replicas
  max_replicas = var.mig_max_replicas
  hostname     = "${var.environment.name}-blog"

  instance_template = module.vm_instance_template.self_link
  target_pools      = [module.load_balancer.target_pool]

  named_ports = [{
    name = "http"
    port = 80
  }]
}
