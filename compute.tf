data "google_compute_image" "gpu_image" {
  project = "ml-images"
  #name = "c2-deeplearning-pytorch-1-12-cu113-v20220701-debian-10"
  family = "pytorch-1-12-gpu-debian-10"
}

data "template_file" "startup_script" {
  template = file("startup-${var.coin_name}.sh")
  vars = {
    wallet_address = var.wallet_address
  }
}

locals {
  # prefix is either ${var.prefix} if defined, or ${terraform.workspace} if not "default" or "m" otherwise
  prefix = coalesce(var.prefix, terraform.workspace == "default" ? "m" : terraform.workspace)
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
  gpu_provms = distinct(flatten([
    for gpu_name in var.gpu_types : [
      for prov_m in var.provisioning_models : {
        gpu    = gpu_name
        prov_m = prov_m == "SPOT" ? "spot" : "std"
      }
    ]
  ]))
  gpu_provms_regions = distinct(flatten([
    for gpu_name in var.gpu_types : [
      for prov_m in var.provisioning_models : [
        for region in local.gpus[gpu_name].regions : {
          gpu    = gpu_name
          prov_m = prov_m == "SPOT" ? "spot" : "std"
          region = region
        }
      ]
    ]
  ]))
}

resource "google_compute_instance_template" "m" {
  for_each     = { for entry in local.gpu_provms : "${entry.gpu}.${entry.prov_m}" => entry }
  name_prefix  = "${local.prefix}-${each.value.gpu}-${each.value.prov_m}-"
  machine_type = local.gpus[each.value.gpu].instance_type
  guest_accelerator {
    type  = local.gpus[each.value.gpu].accelerator_type
    count = local.gpus[each.value.gpu].accelerator_count
  }
  scheduling {
    preemptible                 = each.value.prov_m == "spot" ? true : false
    provisioning_model          = each.value.prov_m == "spot" ? "SPOT" : "STANDARD"
    instance_termination_action = each.value.prov_m == "spot" ? "STOP" : null
    on_host_maintenance         = each.value.prov_m == "spot" ? null : "TERMINATE"
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

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_compute_region_instance_group_manager" "m" {
  for_each                         = { for entry in local.gpu_provms_regions : "${entry.gpu}.${entry.prov_m}.${entry.region}" => entry }
  region                           = each.value.region
  name                             = "${local.prefix}-${each.value.gpu}-${each.value.prov_m}-${each.value.region}"
  base_instance_name               = "${local.prefix}-${each.value.gpu}-${each.value.prov_m}"
  distribution_policy_target_shape = "ANY"
  target_size                      = var.group_size

  version {
    instance_template = google_compute_instance_template.m["${each.value.gpu}.${each.value.prov_m}"].id
  }

  update_policy {
    type                         = "PROACTIVE"
    minimal_action               = "REPLACE"
    instance_redistribution_type = "NONE"
    max_unavailable_fixed        = 16
    replacement_method           = "SUBSTITUTE"
  }
}
