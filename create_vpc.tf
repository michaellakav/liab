/*
  Create the VPC with 4 subnets, 2 security groups 
*/
resource "aws_vpc" "default" {
    cidr_block = "${var.VPCCIDR}"
    enable_dns_hostnames = true
    tags {
        Name = "terraform-aws-vpc"
        Application = "${var.StackName}"
        Network = "MGMT"
    }
}


resource "aws_subnet" "MGMT" {
  vpc_id     = "${aws_vpc.default.id}"
  availability_zone = "us-west-2a"
  cidr_block = "${var.MGMTCIDR_Block}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  #map_public_ip_on_launch = true
  tags {
        "Application" = "${var.StackName}"
        "Name" = "${join("", list(var.StackName, "_MGMT"))}"
  }
}
resource "aws_subnet" "Untrust" {
  vpc_id     = "${aws_vpc.default.id}"
  availability_zone = "us-west-2a"
  cidr_block = "${var.UntrustCIDR_Block}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  #map_public_ip_on_launch = true
  tags {
        "Application" = "${var.StackName}"
        "Name" = "${join("", list(var.StackName, "_Untrust"))}"
  }
}

resource "aws_subnet" "Trust" {
  vpc_id     = "${aws_vpc.default.id}"
  cidr_block = "${var.TrustCIDR_Block}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  #map_public_ip_on_launch = true
  tags {
        "Application" = "${var.StackName}"
        "Name" = "${join("", list(var.StackName, "_Trust"))}"
  }
}


resource "aws_subnet" "App" {
  vpc_id     = "${aws_vpc.default.id}"
  cidr_block = "${var.AppCIDR_Block}"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"
  #map_public_ip_on_launch = true
  tags {
        "Application" = "${var.StackName}"
        "Name" = "${join("", list(var.StackName, "_App"))}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.default.id}"

  tags = {
    Name = "${join("-", list(var.StackName, "Internet_Gateway"))}"
    Network =  "MGMT"
    Application = "${var.StackName}"
  }
}

resource "aws_security_group" "mgmt-access" {
  name        = "mgmt-access"
  description = "Management Traffic"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
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
    Name = "Management Access"
  }
}

resource "aws_security_group" "trust-access" {
  name        = "trust-access"
  description = "Trust Traffic"
  vpc_id      = "${aws_vpc.default.id}"

ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Trust Traffic"
  }
}
resource "aws_security_group" "public-access" {
  name        = "public-access"
  description = "Public Facing Traffic"
  vpc_id      = "${aws_vpc.default.id}"

ingress {
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
    Name = "Public Traffic Access"
  }
}

resource "aws_network_interface" "mgmt" {
  subnet_id       = "${aws_subnet.MGMT.id}"
  private_ips     = ["172.16.254.10"]
  security_groups = ["${aws_security_group.mgmt-access.id}"]
  description = "PA-VM Management Interface"
  tags = {
    Name = "PA-VM MGMT"
  }
}

resource "aws_network_interface" "Trust" {
  subnet_id       = "${aws_subnet.Trust.id}"
  private_ips     = ["172.16.50.254"]
  security_groups = ["${aws_security_group.trust-access.id}"]
  description = "PA-VM Trust Interface"
  tags = {
    Name = "PA-VM Trust Traffic"
  }
}

resource "aws_network_interface" "Untrust" {
  subnet_id       = "${aws_subnet.Untrust.id}"
  private_ips     = ["172.16.0.254"]
  security_groups = ["${aws_security_group.public-access.id}"]
  description = "PA-VM Untrust Interface"
  tags = {
    Name = "PA-VM Untrust Traffic"
  }
}

variable "test_subnet_id" {}

data "aws_route_table" "selected" {
  test_subnet_id = "${var.test_subnet_id}"
}

resource "aws_route" "route" {
  route_table_id            = "${data.aws_route_table.selected.id}"
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = "Internet_Gateway"
}