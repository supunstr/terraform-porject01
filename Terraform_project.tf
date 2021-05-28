variable "whitelist" {
    type = list(string)
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
        Name : "httpd"
    }    
}

module "web_app" {
    source = "./modules/web_application"

web_image_id         = var.web_image_id
web_instance_type    = var.web_instance_type
web_desired_capacity = var.web_desired_capacity
web_max_size         = var.web_max_size
web_min_size         = var.web_min_size
subnets              = [ aws_default_subnet.default_az1.id,aws_default_subnet.default_az2.id ]
security_groups      = [ aws_security_group.prod_web.id ]
web_app              = "prod"
}