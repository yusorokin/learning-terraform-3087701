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
  ]
  ingress_rules = [
    {
      name          = "allow-http-ingress"
      description   = "Allow http and https in."
      source_ranges = ["0.0.0.0/0"]
      allow = [{
        protocol = "tcp"
        ports    = [80, 443]
      }]
    },
    {
      name          = "allow-ssh-ingress"
      description   = "Allow http and https in."
      source_ranges = ["0.0.0.0/0"]
      allow = [{
        protocol = "tcp"
        ports    = [22]
      }]
    },
  ]

  egress_rules = [{
    name               = "allow-all-egress"
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
  name         = "blog-load-balancer"
  service_port = 80
  target_tags  = ["allow-lb-service"]
  network      = module.blog_vpc.network_id
}

module "vm_instance_template" {
  source  = "terraform-google-modules/vm/google//modules/instance_template"
  version = "10.1.1"

  machine_type = var.machine_type

  tags = ["allow-lb-service"]

  network    = module.blog_vpc.network_id
  subnetwork = module.blog_vpc.subnets_ids[0]
  # access_config = [{}]

  source_image = "nginx"
  disk_size_gb = 10
  disk_type    = "pd-balanced"
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

  min_replicas = 1
  max_replicas = 2
  hostname     = "blog-mig"

  instance_template = module.vm_instance_template.self_link
  target_pools      = [module.load_balancer.target_pool]

  named_ports = [{
    name = "http"
    port = 80
  }]
}
