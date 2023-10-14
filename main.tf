

# Configure the AWS Provider

provider "aws" {
  region     = "us-east-1"
  access_key = "AKIA35EKYTSLYXP3TYEQ"
  secret_key = "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"
}

# Create VPC
resource "aws_vpc" "my-vpc" {
  cidr_block       = "10.0.0.0/16"
  tags = {
    Name = "prod-vpc"
  }
}

# Create Internet Gateway 
resource "aws_internet_gateway" "my-gw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "prod-gw"
  }
}


# Create Custom Route Table
resource "aws_route_table" "my-route-table" {
  vpc_id = aws_vpc.my-vpc.id


  # It routes all traffic (0.0.0.0/0) to an Internet Gateway (aws_internet_gateway.my-gw.id),
  # effectively making this the default route for Internet-bound traffic.

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.my-gw.id
  }

  tags = {
    Name = "prod-route-table"
  }
}


variable "subnet_prefix" {
  description = "cidr block for the subnet"
  # default = "10.0.1.0/24"
  type =  list(object({
    cidr_block  = string
    name = string
  }))
}

# Create a Subnet
resource "aws_subnet" "my-subnet-1" {
  vpc_id     = aws_vpc.my-vpc.id
  #cidr_block = "10.0.1.0/24" => without variable 
  cidr_block = var.subnet_prefix[0].cidr_block   # using variable
  availability_zone = "us-east-1a"

  tags = {
    Name = var.subnet_prefix[0].name
  }
}

resource "aws_subnet" "my-subnet-2" {
  vpc_id     = aws_vpc.my-vpc.id
  #cidr_block = "10.0.1.0/24" => without variable 
  cidr_block = var.subnet_prefix[1].cidr_block  # using variable
  availability_zone = "us-east-1a"

  tags = {
    Name = var.subnet_prefix[1].name
  }
}


# Associate subnet with Route table
resource "aws_route_table_association" "my_subnet_association" {
  subnet_id      = aws_subnet.my-subnet-1.id
  route_table_id = aws_route_table.my-route-table.id
}



# Create a security group to allow port 22, 80, and 443
resource "aws_security_group" "my_security_group" {
  name        = "my-security-group"
  description = "Allow SSH, HTTP, and HTTPS"
  vpc_id      = aws_vpc.my-vpc.id

  #ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #http
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #hhtps
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

   tags = {
    Name = "my-security-group"
  }
}


# Create a network interface with an IP in the subnet

# his approach gives you granular control over the network interfaces attached to 
# the instance and is particularly useful when you need to manage multiple network interfaces
#  or perform more advanced networking configurations.
resource "aws_network_interface" "my_network_interface" {
  subnet_id   = aws_subnet.my-subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.my_security_group.id]
}


# Assign an Elastic IP to the network interface
# EIP may require IGW to exist prior to association. Use depends_on to set an explicit dependency on the IGW.
resource "aws_eip" "my_eip" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.my_network_interface.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.my-gw]
}

## just for console output 
output "server_pubilc_ip" {
  value = aws_eip.my_eip. public_ip
}
 

# Create an AWS Linux server
resource "aws_instance" "my_instance" {
  ami = "ami-041feb57c611358bd"
  instance_type = "t2.micro"
  key_name = "abdessamad-ssh"
  availability_zone = "us-east-1a"

  # This method provides more control over network interface attachments.
  network_interface {
    # The device_index helps define the order of attachment and can be useful for controlling network behavior in instances with multiple interfaces.
    device_index = 0
    network_interface_id = aws_network_interface.my_network_interface.id
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install httpd -y
              sudo systemctl enable httpd
              sudo systemctl start httpd
              sudo bash -c "echo 'Hello guys I am here 💥💥' > /var/www/html/index.html"
              EOF

  tags = {
    Name = "MyEC2Instance-webserver"
  }

}

# just for test variables intialzing 
variable "output-print" { 
}


## just for console output 
output "server_private_ip" {
  value =  aws_instance.my_instance.private_ip
}
 

output "hello-output" {
  value =  var.output-print
}