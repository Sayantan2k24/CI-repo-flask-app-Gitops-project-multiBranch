# VPC
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

# Declare the data source
data "aws_availability_zones" "available" {}

# Subnet
resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Default subnet for ${data.aws_availability_zones.available.names[0]}"
  }
}

# Security Group (only defines the group itself)
resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS and SSH traffic"
  vpc_id      = aws_default_vpc.default.id

  tags = {
    Name = "allow_tls"
  }
}

# Ingress rules - modular way
resource "aws_vpc_security_group_ingress_rule" "allow_tls_ports" {
  for_each = toset(["22", "8080"])

  security_group_id = aws_security_group.allow_tls.id
  description       = "Allow port ${each.key} from anywhere"
  from_port         = each.key
  to_port           = each.key
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

# Egress rule - allow all outbound
resource "aws_vpc_security_group_egress_rule" "allow_all_egress" {
  security_group_id = aws_security_group.allow_tls.id
  description       = "Allow all outbound traffic"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# SSH Key
resource "aws_key_pair" "jenkins-key" {
  key_name   = "jenkins-key"
  public_key = file("${path.module}/ssh-keys/id_rsa.pub")
}

# EC2 Instance
resource "aws_instance" "jenkins_server" {
  ami                    = "ami-07378eee6a8e82f97"  # rhel9 in ap-south-1 region
  instance_type          = "t2.medium"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  key_name               = aws_key_pair.jenkins-key.key_name

  tags = {
    Name = "jenkins-server"
  }
}

# Provisioner (copy + run install_jenkins.sh)
resource "null_resource" "configure_jenkins" {

  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("${path.module}/ssh-keys/id_rsa")
    host        = aws_instance.jenkins_server.public_ip
  }

  provisioner "file" {
    source      = "./install_jenkins.sh"
    destination = "/tmp/install_jenkins.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/install_jenkins.sh",
      "sh /tmp/install_jenkins.sh"
    ]
  }

  depends_on = [aws_instance.jenkins_server]
}
