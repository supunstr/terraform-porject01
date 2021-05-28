variable "whitelist" {
    type = list(string)
}
variable "web_image_id" {
    type = string
}
variable "web_instance_type" {
    type = string
}
variable "web_desired_capacity" {
    type = number
}
variable "web_max_size" {
    type = number
    }
variable "web_min_size" {
    type = number
}

provider "aws" {
    profile = "default"
    region = "us-east-1"
}

# using default VPC for buld.
resource "aws_default_vpc" "default" {}

# Selecting two subnets
resource "aws_default_subnet" "default_az1" {
    availability_zone = "us-east-1a"

    tags  = {
        "Name" : "prod_subnet"
    }
}

resource "aws_default_subnet" "default_az2" {
    availability_zone = "us-east-1b"

    tags  = {
        "Name" : "prod_subnet"
    }
}

# creating security prod_web and open port 80 and 443
resource "aws_security_group" "prod_web" {
    name        = "prod_web"
    description = "Allow http and https ports inbound and everything outbound"


    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = var.whitelist
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = var.whitelist
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = var.whitelist
    }

    tags = {
        Name : "production"
    }    
}

# Creating ELB
resource "aws_elb" "prod_web_elb" {
    name            = "prod-web-elb"
    subnets         = [ aws_default_subnet.default_az1.id,aws_default_subnet.default_az2.id ]
    security_groups = [ aws_security_group.prod_web.id ]

    listener {
      instance_port     = 80
      instance_protocol = "http"
      lb_port           = 80
      lb_protocol       = "http"
    }
      tags = {
        Name : "production_ELB"
    } 
}

# Creating AutoScaling template
resource "aws_launch_template" "prod_web_template" {
  name_prefix   = "prod-web-template"
  image_id      = var.web_image_id
  vpc_security_group_ids = [ aws_security_group.prod_web.id]
  
  instance_type = var.web_instance_type

        tags = {
        Name : "production"
    }
}

resource "aws_autoscaling_group" "prod_group" {
  vpc_zone_identifier = [ aws_default_subnet.default_az1.id,aws_default_subnet.default_az2.id  ]
  desired_capacity    = var.web_desired_capacity
  max_size            = var.web_max_size
  min_size            = var.web_min_size

  launch_template {
    id      = aws_launch_template.prod_web_template.id
    version = "$Latest"
  }
     #   tag  {
      #  Key = "Name"
       # value = "Production"
        #propagate_at_launch = true

   # }
}

resource "aws_autoscaling_attachment" "prod_web" {
  autoscaling_group_name = aws_autoscaling_group.prod_group.id
  elb                    = aws_elb.prod_web_elb.id
}