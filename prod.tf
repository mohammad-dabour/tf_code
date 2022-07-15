variable "whitelist" {
  type = list(string)
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
variable "web_image_id" {
  type = string
}
variable "web_instance_type" {
  type = string
}


provider "aws" {

  profile = "mdabour_personal"
  region  = "us-east-1"

}

/*variable "webServer" {
  
  type = string
  default = "ami-0a5ffcdd4f4353671"
}*/


resource "aws_s3_bucket" "prod_tf_course" {
  bucket = "tf-training-20220621"
  acl    = "private"
}

resource "aws_default_vpc" "default" {}


resource "aws_security_group" "prod_web" {

  tags = {
    "terrafrom" : "true"
  }
  name        = "prod_web"
  description = "A Foo Bar Rule for training."

  ingress {
    cidr_blocks = var.whitelist
    description = "my work IP"
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80

  }

  ingress {
    cidr_blocks = var.whitelist
    description = "my work IP"
    from_port   = 443
    protocol    = "tcp"
    to_port     = 443

  }

  egress {
    cidr_blocks = var.whitelist
    description = "Outbound traffic"
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
  }

}

/*resource "aws_instance" "prod_web" {

  count         = 2
  ami           = "ami-0a5ffcdd4f4353671"
  instance_type = "t2.nano"
  vpc_security_group_ids = [
    aws_security_group.prod_web.id
  ]
  tags = {
    "terrafrom" : "true"
  }
}*/

resource "aws_default_subnet" "default_az1" {
  availability_zone = "us-east-1a"

  tags = {
    "terrafrom" : "true"
  }
}

resource "aws_elb" "prod_web" {
  name = "prod-web"
  //instances       = aws_instance.prod_web.*.id
  subnets         = [aws_default_subnet.default_az1.id, aws_default_subnet.default_bz1.id]
  security_groups = [aws_security_group.prod_web.id]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  tags = {
    "terrafrom" : "true"
  }
}

resource "aws_default_subnet" "default_bz1" {
  availability_zone = "us-east-1b"

  tags = {
    "terrafrom" : "true"
  }
}

/*resource "aws_eip_association" "prod_web" {

  instance_id   = aws_instance.prod_web.0.id
  allocation_id = aws_eip.prod_web.id

}*/
/*resource "aws_eip" "prod_web" {

  tags = {
    "terrafrom" : "true"
  }


}*/

resource "aws_launch_template" "prod_web" {
  name_prefix   = "prod-web"
  image_id      = var.web_image_id
  instance_type = var.web_instance_type

  tags = {
    "terrafrom" : "true"
  }
}

resource "aws_autoscaling_attachment" "prod_web" {
  autoscaling_group_name = aws_autoscaling_group.prod_web.id
  elb                    = aws_elb.prod_web.id

}

resource "aws_autoscaling_group" "prod_web" {
  //availability_zones  = ["us-east-1a", "us-east-1b"]
  desired_capacity    = var.web_desired_capacity
  max_size            = var.web_max_size
  min_size            = var.web_min_size
  vpc_zone_identifier = [aws_default_subnet.default_az1.id, aws_default_subnet.default_bz1.id]

  launch_template {
    id      = aws_launch_template.prod_web.id
    version = "$Latest"
  }

  tag {
    key                 = "terrafrom"
    value               = "true"
    propagate_at_launch = true
  }
}
