variable env {}
variable instance_name {}
variable vpc_id {}
variable db_subnets { type = "list" }
variable engine_version { default = "5.6.35" }
variable instance_class {}
variable allocated_storage {}
variable storage_type { default = "gp2" }
variable allow_ingress_security_groups_count { default = 0 } // https://github.com/hashicorp/terraform/issues/10857
variable allow_ingress_security_groups { type = "list" }
variable skip_final_snapshot_on_delete { default = false }
variable username {}
variable password {}

resource "aws_db_subnet_group" "db" {
    name_prefix = "${var.env}"
    subnet_ids = ["${var.db_subnets}"]
}

resource "aws_security_group" "db_allow_ingress" {
    name = "${var.env}-db-allow-ingress"
    vpc_id = "${var.vpc_id}"

    tags {
      Name = "${var.env}-db-allow-ingress"
    }
}

resource "aws_security_group_rule" "allow_ingress" {
    count = "${var.allow_ingress_security_groups_count}"

    security_group_id = "${aws_security_group.db_allow_ingress.id}"
    type = "ingress"
    from_port = "3306"
    to_port = "3306"
    protocol = "tcp"
    source_security_group_id = "${element(var.allow_ingress_security_groups, count.index)}"
}

resource "aws_db_instance" "db" {
    identifier_prefix = "${var.env}-${var.instance_name}"
    engine = "mysql"
    engine_version = "${var.engine_version}"
    instance_class = "${var.instance_class}"
    allocated_storage = "${var.allocated_storage}"
    storage_type = "${var.storage_type}"
    db_subnet_group_name = "${aws_db_subnet_group.db.id}"
    vpc_security_group_ids = ["${aws_security_group.db_allow_ingress.id}"]
    username = "${var.username}"
    password = "${var.password}"
    skip_final_snapshot = "${var.skip_final_snapshot_on_delete}"
}