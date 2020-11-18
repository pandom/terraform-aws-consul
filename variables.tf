variable hostname {
  type    = string
  default = "consul"
}
variable nomad_hostname {
  type    = string
  default = "nomad"
}

variable key_name {
  type    = string
  default = "burkey"
}

variable tags {
  type = map
  default = {
    TTL   = "48"
    owner = "Burkey"
    demo = "ATO"
  }
}

variable instance_type {
  type    = string
  default = "t2.medium"
}

variable slack_webhook {
  type    = string
  default = ""
}

variable private_ip {
  type    = string
  default = "10.0.111.162"
}

variable consul_datacenter {
  type    = string
  default = "AWS"
}

variable my_cidrs {
  type = list
  default = []
}

variable consul_version {
  type = string
  default = ""
}
variable vault_version {
  type = string
  default = ""
}
variable nomad_version {
  type = string
  default = ""
}