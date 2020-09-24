data template_file "userdata" {
  template = file("${path.module}/templates/userdata.yaml")

  vars = {
    ip_address = var.private_ip,
    consul_conf = base64encode(templatefile("${path.module}/templates/config.json",
      {
        consul_datacenter = var.consul_datacenter
      }
    ))
    slack_webhook = var.slack_webhook
  }
}