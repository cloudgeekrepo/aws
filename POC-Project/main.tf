
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_ami" "nat" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami-vpc-nat-2018.03.0.2020*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"] # Canonical
}

############# VPC Creation #####################
resource "aws_vpc" "demovpc" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "demovpc"
  }
}

#### Internet Gateway #####################

resource "aws_internet_gateway" "demogw" {
  vpc_id = aws_vpc.demovpc.id

  tags = {
    Name = "demoigw"
  }
}


################ Private Subnets ############

resource "aws_subnet" "private" {
  count             = var.private_subnet_count
  vpc_id            = aws_vpc.demovpc.id
  cidr_block        = cidrsubnet("${aws_vpc.demovpc.cidr_block}", 8, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Private-Subnet-${count.index + 1}"
  }
}

################ Public Subnets ########################

resource "aws_subnet" "public" {
  count             = var.public_subnet_count
  vpc_id            = aws_vpc.demovpc.id
  cidr_block        = cidrsubnet("${aws_vpc.demovpc.cidr_block}", 8, count.index + var.private_subnet_count)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "Public-Subnet-${count.index + 1}"
  }
}

#############Route Table - Public Subnet ###############

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.demovpc.id


  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demogw.id
  }

  tags = {
    Name = "Public-Route-Table"
  }
}

#############Route Table - Public Subnet- Association ###############

resource "aws_route_table_association" "public" {
  count          = var.public_subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

#################### Security groups ################################

####### Internal SG

resource "aws_security_group" "internal" {
  name        = "allow_internal_traffic"
  description = "Allow internal traffic"
  vpc_id      = aws_vpc.demovpc.id

  ingress {
    description = "Internal Traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.demovpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_internal"
  }
}

###### External SG


resource "aws_security_group" "external" {
  name        = "allow_external_traffic"
  description = "Allow external traffic"
  vpc_id      = aws_vpc.demovpc.id

  ingress {
    description = "External Traffic"
    from_port   = 22
    to_port     = 22
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
    Name = "allow_external"
  }
}

############## NAT instance ############################

resource "aws_instance" "nat" {
  ami                         = data.aws_ami.nat.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public[0].id
  key_name                    = var.key_name
  source_dest_check           = false
  associate_public_ip_address = true
  iam_instance_profile        = "var.iam_profile_name"
  vpc_security_group_ids      = [aws_security_group.external.id, aws_security_group.internal.id]

  tags = {
    Name = "demo-nat-instance"
  }
}

#############Route Table - Private Subnet ###############

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.demovpc.id


  route {
    cidr_block  = "0.0.0.0/0"
    instance_id = aws_instance.nat.id
  }

  tags = {
    Name = "Private-Route-Table"
  }
}

#############Route Table - Private Subnet- Association ###############

resource "aws_route_table_association" "private" {
  count          = var.private_subnet_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}
#####################################################################

############## DemoAPP instance ############################

resource "aws_instance" "demoapp" {
  ami                         = "ami-0affd4508a5d2481b"
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.private[0].id
  key_name                    = var.key_name
  associate_public_ip_address = false
  iam_instance_profile        = "var.iam_profile_name"
  vpc_security_group_ids      = [aws_security_group.internal.id]
  user_data                   = file("userdata.sh")

  tags = {
    Name = "demo-app-instance"
  }
}
