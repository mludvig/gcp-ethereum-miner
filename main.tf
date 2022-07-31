terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.30.0"
    }
  }
}

provider "google" {
  credentials = var.credentials_file == null ? null : file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}
