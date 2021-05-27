provider "aws" {
    profile = "default"
    region = "us-east-1"
}

resource "aws_default_vpc" "default" {
  
}

resource "aws_security_group" "prod_web" {
    name = "prod_web"
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

resource "aws_instance" "prod_web" {
    ami                    = "ami-0b0af3577fe5e3532"
    instance_type          = "t2.micro"

    vpc_security_group_ids = [ aws_security_group.prod_web.id ]

        tags = {
        Name : "production"
    } 
}