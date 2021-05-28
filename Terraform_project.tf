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
        cidr_blocks = [ "0.0.0.0/0" ]  
    }

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]  
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
    }

    tags = {
        Name : "production"
    }    
}

# creating two instances and allocate prod_web security group.
resource "aws_instance" "prod_web" {
    count = 2

    ami                    = "ami-0b0af3577fe5e3532"
    instance_type          = "t2.micro"

    vpc_security_group_ids = [ aws_security_group.prod_web.id ]

        tags = {
            Name : "production"
    } 
}

# creating elastic IP
resource "aws_eip" "prod_web_ip" {
    tags = {
        Name : "production_IP"
    } 
}

# Assinging elastic IP for second instance.
resource "aws_eip_association" "prod_web" {
    instance_id   = aws_instance.prod_web[1].id
    allocation_id = aws_eip.prod_web_ip.id

}

# Creating ELB
resource "aws_elb" "prod_web_elb" {
    name            = "prod-web-elb"
    instances       = aws_instance.prod_web.*.id
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