
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "main"
  }
}
resource "aws_subnet" "subnet1" {
   vpc_id     = "${aws_vpc.main.id}"
   cidr_block = "10.0.1.0/24"
 


  tags  =  {
    Name = "app-subnet-1"
    }
 }
 resource "aws_subnet" "subnet2" {
   vpc_id     = "${aws_vpc.main.id}"
   cidr_block = "10.0.2.0/24"
  


     tags  =  {
      Name = "elb-subnet-2"
     }
   }
resource "aws_internet_gateway" "main-igw" {
   vpc_id = "${aws_vpc.main.id}"

  tags = {
   Name = "main-igw"
   }
   }

resource "aws_eip" "nat" {
}

resource "aws_nat_gateway" "main-natgw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.subnet2.id}"

  tags = {
    Name = "main-nat"
  }
}

resource "aws_route_table" "main-public-rt" {
  vpc_id = "${aws_vpc.main.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.main-igw.id}"
  }

  tags = {
    Name = "main-public-rt"
  }
}


resource "aws_route_table" "main-private-rt" {
  vpc_id = "${aws_vpc.main.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.main-natgw.id}"
  }

  tags  = {
    Name = "main-private-rt"
  }
}
resource "aws_route_table_association" "public-assoc-1" {
  subnet_id      = "${aws_subnet.subnet1.id}"
  route_table_id = "${aws_route_table.main-public-rt.id}"
}

resource "aws_route_table_association" "private-assoc-2" {
  subnet_id      = "${aws_subnet.subnet2.id}"
  route_table_id = "${aws_route_table.main-private-rt.id}"
}

resource "aws_instance" "web" {
  ami           = "ami-06878d265978313ca"
  instance_type = "t2.micro"
  vpc_security_group_ids      = ["${aws_security_group.bastion-sg.id}"]
  associate_public_ip_address = true
  subnet_id = aws_subnet.subnet1.id

  
  user_data = <<-EOL
  #!/bin/bash -xe
  sudo su
  apt update
  apt-get install nginx -y
  EOL
  tags = {
    Name = "HelloWorld"
  }
}


resource "aws_security_group" "bastion-sg" {
  name   = "bastion-security-group"
##  vpc_id = "${aws_default_vpc.default.id}"
   vpc_id = "${aws_vpc.main.id}"

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0 
    to_port     = 0 
    cidr_blocks = ["0.0.0.0/0"]
  }
}