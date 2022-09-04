# GCP Ethereum (ETH) and Ethereum Classic (ETC) Miner

Terraform template for mining _Ethereum (ETH)_ and _Ethereum Classic (ETC)_ crypto currencies on Google
Cloud Platform (GCP) GPU-enabled VM instances.

<img align="centre" src="https://upload.wikimedia.org/wikipedia/commons/thumb/5/51/Google_Cloud_logo.svg/320px-Google_Cloud_logo.svg.png"/>

<img align="right" src="https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/Ethereum_logo_2014.svg/128px-Ethereum_logo_2014.svg.png"/>

## Important!

* GCP is very sensitive about crypto mining on their platform. The scripts and
  templates presented here have been carefully crafted to bypass detection however
  as always _run it at your own risk_.

* Even more importantly: _don't change the startup script_ or you may expose yourself
  to the GCP wrath.

* Ethereum mining may not be profitable at all times and it can get _very expensive
  very quickly_ - you have been warned! Unless you've got access to a free GCP account
  it may not be the wisest thing to do!

## Medium article

Check out my blog post [**Easy Etherum mining on GCP**](https://medium.com/coinmonks/easy-ethereum-mining-on-gcp-576f0aaaeeed) for more details.

## Quick start

The easiest way to start is by using the [Google Cloud Shell](https://cloud.google.com/shell).
I assume that you already have a _GCP Project_ set up, let's say it's called `mining-project-12345`.

1. Login to your [Google Cloud Console](https://console.cloud.google.com/)

2. Open the cloud shell using the icon in the top-right corner of the console.

3. Once the shell starts up you may have to select the right project first:

        cloudshell:~$ gcloud config set project mining-project-12345
        Updated property [core/project].
        cloudshell:~ (mining-project-12345)$

4. Next we clone this GIT repository to Cloud Shell:

        cloudshell:~ (mining-project-12345)$ git clone https://github.com/mludvig/gcp-ethereum-miner.git
        Cloning into 'gcp-ethereum-miner'...
        remote: Enumerating objects: 41, done.
        remote: Counting objects: 100% (41/41), done.
        remote: Compressing objects: 100% (20/20), done.
        remote: Total 41 (delta 23), reused 39 (delta 21), pack-reused 0
        Receiving objects: 100% (41/41), 5.80 KiB | 2.90 MiB/s, done.
        Resolving deltas: 100% (23/23), done.

        cloudshell:~ (mining-project-12345)$ cd gcp-ethereum-miner
        cloudshell:~/gcp-ethereum-miner (mining-project-12345)$

5. Configure `terraform.tfvars` to your liking.

        # Ethereum (ETH) or Ethereum Classic (ETC)
        coin_name           = "ETC"

        # Ethereum wallet address
        wallet_address      = "0x99b36B44cf319c9E0ed4619ee2050B21ECac2c15"

        # Launch instances in these provisioning models (best for high availability)
        provisioning_models = ["SPOT", "STANDARD"]

        # GPU types to use
        gpu_types           = ["t4", "a100", "v100"]

        # Number of instances per-gpu / per-region / per-provisioning_model
        group_size          = 16

    A note about `group_size` - each combination of GPU type + Region + Spot/Standard mode creates
    a separate _Instance Group_ and each instance group will have the configured `group_size`.
    It means that the number of instances eventually running will be up to *group_size *
    number of instance groups*, of course only if your Service Quotas permit.

6. Now's the time to start mining!

        cloudshell:~/gcp-ethereum-miner (mining-project-12345)$ terraform init
        cloudshell:~/gcp-ethereum-miner (mining-project-12345)$ terraform apply -auto-approve

    You may be presented with a pop up saying "Authorize Cloud Shell" to make GCP API calls - click *Authorize*.

You will see how Terraform starts creating the Instance Templates and Instance Groups. 
When it's done head over to the [VM console](https://console.cloud.google.com/compute/instances)
and you should see some instances starting up. 

## GPU Quotas

If there are none check out the [Instance Groups](https://console.cloud.google.com/compute/instanceGroups/list)
console and in there the ERRORS tab in some of the IGs to figure out what's going on. 
Most likely you'll be limited by **GPU Quotas** and will see messages like:

* Instance creation failed: Quota GPUS_ALL_REGIONS exceeded. Limit 0.0 globally.
* Instance creation failed: Quota PREEMTIBLE_NVIDIA_T4_GPUS exceeded. Limit 0.0 in region us-central1.

If that's the case head to *IAM -> Quotas*, search for the above (e.g. GPUS_ALL_REGIONS) and try to get them increased.

The form will ask for a reason or justification. Needless to say that "Crypto mining" is not a good one to put forward :)

## Happy mining!
