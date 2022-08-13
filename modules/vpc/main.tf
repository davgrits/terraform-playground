terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "main_vpc"
	Project = "david_grits"
  }
}

# Create public subnet1 in availability zone a
resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet1"
	Project = "david_grits"
  }
}

# Create public subnet2 in availability zone b
resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet2"
	Project = "david_grits"
  }
}

# Create private subnet1 in availability zone a
resource "aws_subnet" "private_subnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet1"
	Project = "david_grits"
  }
}

# Create private subnet2 in availability zone b
resource "aws_subnet" "private_subnet2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = false

  tags = {
    Name = "private-subnet2"
	Project = "david_grits"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "internet gateway"
	Project = "david_grits"
  }
}

# Create Public Route Table
resource "aws_route_table" "public_subnets_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public subnets route table"
	Project = "david_grits"
  }
}

# Create route table association of public subnet1
resource "aws_route_table_association" "internet_for_public_sub1" {
  route_table_id = aws_route_table.public_subnets_rt.id
  subnet_id      = aws_subnet.public_subnet1.id
}

# Create route table association of public subnet2
resource "aws_route_table_association" "internet_for_public_sub2" {
  route_table_id = aws_route_table.public_subnets_rt.id
  subnet_id      = aws_subnet.public_subnet2.id
}

# Create Elastic IP for NAT gateway1
  resource "aws_eip" "eip_natgw1" {
  count = "1"
}

# Create Elastic IP for NAT gateway2
  resource "aws_eip" "eip_natgw2" {
  count = "1"
}

# Create NAT gateway1
resource "aws_nat_gateway" "natgateway_1" {
  count         = "1"
  allocation_id = aws_eip.eip_natgw1[count.index].id
  subnet_id     = aws_subnet.public_subnet1.id
}

# Create NAT gateway2
resource "aws_nat_gateway" "natgateway_2" {
  count         = "1"
  allocation_id = aws_eip.eip_natgw1[count.index].id
  subnet_id     = aws_subnet.public_subnet2.id
}

# Create private route table for private subnet1
resource "aws_route_table" "private_subnet1_rt" {
  count  = "1"
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgateway_1[count.index].id
  }
  tags = {
    Name = "private subnet1 route table" 
	Project = "david_grits"
 }
}

# Create private route table for private subnet2
resource "aws_route_table" "private_subnet2_rt" {
  count  = "1"
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.natgateway_2[count.index].id
  }
  tags = {
    Name = "private subnet2 route table" 
	Project = "david_grits"
 }
}

# Create route table association beetwen private subnet1 & NAT gateway1
resource "aws_route_table_association" "private_subnet1_to_natgw1" {
  count          = "1"
  route_table_id = aws_route_table.private_subnet1_rt[count.index].id
  subnet_id      = aws_subnet.private_subnet1.id
}

# Create route table association beetwen private subnet2 & NAT gateway2
resource "aws_route_table_association" "private_subnet1_to_natgw2" {
  count          = "1"
  route_table_id = aws_route_table.private_subnet2_rt[count.index].id
  subnet_id      = aws_subnet.private_subnet2.id
}
