terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}
# Declare the data source for availablity zone depending on region specified
data "aws_availability_zones" "available" {
  state = "available"
}

#create VPC
resource "aws_vpc" "main" {
  cidr_block           = var.cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main"
    #  "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
  }
}
#create public and private subnets
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "Public subnet"
    #  "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
    #  "kubernetes.io/role/elb"                     = "1"

  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "Private subnet"
    #"kubernetes.io/cluster/${var.cluster_name}"  = "shared"
    #  "kubernetes.io/role/internal-elb"            = "1"
  }
}

#create public_1 and private_1 subnets (recommended for eks prod environment)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public1_subnet
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public subnet"
    #  "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
    #  "kubernetes.io/role/elb"                     = "1"

  }
}

resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private1_subnet
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Private subnet"
    #  "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
    #   "kubernetes.io/role/internal-elb"            = "1"
  }

}
#internet gate way
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "mainGW"
  }
}

#elastic ip for nat gateway
resource "aws_eip" "nat_eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "NAT Gateway EIP"
  }
}
resource "aws_eip" "nat_eip1" {
  vpc        = true
  depends_on = [aws_internet_gateway.gw]
  tags = {
    Name = "NAT Gateway EIP"
  }
}
# Nat gate way
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "Main Nat Gateway"
  }
}
resource "aws_nat_gateway" "nat1" {
  allocation_id = aws_eip.nat_eip1.id
  subnet_id     = aws_subnet.public_1.id

  tags = {
    Name = "Main Nat Gateway_1"
  }
}

#Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public Route table"
  }
}
#Associate between public and private Route table
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}
#Route Table for Private Subnet
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Private Route table"
  }
}

resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "Private Route table"
  }
}
#Associate between public and private Route table
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private1.id
}


###########################################################################
# create a security group
###########################################################################
resource "aws_security_group" "allow_tls" {

  name        = "appDMZ"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = var.ssh_port
    to_port     = var.ssh_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
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
    Name = "allow_tls"
  }
}

######################################################################################
# create an instance
######################################################################################
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami = data.aws_ami.ubuntu.id
  #count         = var.instance_count
  instance_type   = var.instance_type
  key_name        = var.key_name
  subnet_id       = aws_subnet.public.id
  security_groups = ["${aws_security_group.allow_tls.id}"]
  user_data       = <<EOF
          #! /bin/bash
          sudo apt update -y 
          sudo apt install docker.io -y
          sudo usermod -aG docker ubuntu  
	EOF

  associate_public_ip_address = true

  tags = {
    Name = "nodeapp"
  }

}

# ---------------------------------------------------------------------------------------------------------------------
# Provision the server using remote-exec
# ---------------------------------------------------------------------------------------------------------------------

resource "null_resource" "null_provisioner" {
  triggers = {
    public_ip = aws_instance.web.public_ip
  }

  connection {
    type        = "ssh"
    host        = aws_instance.web.public_ip
    user        = var.ssh_user
    port        = var.ssh_port
    private_key = file("legacykey1.pem")
    #   agent = true
  }


  // commands to execute on remote system
  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y", 
      "sudo apt install docker.io -y",
      "sudo groupadd docker",
      "sudo usermod -aG docker ubuntu",
      "sudo chown -R ubuntu:ubuntu /var/run/docker.sock",
      "docker run -d --name questapp -p 80:3000 --env SECRET_WORD=TwelveFactor akwa2020/nodeapp",
    ]
  }

}

##############################################################################################
# Load Balancer
##############################################################################################
# Create a new load balancer
resource "aws_elb" "app_elb" {
  name = "nodeapp-elb"
  # availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  security_groups = ["${aws_security_group.allow_tls.id}"]
  subnets         = ["${aws_subnet.public.id}", "${aws_subnet.public_1.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = [aws_instance.web.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "nodeapp_elb"
  }
}

##############################################################################################
# https Load Balancer
##############################################################################################
# Create a new load balancer
resource "aws_elb" "https_elb" {
  name = "nodeapp-httpselb"
  # availability_zones = ["us-east-2a", "us-east-2b", "us-east-2c"]
  security_groups = ["${aws_security_group.allow_tls.id}"]
  subnets         = ["${aws_subnet.public.id}", "${aws_subnet.public_1.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 443
    lb_protocol       = "https"
    ssl_certificate_id = "arn:aws:acm:us-east-2:636327228230:certificate/8dfe743c-2670-4ce7-9c26-c611564e47f8"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = [aws_instance.web.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "nodeapp_httpselb"
  }
}

