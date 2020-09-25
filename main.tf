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
    name   = "tag:application"
    values = ["consul-${var.consul_version}"]
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

  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name

  monitoring = true
  vpc_security_group_ids = [
    local.security_group_outbound,
    local.security_group_ssh,
    module.security_group_consul.this_security_group_id
  ]

  subnet_id = local.public_subnets[0]
  tags      = var.tags
}

resource aws_route53_record "this" {
  zone_id = data.aws_route53_zone.this.id
  name    = "${var.hostname}.${data.aws_route53_zone.this.name}"
  type    = "A"
  ttl     = "300"
  records = [module.consul.public_ip[0]]
}

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

