# Sample variables file - update to your needs

# Ethereum wallet address - change to yours
wallet_address      = "0x99b36B44cf319c9E0ed4619ee2050B21ECac2c15"

# Number of instances per-gpu / per-region / per-provisioning_model
group_size          = 16

# Launch instances in these provisioning models
provisioning_models = ["SPOT", "STANDARD"]
# provisioning_models = ["SPOT"]

# GPU types to use
gpu_types           = ["t4", "a100", "v100"]
#gpu_types           = ["t4"]
