variable "region" {
  default = "us-east-1"
}

variable "key_name"               {}
variable "bastion_key_name"       { default = "bastion" }

variable availability_zones {
  default = ["us-east-1a"]
}

terraform {
  backend "s3" {
    bucket = "jro-terraform-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = "${var.region}"
}

module "network" {
  source = "./network"

  env =                 "${terraform.workspace}"
  availability_zones =  ["${var.availability_zones}"]
}

module "bastion" {
  source    = "./apps/bastion"

  env       = "${terraform.workspace}"
  vpc_id    = "${module.network.vpc_id}"
  subnets   = "${module.network.dmz_subnets}"
  key_name  = "${var.key_name}"

  allow_cidr_block            = "${module.network.cidr_block}"
  allow_security_groups_count = 0
  allow_security_groups       = [
  ]
}

/*
module "mysql" {
  source = "./services/rds/mysql"

  env = "${terraform.workspace}"
  instance_name = "db"
  vpc_id = "${module.network.vpc_id}"
  db_subnets = "${module.network.rds_subnets}"
  allow_ingress_security_groups_count = 0 // https://github.com/hashicorp/terraform/issues/10857
  allow_ingress_security_groups = []
  instance_class = "db.t2.micro"
  allocated_storage = 5
  skip_final_snapshot_on_delete = "${terraform.workspace == "dev" ? true : false}"

  username = "CHANGEME"
  password = "CHANGEME"
}
*/