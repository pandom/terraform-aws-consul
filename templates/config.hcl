#NOMAD CONFIGURATION
bind_addr = "0.0.0.0"
advertise  {
  http = "3.25.211.183:4646"
  rpc = "3.25.211.183:4647"
  serf = "3.25.211.183:4648"
}
data_dir = "/var/lib/nomad"
datacenter = "DC1"
region = "prod"
authoritative_region = "prod"
enable_syslog = "true"
syslog_facility = "LOCAL0"
log_level = "INFO"
server {
  enabled          = true
  bootstrap_expect = 1
  authoritative_region = "prod"
}
# acl {
#   enabled = true
#   token_ttl = "300s"
#   policy_ttl = "600s"
# }
audit {
  enabled = true
}
