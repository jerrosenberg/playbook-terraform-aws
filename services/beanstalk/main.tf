variable env {}
variable application_name {}
variable vpc_id {}
variable instance_subnets { type = "list" }
variable elb_subnets { type = "list" }
variable instance_role {}
variable service_role {}
variable instance_type {}
variable port_outside {}
variable port_inside {}
variable solution_stack_name {
    default = "64bit Amazon Linux 2017.03 v2.7.1 running Docker 17.03.1-ce"
}
variable availability_zones {
    default = "Any 1"
}
variable min_size {
    default = "1"
}
variable max_size {
    default = "1"
}
variable associate_public_ip_address {
    default = "true"
}
variable command_deployment_policy {
    default = "Rolling"
}
variable command_batch_type {
    default = "Fixed"
}
variable command_batch_size {
    default = "1"
}
variable connection_draining_enabled {
    default = "true"
}
variable min_instances_in_service {
    default = 2
}
variable rolling_update_batch_size {
    default = 1
}

resource "aws_security_group" "app" {
    name = "${var.env}-${var.application_name}"
    vpc_id = "${var.vpc_id}"

    ingress {
        from_port = "${var.port_outside}"
        to_port = "${var.port_inside}"
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags {
      Name = "${var.env}-${var.application_name}"
    }
}

resource "aws_elastic_beanstalk_application" "app" {
  name = "${var.env}-${var.application_name}"
}

resource "aws_elastic_beanstalk_environment" "app" {
  name = "${var.env}-${var.application_name}-env"
  application = "${aws_elastic_beanstalk_application.app.name}"
  solution_stack_name = "${var.solution_stack_name}"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "IamInstanceProfile"
    value = "${var.instance_role}"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name = "VPCId"
    value = "${var.vpc_id}"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name = "AssociatePublicIpAddress"
    value = "${var.associate_public_ip_address}"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name = "Subnets"
    value = "${join(",", var.instance_subnets)}"
  }
  setting {
    namespace = "aws:ec2:vpc"
    name = "ELBSubnets"
    name = "ELBSubnets"
    value = "${join(",", var.elb_subnets)}"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "InstanceType"
    value = "${var.instance_type}"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name = "Availability Zones"
    value = "${var.availability_zones}"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name = "MinSize"
    value = "${var.min_size}"
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name = "MaxSize"
    value = "${var.max_size}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "ServiceRole"
    value = "${var.service_role}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name = "SystemType"
    value = "enhanced"
  }
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name = "RollingUpdateEnabled"
    value = "true"
  }
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name = "RollingUpdateType"
    value = "Health"
  }
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name = "MinInstancesInService"
    value = "${var.min_instances_in_service}"
  }
  setting {
    namespace = "aws:autoscaling:updatepolicy:rollingupdate"
    name = "MaxBatchSize"
    value = "${var.rolling_update_batch_size}"
  }
  setting {
    namespace = "aws:elb:loadbalancer"
    name = "CrossZone"
    value = "true"
  }
  setting {
    namespace = "aws:elb:loadbalancer"
    name = "SecurityGroups"
    value = "${aws_security_group.app.id}"
  }
  setting {
    namespace = "aws:elb:loadbalancer"
    name = "ManagedSecurityGroup"
    value = "${aws_security_group.app.id}"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "SecurityGroups"
    value = "${aws_security_group.app.id}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name = "BatchSizeType"
    value = "${var.command_batch_type}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name = "BatchSize"
    value = "${var.command_batch_size}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name = "DeploymentPolicy"
    value = "${var.command_deployment_policy}"
  }
  setting {
    namespace = "aws:elb:policies"
    name = "ConnectionDrainingEnabled"
    value = "${var.connection_draining_enabled}"
  }
}

output "application_name" {
  value = "${aws_elastic_beanstalk_application.app.name}"
}
output "environment_name" {
  value = "${aws_elastic_beanstalk_environment.app.name}"
}
output "security_group_id" {
  value = "${aws_security_group.app.id}"
}