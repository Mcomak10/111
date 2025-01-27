variable "benchmarking_ami_name_pattern" {
  # The "{{arch}}" placeholder will be filled in later.
  default = "yjit-benchmarking-{{arch}}-*"
}

variable "benchmarking_x86_instance_type" {
  default = "c7i.metal-24xl" # c7i.metal-24xl is $4.284/hour for 96 cpu 192 mem
}

variable "benchmarking_arm_instance_type" {
  default = "c7g.metal" # c7g.metal is $2.3123/hour for 64 cpu 128 mem
}

# The ubuntu source image takes up almost 2GB.
# ~/.rustup (when present) can eat 2.2GB
# Each built ruby in ~/.rubies can take 700MB - 1.5GB (minimum of 3, call it 5GB).
# Each ruby build dir is also 1.5GB (currently 3 another 5GB).
# yjit-bench and yjit-metrics add up to 1.5GB.
# The yjit-raw/benchmark-data repo is 7.5GB.
# That brings us to 24GB, add more to be sure we have plenty of room.
variable "benchmarking_volume_size_gb" {
  default = 32
}

variable "dev_ami_name_pattern" {
  # The "{{arch}}" placeholder will be filled in later.
  default = "yjit-dev-{{arch}}-*"
}

# Git credentials come from 1password and get added to the instance secrets.
variable "git_email" {
  type      = string
  sensitive = true # Not really
}

variable "git_name" {
  default = "YJIT Metrics Continuous Benchmarking Server"
}

variable "git_token" {
  type      = string
  sensitive = true
}

variable "git_user" {
  type      = string
  sensitive = true
}

# How long should permissions granted by the instance profile last?
# Benchmarking should generally finish in 4-6 hours, though currently we are
# only reading the secrets at boot time.
variable "instance_profile_session_duration_seconds" {
  default = 3600 * 8 # hours
}

# User in AWS whose access key is used to start instances and initiate benchmarks.
variable "job_bot_user_name" {
  default = "yjit-benchmark-bot"
}

variable "launch_template_name" {
  default = "yjit-benchmarking"
}

variable "region" {
  default = "us-east-2" # Ohio is for lovers (it's also the cheapest place to run metal).
}

variable "reporting_ebs_device_label" {
  # This should match the value used by packer.
  default = "yjit-reportcache" # 16-char limit
}

variable "reporting_instance_type" {
  # The timeline report has an RSS of 6GB (as of 2024-09-17).
  # Let's pass up 8GB and go up to 16GB.
  # r7i.large:       2 CPU 16 GB: 0.1323
  # r8g.large:       2 CPU 16 GB: 0.11782
  # m7i-flex.xlarge: 4 CPU 16 GB: 0.19152
  default = "r7i.large"
}

variable "reporting_ebs_name" {
  # This should match the var used by packer.
  default = "YJIT Benchmark Reporting Cache"
}

# The reporting instance does most of its disk churn on the cache volume
# (it doesn't need to build rubies) so it can be a bit smaller.
# The disk starts out at around 16 so let's give it 24
# so that there's plenty of space for upgrades, etc.
variable "reporting_root_volume_size_gb" {
  default = 24
}

variable "root_device_name" {
  default = "/dev/sda1"
}

variable "secret_name" {
  default = "yjit-benchmarking"
}

variable "ssh_key_name" {
  # The aws user needs explicit permission to import this key pair.
  default = "yjit-benchmarking-ssh"
}

variable "ssh_public_key" {
  type      = string
  sensitive = true # Not really
}

# Like the git creds this comes from 1password and gets embedded as an AWS secret.
variable "slack_token" {
  type      = string
  sensitive = true
}

variable "tags" {
  default = {
    "Project" = "YJIT"
  }
}

variable "virtualization_type" {
  default = "hvm" # Must be hvm for metal instances.
}

locals {
  timestamp = replace(timestamp(), "/[- TZ:]/", "")

  amis = tomap({
    "x86" = tomap({
      arch          = "x86_64",
      instance_type = var.benchmarking_x86_instance_type,
    }),
    "arm" = tomap({
      arch          = "arm64",
      instance_type = var.benchmarking_arm_instance_type,
    })
  })

  reporting_ebs_device_name = "/dev/xvdf" # This may get remapped to something else but it is required to be specified.
}
