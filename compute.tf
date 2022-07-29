data "google_compute_image" "gpu_image" {
  family = "gpu-1"
}

data "template_file" "startup_script" {
  template = file("startup.sh")
  vars = {
    wallet_address = var.wallet_address
  }
}

locals {
  regions_t4 = [
    "asia-east1",
    "asia-northeast1",
    "asia-northeast3",
    "asia-south1",
    "asia-southeast1",
    "asia-southeast2",
    "australia-southeast1",
    "europe-west1",
    "europe-west2",
    "europe-west3",
    "europe-west4",
    "northamerica-northeast1",
    "southamerica-east1",
    "us-central1",
    "us-east1",
    "us-east4",
    "us-west1",
    "us-west2",
    "us-west4",
  ]
}

resource "google_compute_instance_template" "gpu_instance_template" {
  name         = "gpu-template"
  machine_type = "n1-standard-1"
  guest_accelerator {
    type  = "nvidia-tesla-t4"
    count = 2
  }
  scheduling {
    preemptible                 = true
    provisioning_model          = "SPOT"
    instance_termination_action = "STOP"
    automatic_restart           = false
  }

  metadata_startup_script = data.template_file.startup_script.rendered

  disk {
    source_image = data.google_compute_image.gpu_image.self_link
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
    access_config {
    }
  }
}

resource "google_compute_region_instance_group_manager" "gpu" {
  for_each = toset(local.regions_t4)
  region = each.value
  name = "gpu-igm-${each.value}"
  base_instance_name = "gpu"
  distribution_policy_target_shape = "ANY"

  version {
    instance_template  = google_compute_instance_template.gpu_instance_template.id
  }
  target_size = 16
}
