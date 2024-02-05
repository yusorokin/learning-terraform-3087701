terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
    }
  }
}

provider "google" {
  project = "dynamic-density-246618"
  region  = "europe-west1"
}
