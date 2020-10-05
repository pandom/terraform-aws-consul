#NOMAD CONFIGURATION
bind_addr = "0.0.0.0"
advertise  {
  http = "13.211.103.60:4646"
  rpc = "13.211.103.60:4647"
  serf = "13.211.103.60:4648"
}
data_dir = "/opt/nomad/data"
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
