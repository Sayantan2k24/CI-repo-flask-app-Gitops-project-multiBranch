# VPC
# Using the default VPC 
resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

# Declare the data source
# Accessing the list of AWS Availability Zones within the same region
data "aws_availability_zones" "available" {}

# Subnets in 2 AZs
resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Default subnet for ${data.aws_availability_zones.available.names[0]}"
  }
}

resource "aws_default_subnet" "default_az2" {
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "Default subnet for ${data.aws_availability_zones.available.names[1]}"
  }
}

# Security Group
resource "aws_security_group" "secure_sg" {
  name        = "secure-sg"
  description = "Allow necessary inbound traffic"
  vpc_id      = aws_default_vpc.default.id

  tags = {
    Name = "secure-sg"
  }
}

# Rules (multiple ingress + 1 egress)
# SMTP
resource "aws_security_group_rule" "smtp" {
  type              = "ingress"
  from_port         = 25
  to_port           = 25
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secure_sg.id
  description       = "SMTP"
}

# HTTP
resource "aws_security_group_rule" "http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secure_sg.id
  description       = "HTTP"
}

# HTTPS
resource "aws_security_group_rule" "https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secure_sg.id
  description       = "HTTPS"
}

# SSH
resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secure_sg.id
  description       = "SSH"
}

# Kubernetes API Server
resource "aws_security_group_rule" "k8s_api" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secure_sg.id
  description       = "K8s API Server"
}

# NodePort Services (including Argo CD & NGINX Ingress)
resource "aws_security_group_rule" "nodeport_services" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secure_sg.id
  description       = "NodePort Services"
}

# ICMP - ping
resource "aws_security_group_rule" "icmp" {
  type              = "ingress"
  from_port         = 0
  to_port           = -1
  protocol          = "icmp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secure_sg.id
  description       = "Ping"
}

# Calico BGP
resource "aws_security_group_rule" "bgp" {
  type              = "ingress"
  from_port         = 179
  to_port           = 179
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secure_sg.id
  description       = "Calico BGP"
}

# Calico VXLAN
resource "aws_security_group_rule" "vxlan" {
  type              = "ingress"
  from_port         = 4789
  to_port           = 4789
  protocol          = "udp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secure_sg.id
  description       = "Calico VXLAN"
}

# Calico IP-in-IP
resource "aws_security_group_rule" "ipip" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "4"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secure_sg.id
  description       = "Calico IP-in-IP"
}

# Kubelet API
resource "aws_security_group_rule" "kubelet" {
  type              = "ingress"
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secure_sg.id
  description       = "Kubelet API"
}

# Typha (optional)
resource "aws_security_group_rule" "typha" {
  type              = "ingress"
  from_port         = 5473
  to_port           = 5473
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secure_sg.id
  description       = "Calico Typha"
}

resource "aws_security_group_rule" "all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.secure_sg.id
  description       = "Allow all outbound traffic"
}



# SSH Key
resource "aws_key_pair" "server-key" {
  key_name   = "k8s-server-key"
  public_key = file("../keys/id_rsa.pub")
}

# Master Node
resource "aws_instance" "k8s_master" {
  ami                    = "ami-05a5bb48beb785bf1"
  instance_type          = "t2.medium"
  subnet_id              = aws_default_subnet.default_az1.id # in 1a
  vpc_security_group_ids = [aws_security_group.secure_sg.id]
  key_name               = aws_key_pair.server-key.key_name

  root_block_device {
    volume_size           = 10
    delete_on_termination = true
  }

  tags = {
    Name = "k8s-master"
  }
}

# Slave Nodes
resource "aws_instance" "k8s_slaves" {
  count                  = 2
  ami                    = "ami-05a5bb48beb785bf1"
  instance_type          = "t2.medium"
  subnet_id              = element([aws_default_subnet.default_az1.id, aws_default_subnet.default_az2.id], count.index % 2) # count.index % 2 = 0 then select 1a, if 1 --> select 1b  
  vpc_security_group_ids = [aws_security_group.secure_sg.id]
  key_name               = aws_key_pair.server-key.key_name

  root_block_device {
    volume_size           = 10
    delete_on_termination = true
  }

  tags = {
    Name = "k8s-slave-${count.index + 1}"
  }
}

# Outputs
output "k8s_master_public_ip" {
  value = aws_instance.k8s_master.public_ip
}

output "k8s_slave_1_public_ip" {
  value = aws_instance.k8s_slaves[0].public_ip
}

output "k8s_slave_2_public_ip" {
  value = aws_instance.k8s_slaves[1].public_ip
}

# Inventory File for Ansible
resource "local_file" "inventory_creation" {
  depends_on = [aws_instance.k8s_master, aws_instance.k8s_slaves]

  content = <<-EOF
[master]
${aws_instance.k8s_master.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=../keys/id_rsa

[slaves]
%{ for slave in aws_instance.k8s_slaves[*] ~}
${slave.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=../keys/id_rsa
%{ endfor }
EOF

  filename = "../ansible-ws/inventory"
}

# Ansible Config File
resource "local_file" "configure_ansible_cfg" {
  depends_on = [local_file.inventory_creation]

  content  = <<-EOF
[defaults]
host_key_checking=False
inventory=./inventory
remote_user=ec2-user
private_key_file=../keys/id_rsa
ask_pass=false
deprecation_warnings=False

[privilege_escalation]
become=true
become_method=sudo
become_user=root
become_ask_pass=false
EOF

  filename = "../ansible-ws/ansible.cfg"
}

# Set SSH Key Permissions
resource "null_resource" "set_private_key_permissions" {
  provisioner "local-exec" {
    command = "chmod 400 ../keys/id_rsa"
  }
}

# Wait for SSH readiness
resource "null_resource" "trigger_ansible_after_sleep" {
  depends_on = [aws_instance.k8s_master, aws_instance.k8s_slaves]

  provisioner "local-exec" {
    working_dir = "../ansible-ws"
    command     = "echo 'Waiting 60 seconds for SSH to be ready...' && sleep 60"
  }
}

# Verify SSH connectivity
resource "null_resource" "verify_ansible_connectivity" {
  depends_on = [null_resource.trigger_ansible_after_sleep]

  provisioner "local-exec" {
    working_dir = "../ansible-ws"
    command     = "ansible all -m ping"
  }
}

# Run common setup
resource "null_resource" "trigger_ansible_playbook_common" {
  depends_on = [null_resource.verify_ansible_connectivity]

  provisioner "local-exec" {
    working_dir = "../ansible-ws"
    command     = "ansible-playbook rhel_common.yml"
  }
}

# Run master setup
resource "null_resource" "trigger_ansible_playbook_master" {
  depends_on = [null_resource.trigger_ansible_playbook_common]

  provisioner "local-exec" {
    working_dir = "../ansible-ws"
    command     = "ansible-playbook rhel_master.yml"
  }
}

# Wait for Calico pods
resource "null_resource" "trigger_ansible_sleep_for_calico_pods_healthy" {
  depends_on = [null_resource.trigger_ansible_playbook_master]

  provisioner "local-exec" {
    working_dir = "../ansible-ws"
    command     = "echo 'Waiting 120 seconds for Calico pods to be ready...' && sleep 120"
  }
}

# Install ArgoCD and Ingress Controller
resource "null_resource" "trigger_ansible_playbook_argocd_nginx_ingress" {
  depends_on = [null_resource.trigger_ansible_sleep_for_calico_pods_healthy]

  provisioner "local-exec" {
    working_dir = "../ansible-ws"
    command = "ansible-playbook setup-argoCD-and-nginx-ingress.yml --extra-vars='node_ip=${aws_instance.k8s_master.public_ip}'"
  }
}
