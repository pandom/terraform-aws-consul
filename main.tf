data terraform_remote_state "this" {
  backend = "remote"

  config = {
    organization = "burkey"
    workspaces = {
      name = "terraform-aws-core"
    }
  }
}

locals {
  public_subnets          = data.terraform_remote_state.this.outputs.public_subnets
  security_group_outbound = data.terraform_remote_state.this.outputs.security_group_outbound
  security_group_ssh      = data.terraform_remote_state.this.outputs.security_group_ssh
  vpc_id                  = data.terraform_remote_state.this.outputs.vpc_id
}


data aws_route53_zone "this" {
  name         = "burkey.hashidemos.io"
  private_zone = false
}

data aws_ami "ubuntu" {
  most_recent = true

  filter {
    name   = "tag:nomad"
    values = ["${var.nomad_version}"]
  }
  filter {
    name   = "tag:vault"
    values = ["${var.vault_version}"]
  }
  filter {
    name   = "tag:consul"
    values = ["${var.consul_version}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["711129375688"] # HashiCorp account
}

module "consul" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.13.0"

  name           = var.hostname
  instance_count = 1

  private_ip = var.private_ip

  user_data_base64 = base64gzip(data.template_file.userdata.rendered)

  ami           = "ami-09eaf096889b18b99"
  instance_type = var.instance_type
  key_name      = var.key_name

  monitoring = true
  vpc_security_group_ids = [
    local.security_group_outbound,
    local.security_group_ssh,
    module.security_group_consul.this_security_group_id,
    module.security_group_nomad.this_security_group_id
  ]

  subnet_id = local.public_subnets[0]
  tags      = var.tags
}
module "nomad" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "2.13.0"

  name           = var.nomad_hostname
  instance_count = 1

  private_ip = "10.0.111.163"

  user_data_base64 = base64gzip(data.template_file.userdata.rendered)

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  monitoring = true
  vpc_security_group_ids = [
    local.security_group_outbound,
    local.security_group_ssh,
    module.security_group_consul.this_security_group_id,
    module.security_group_nomad.this_security_group_id
  ]

  subnet_id = local.public_subnets[0]
  tags      = var.tags
}
# NAME ENTRIES
resource aws_route53_record "this" {
  zone_id = data.aws_route53_zone.this.id
  name    = "${var.hostname}.${data.aws_route53_zone.this.name}"
  type    = "A"
  ttl     = "300"
  records = [module.consul.public_ip[0]]
}
resource aws_route53_record "nomad" {
  zone_id = data.aws_route53_zone.this.id
  name    = "${var.nomad_hostname}.${data.aws_route53_zone.this.name}"
  type    = "A"
  ttl     = "300"
  records = [module.consul.public_ip[0]]
}

## SECOND NOMAD

resource aws_route53_record "nomad-remote" {
  zone_id = data.aws_route53_zone.this.id
  name    = "${var.nomad_hostname}-remote.${data.aws_route53_zone.this.name}"
  type    = "A"
  ttl     = "300"
  records = [module.nomad.public_ip[0]]
}
resource aws_route53_record "consul-remote" {
  zone_id = data.aws_route53_zone.this.id
  name    = "${var.hostname}-remote.${data.aws_route53_zone.this.name}"
  type    = "A"
  ttl     = "300"
  records = [module.nomad.public_ip[0]]
}

## SECURITY GROUPS
module "security_group_consul" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "consul-http"
  description = "consul http access"
  vpc_id      = local.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 8500
      to_port     = 8500
      protocol    = "tcp"
      description = "consul ingress"
      cidr_blocks = "10.0.0.0/16,${join(",",var.my_cidrs)}"
    },
    {
      from_port   = 8300
      to_port     = 8301
      protocol    = "tcp"
      description = "consul ingress"
      cidr_blocks = "10.0.0.0/16,${join(",",var.my_cidrs)}"
    }
  ]
  tags = var.tags
}

module "security_group_nomad" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "nomad-http"
  description = "nomad http access"
  vpc_id      = local.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 4646
      to_port     = 4646
      protocol    = "tcp"
      description = "nomad ingress"
      cidr_blocks = "13.236.195.181/32,13.239.146.114/32,10.0.0.0/16,${join(",",var.my_cidrs)}"
    },
    {
      from_port   = 4647
      to_port     = 4648
      protocol    = "tcp"
      description = "nomad backend"
      cidr_blocks = "13.236.195.181/32,13.239.146.114/32,10.0.0.0/16,${join(",",var.my_cidrs)}"
    }
  ]
  tags = var.tags
}

