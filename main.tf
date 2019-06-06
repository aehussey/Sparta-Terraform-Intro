provider "aws" {
  region = "eu-west-1"
}


resource "aws_vpc" "aws_vpc_arthur" {
  cidr_block = "10.180.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "aehussey-vpc"
  }
}

resource "aws_subnet" "aehussey-public-subnet" {
  vpc_id = "${aws_vpc.aws_vpc_arthur.id}"
  cidr_block = "10.180.0.0/24"


  tags = {
    Name = "aehussey-public subnet"
  }
}

resource "aws_subnet" "aehussey-private-subnet" {
  vpc_id = "${aws_vpc.aws_vpc_arthur.id}"
  cidr_block = "10.180.1.0/24"


  tags = {
    Name = "aehussey-private subnet"
  }
}

resource "aws_internet_gateway" "aehussey-gw" {
  vpc_id = "${aws_vpc.aws_vpc_arthur.id}"

  tags = {
    Name = "aehussey-VPC-IGW"
  }
}

resource "aws_route_table" "aehussey-public-route-table" {
  vpc_id = "${aws_vpc.aws_vpc_arthur.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.aehussey-gw.id}"
  }

  tags = {
    Name = "aehussey-Public-Subnet-RT"
  }
}

resource "aws_route_table" "aehussey-private-route-table" {
  vpc_id = "${aws_vpc.aws_vpc_arthur.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.aehussey-gw.id}"
  }

  tags = {
    Name = "aehussey-Private-Subnet-RT"
  }
}

resource "aws_route_table_association" "aehussey-db-private-rt" {
  subnet_id = "${aws_subnet.aehussey-private-subnet.id}"
  route_table_id = "${aws_route_table.aehussey-private-route-table.id}"
}

resource "aws_security_group" "aehussey-sg-app" {
  name = "aehussey-sg-app"
  description = "Allow incoming HTTP connections & SSH access"

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks =  ["0.0.0.0/0"]
  }

  vpc_id="${aws_vpc.aws_vpc_arthur.id}"

  tags = {
    Name = "aehussey-public-sg"
  }
}

resource "aws_security_group" "aehussey-sg-db" {
  name = "vpc_test_web"
  description = "Allow incoming HTTP connections & SSH access"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["10.180.0.0/24"]
  }

  vpc_id="${aws_vpc.aws_vpc_arthur.id}"

  tags = {
    Name = "aehussey-private-sg"
  }
}

resource "aws_instance" "app_instance_arthur" {
  ami = "ami-0b45d039456f24807"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = "${aws_subnet.aehussey-public-subnet.id}"
  key_name = "${aws_key_pair.ahusseyKP.id}"
  vpc_security_group_ids = ["${aws_security_group.aehussey-sg-app.id}"]
  tags = {
    Name = "arthur-app-instance"
  }
}

resource "aws_instance" "db_instance_arthur" {
  ami = "ami-06e660b1f75657eb4"
  instance_type = "t2.micro"
  associate_public_ip_address = false
  subnet_id = "${aws_subnet.aehussey-private-subnet.id}"
  vpc_security_group_ids = ["${aws_security_group.aehussey-sg-db.id}"]
  tags = {
    Name = "arthur-db-instance"
  }
}

resource "aws_key_pair" "ahusseyKP" {
  key_name = "aeh-terraform"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}
