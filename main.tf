 locals {
    ami = "ami-0c7217cdde317cfec"
    vpc_id = "vpc-0a58795060b0ac716"
    subnet_id = "subnet-081b92a3cfb26b3e7"
    ssh_user = "ubuntu"
    key_name = "id_rsa"
    private_key_path = "/home/devops/.ssh/id_rsa"
    ingress = [
        {
            port = 22
            description = "ssh port"
        },
        {
            port = 80
            description = "http"
        }
    ]
 }


 provider "aws" {
    region = "us-east-1"
 }

 resource "aws_security_group" "nginx" {
    name = "nginx_access"
    vpc_id = local.vpc_id 
    dynamic "ingress" {
        for_each = local.ingress
        content {
            description = ingress.value.description
            to_port = ingress.value.port
            from_port = ingress.value.port
            protocol = "tcp"
            cidr_blocks = ["0.0.0.0/0"]

        }
    }
    egress {
        description = "allow outbound"
        to_port = 0
        from_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

 }

output "public_ip" {
  value = aws_instance.nginx.public_ip
}



 resource "aws_instance" "nginx" {
    ami = local.ami
    subnet_id = local.subnet_id
    instance_type = "t3.micro"
    associate_public_ip_address = true 
    security_groups = [aws_security_group.nginx.id]
    key_name = local.key_name

    provisioner "remote-exec" {
        inline = ["echo 'wait until ssh is ready guys!'"]
        connection {
            type = "ssh"
            user = local.ssh_user
            private_key = file(local.private_key_path)
            host = aws_instance.nginx.public_ip
        }
    }
    provisioner "local-exec" {
        command = "ansible-playbook -i ${aws_instance.nginx.public_ip}, --private-key ${local.private_key_path} nginxplay.yml"
    }

 }