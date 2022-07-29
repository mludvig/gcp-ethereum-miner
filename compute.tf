data "google_compute_image" "gpu_image" {
  family = "gpu-1"
}

data "template_file" "startup_script" {
  template = file("startup.sh")
  vars = {
    wallet_address = var.wallet_address
  }
}

resource "google_compute_instance" "gpu_instance" {
  name         = "tf-instance"
  machine_type = "n1-standard-1"
  guest_accelerator = [{
    type  = "nvidia-tesla-t4"
    count = 1
  }]
  scheduling {
    preemptible                 = true
    provisioning_model          = "SPOT"
    instance_termination_action = "STOP"
    automatic_restart           = false
  }

  metadata_startup_script = data.template_file.startup_script.rendered

  boot_disk {
    initialize_params {
      image = data.google_compute_image.gpu_image.self_link
    }
  }

  network_interface {
    network = "default"
    access_config {
    }
  }
}
