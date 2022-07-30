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
  gpus = {
    t4 = {
      accelerator_type  = "nvidia-tesla-t4"
      accelerator_count = 2
      instance_type     = "n1-standard-1"
      regions = [
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
    v100 = {
      accelerator_type  = "nvidia-tesla-v100"
      accelerator_count = 1
      instance_type     = "n1-standard-1"
      regions = [
        "asia-east1",
        "europe-west4",
        "us-central1",
        "us-east1",
        "us-west1",
      ]
    }
    a100 = {
      accelerator_type  = "nvidia-tesla-a100"
      accelerator_count = 1
      instance_type     = "a2-highgpu-1g"
      regions = [
        "asia-northeast1",
        "asia-northeast3",
        "asia-southeast1",
        "europe-west4",
        "us-central1",
        "us-east1",
        "us-west1",
        "us-west4",
      ]
    }
  }
  gpu_regions = distinct(flatten([
    for gpu_name, gpu_params in local.gpus : [
      for region in gpu_params.regions : {
        gpu    = gpu_name
        region = region
      }
    ]
  ]))
}

resource "google_compute_instance_template" "m" {
  for_each     = local.gpus
  name         = "m-${each.key}"
  machine_type = each.value.instance_type
  guest_accelerator {
    type  = each.value.accelerator_type
    count = each.value.accelerator_count
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

resource "google_compute_region_instance_group_manager" "m" {
  for_each                         = { for entry in local.gpu_regions : "${entry.gpu}.${entry.region}" => entry }
  region                           = each.value.region
  name                             = "${each.value.gpu}-${each.value.region}"
  base_instance_name               = "m-${each.value.gpu}"
  distribution_policy_target_shape = "ANY"
  target_size                      = 16

  version {
    instance_template = google_compute_instance_template.m[each.value.gpu].id
  }
}
