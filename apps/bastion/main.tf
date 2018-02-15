variable env                            {}
variable vpc_id                         {}
variable instance_type                  { default = "t2.micro" }
variable key_name                       {}
variable subnets                        { type = "list" }
variable allow_security_groups          { type = "list" }
variable allow_security_groups_count    {} // https://github.com/hashicorp/terraform/issues/10857
variable allow_cidr_block               {}

data "aws_ami" "ubuntu" {
    owners      = ["099720109477"] # Canonical
    most_recent = true

    filter {
        name    = "name"
        values  = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
    }
}

resource "aws_security_group" "bastion" {
    name    = "${var.env}-bastion"
    vpc_id  = "${var.vpc_id}"

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    egress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = ["${var.allow_cidr_block}"]
    }

    tags {
        Name    = "${var.env}-bastion"
        Env     = "${var.env}"
    }
}

resource "aws_security_group_rule" "bastion_internal" {
    count                       = "${var.allow_security_groups_count}"

    security_group_id           = "${element(var.allow_security_groups, count.index)}"
    type                        = "ingress"
    from_port                   = 22
    to_port                     = 22
    protocol                    = "tcp"
    source_security_group_id    = "${aws_security_group.bastion.id}"
}

resource "aws_instance" "bastion" {
    count                       = "${length(var.subnets)}"

    ami                         = "${data.aws_ami.ubuntu.id}"
    instance_type               = "${var.instance_type}"
    subnet_id                   = "${element(var.subnets, count.index)}"
    vpc_security_group_ids      = ["${aws_security_group.bastion.id}"]
    associate_public_ip_address = true
    key_name                    = "${var.key_name}"

    lifecycle {
        ignore_changes = [
            "ami"
        ]
    }
    
    tags = {
        Name    = "${var.env}-bastion"
        Env     = "${var.env}"
    }
}

output "security_group_id" {
    value = "${aws_security_group.bastion.id}"
}
