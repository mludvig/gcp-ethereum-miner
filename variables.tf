variable "project" {
  default = null
}

variable "credentials_file" {
  default = null
}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

variable "coin_name" {
  default = "ETC"
}

variable "wallet_address" {
  default = "0x99b36B44cf319c9E0ed4619ee2050B21ECac2c15"
}

variable "gpu_types" {
  default = ["t4", "a100", "v100"]
}

variable "group_size" {
  default = 16
}

variable "provisioning_models" {
  default = ["SPOT", "STANDARD"]
}

variable "prefix" {
  default = ""
}
