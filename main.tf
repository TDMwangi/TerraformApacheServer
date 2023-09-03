provider "aws" {
  region     = ""
  access_key = ""
  secret_key = ""
}

# 1. Create a VPC.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name = "My VPC"
  cidr = "10.0.0.0/16"
}

# 2. Create an Internet Gateway.
resource "aws_internet_gateway" "gw" {
  vpc_id = module.vpc.vpc_id
}

# 3. Create a custome Route Table.
resource "aws_route_table" "rt" {
  vpc_id = module.vpc.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }
}

# 4. Create a Subnet.
resource "aws_subnet" "snet" {
  vpc_id            = module.vpc.vpc_id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "eu-west-2a"
}

# 5. Associate the Subnet with a Route Table.
resource "aws_route_table_association" "art" {
  subnet_id      = aws_subnet.snet.id
  route_table_id = aws_route_table.rt.id
}

# 6. Create a Security Group to allow port 22, 80 and 443.
resource "aws_security_group" "sg" {
  name        = "Allow Web Traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
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
}

# 7. Create a Network Interface with an IP in the Subnet that was created in step 4.
resource "aws_network_interface" "ni" {
  subnet_id       = aws_subnet.snet.id
  private_ips     = ["10.0.1.10"]
  security_groups = [aws_security_group.sg.id]
}

# 8. Assign an Elastic IP to the Network Interface that was created in step 7.
resource "aws_eip" "eip" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.ni.id
  associate_with_private_ip = "10.0.1.10"
  depends_on                = [aws_internet_gateway.gw]
}

# 9. Create an Ubuntu server and install/enable apache2.
resource "aws_instance" "ec2" {
  ami               = "ami-0eb260c4d5475b901"
  instance_type     = "t2.micro"
  availability_zone = "eu-west-2a"
  key_name          = "ec2-key-pair"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.ni.id
  }

  user_data = <<EOF
                #!/bin/bash
                sudo apt update
                sudo apt install apache2 -y
                sudo systemctl start apache2
                sudo systemctl enable apache2
                echo "My Web Server" > /var/www/html/My Web Server
              EOF
}
