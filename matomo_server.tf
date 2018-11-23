# matomo_server.tf
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "matomo_server" {
  ami             = "ami-0f9351b59be17920e"                      # Ubuntu 14.04 LTS AMD64 in us-east-1
  instance_type   = "t2.micro"
  key_name        = "${aws_key_pair.matomo_server_key.key_name}"
  security_groups = ["${aws_security_group.allow_ssh.name}"]
  

  provisioner "remote-exec" {
    when    = "destroy"
    inline = [
                "docker container stop $(docker container ls -a -q)",
                "docker rm -f $(docker ps -a -q)",
                "docker rmi -f $(docker images -a -q)",
                "docker system prune -a -f --volumes"
    ] 

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("~/.ssh/id_rsa")}"
    }
  }

# Explanations of what all the apt-get changes mean can be
#  found here https://docs.docker.com/install/linux/docker-ce/ubuntu/#install-docker-ce-1
  provisioner "remote-exec" {
    when    = "create"
    inline = [
                "sudo apt-get update",
                "sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common",
                "sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -",
                "sudo apt-key fingerprint 0EBFCD88",
                "sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\"",
                "sudo apt-get update",
                "sudo apt-cache search docker-ce",
                "sudo apt-get -y install docker-ce",
                "sudo docker pull dgolant/matomo:latest",
                "sudo docker run dgolant/matomo:latest"
    ] 

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = "${file("~/.ssh/id_rsa")}"
    }
  }
}

resource "aws_key_pair" "matomo_server_key" {
  key_name   = "matomo_server_key"
  public_key = "${file("~/.ssh/id_rsa.pub")}"
}

resource "aws_security_group" "allow_ssh" {
  name = "allow_ssh"

  # SSH access
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
}

# Configure the Docker provider 
# provider "docker" {
  # host = "unix:///var/run/docker.sock"
  # host = "${aws_instance.matomo_server.private_ip}"
# }

# Create a container
# resource "docker_container" "matomo_server" {
#   image = "${docker_image.matomo.latest}"
#   name  = "matomo_server"

#   # restart = "unless-stopped"
#   logs   = true
#   attach = true

#   ports {
#     internal = 80
#     external = 80

#     protocol = "-1"
#   }
# }

# resource "docker_image" "matomo" {
#   name = "dgolant/matomo:latest"
# }

output "matomo_public_dns" {
  value = "${aws_instance.matomo_server.public_dns}"
}
