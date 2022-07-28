data "google_compute_image" "gpu_image" {
  family = "gpu-1"
}

resource "google_compute_instance" "gpu_instance" {
  name         = "tf-instance"
  machine_type = "n1-standard-1"
  guest_accelerator = [{
    type  = "nvidia-tesla-t4"
    count = 1
  }]
  scheduling {
    preemptible        = true
    provisioning_model = "SPOT"
    automatic_restart  = false
  }

  metadata_startup_script = file("startup.sh")

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
