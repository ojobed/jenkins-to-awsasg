#  VPC data



resource "aws_vpc" "vpc21" {

  cidr_block = "10.0.0.0/16"



  tags = {

    Name = "vpc21"

  }

}



# Availabiltiy Zone configuration



data "aws_availability_zones" "available" {

  state = "available"

  enable_nat_gateway   = true

  single_nat_gateway   = true

  enable_dns_hostnames = true

}



#  Subnet configuration



resource "aws_subnet" "public_subnet" {

  vpc_id                  = aws_vpc.vpc21.id

  cidr_block              = var.pub_sub_cidr[count.index]

  count                   = 2

  map_public_ip_on_launch = true

  availability_zone       = data.aws_availability_zones.available.names[count.index]

}



#  Security Group Configuration



resource "aws_security_group" "capstone_security_group" {

  name        = "capstone-security-group"

  description = "capstone Security Group"

  vpc_id      = aws_vpc.vpc21.id

  

    ingress {

    from_port        = 22

    to_port          = 22

    protocol         = "tcp"

    cidr_blocks      = ["0.0.0.0/0"]

    ipv6_cidr_blocks = ["::/0"]

	}

	

	ingress {

    description = "HTTPS from web"

    from_port   = 443

    to_port     = 443

    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]

  }



    egress {

    from_port   = 0

    to_port     = 0

    protocol    = "-1"

    cidr_blocks = ["0.0.0.0/0"]

  }

  tags = {

    Name = "capstone_security_group"

  }

}



# Internet Gateway Configuration 



resource "aws_internet_gateway" "internet_gateway" {

  vpc_id = aws_vpc.vpc21.id



  tags = {

    Name = "capstone_internet_gateway"

  }

}



# public route table configuration



resource "aws_route_table" "public_rt_capstone" {

  vpc_id = aws_vpc.vpc21.id



  route {

    cidr_block = "0.0.0.0/0"

    gateway_id = aws_internet_gateway.internet_gateway.id

  }

}



# route_table_association



resource "aws_route_table_association" "capstone-rta" {

  count 		 = 2

  subnet_id      = aws_subnet.public_subnet[count.index].id

  route_table_id = aws_route_table.public_rt_capstone.id

}







#  EC2 Instance and Apache install configuration



resource "aws_launch_configuration" "web_config" {

  name_prefix     = "web-config"

  image_id        = "ami-01c647eace872fc02"

  instance_type   = "t2.micro"

  key_name	= "myasg"

# user_data       = file("bashdata.sh")

  security_groups = [aws_security_group.capstone_security_group.id]



}



resource "aws_autoscaling_group" "capstone_asg" {



  vpc_zone_identifier       = [for i in aws_subnet.public_subnet[*] : i.id]

  launch_configuration      = aws_launch_configuration.web_config.name

  desired_capacity          = 1

  max_size                  = 2

  min_size                  = 1

  health_check_grace_period = 30

  health_check_type         = "EC2"



  tag {

    key                 = "Name"

    value               = "ec2 capstone instance"

    propagate_at_launch = true

  }



  lifecycle {

    create_before_destroy = true

  }

}
