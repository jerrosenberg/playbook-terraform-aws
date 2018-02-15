# Variables
variable env {}
variable cidr_prefix { default = "10.0" }
variable availability_zones { type = "list" }

# Each network group is 4 networks wide to support up to 4 availability zones per group.
#   Allocation:
#       (12) /22 groups from   .0-.192 support 1,024 addresses per network
#        (6) /23 groups from .192-.240 support   512 addresses per network
#       (16) /24 groups from .240-.255 support   256 addresses per network
variable network_groups {
  type = "map"
  default = {
    # /22 networks
    dmz = "0"
    app = "16"

    # /24 networks
    rds = "240"
  }
}

locals {
    cidr_block = "${var.cidr_prefix}.0.0/16"
}

# VPC
resource "aws_vpc" "main" {
    cidr_block              = "${local.cidr_block}"
    enable_dns_hostnames    = true

    tags {
      Name = "${var.env}"
    }
}

# DMZ Network
resource "aws_subnet" "dmz" {
    count = "${length(var.availability_zones)}"

    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.cidr_prefix}.${var.network_groups["dmz"] + (4 * count.index)}.0/22"
    availability_zone = "${var.availability_zones[count.index]}"

    tags {
      Name = "${var.env}-dmz-${var.availability_zones[count.index]}"
    }
}

resource "aws_internet_gateway" "gateway" {
    vpc_id = "${aws_vpc.main.id}"

    tags {
      Name = "${var.env}-gateway"
    }
}

resource "aws_route_table" "dmz" {
    vpc_id = "${aws_vpc.main.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.gateway.id}"
    }

    tags {
      Name = "${var.env}-dmz-route-table"
    }
}

resource "aws_route_table_association" "dmz" {
    count = "${length(var.availability_zones)}"

    route_table_id = "${aws_route_table.dmz.id}"
    subnet_id = "${element(aws_subnet.dmz.*.id, count.index)}"
}

resource "aws_eip" "nat" {
    count = "${length(var.availability_zones)}"
    
    vpc = true
}

resource "aws_nat_gateway" "nat" {
    depends_on = ["aws_internet_gateway.gateway"]
    count = "${length(var.availability_zones)}"

    allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
    subnet_id = "${element(aws_subnet.dmz.*.id, count.index)}"
}

# App Network
resource "aws_subnet" "app" {
    count = "${length(var.availability_zones)}"

    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.cidr_prefix}.${var.network_groups["app"] + (4 * count.index)}.0/22"
    availability_zone = "${var.availability_zones[count.index]}"

    tags {
      Name = "${var.env}-app-${var.availability_zones[count.index]}"
    }
}

resource "aws_route_table" "app" {
    count = "${length(var.availability_zones)}"

    vpc_id = "${aws_vpc.main.id}"

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = "${element(aws_nat_gateway.nat.*.id, count.index)}"
    }

    tags { 
        Name = "${var.env}-app-route-table-${count.index}"
    }
}

resource "aws_route_table_association" "app" {
    count = "${length(var.availability_zones)}"

    route_table_id = "${element(aws_route_table.app.*.id, count.index)}"
    subnet_id = "${element(aws_subnet.app.*.id, count.index)}"
}

# RDS Network
resource "aws_subnet" "rds" {
    count = "${length(var.availability_zones)}"

    vpc_id = "${aws_vpc.main.id}"
    cidr_block = "${var.cidr_prefix}.${var.network_groups["rds"] + count.index}.0/24"
    availability_zone = "${var.availability_zones[count.index]}"

    tags {
      Name = "${var.env}-rds-${var.availability_zones[count.index]}"
    }
}

# Outputs
output "vpc_id" {
    value = "${aws_vpc.main.id}"
}

output "cidr_block" {
    value = "${local.cidr_block}"
}

output "dmz_subnets" {
    value = ["${aws_subnet.dmz.*.id}"]
}

output "app_subnets" {
    value = ["${aws_subnet.app.*.id}"]
}

output "rds_subnets" {
    value = ["${aws_subnet.rds.*.id}"]
}