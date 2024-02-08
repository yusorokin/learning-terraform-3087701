variable "project_id" {
  description = "Project ID"
  default     = "dynamic-density-246618"
}

variable "region" {
  description = "Region"
  default     = "europe-west1"
}

variable "zone" {
  description = "Zone"
  default     = "europe-west1-b"
}

variable "instance_template" {
  description = "Instance template attributes"
  type = object({
    image_name   = string
    machine_type = string
    disk_size_gb = number
    disk_type    = string
  })
  default = {
    image_name   = "nginx"
    machine_type = "f1-micro"
    disk_size_gb = 10
    disk_type    = "pd-balanced"
  }
}

variable "environment" {
  description = "Environment attributes"
  type = object({
    name           = string
    network_prefix = string
  })
  default = {
    name           = "dev"
    network_prefix = "10.10"
  }
}

variable "mig_min_replicas" {
  description = "MIG minimal replica count"
  type        = number
  default     = 1
}

variable "mig_max_replicas" {
  description = "MIG minimal replica count"
  type        = number
  default     = 1
}
