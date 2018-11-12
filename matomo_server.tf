# matomo_server.tf
provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "matomo_server" {
  ami             = "ami-0f9351b59be17920e"                      # Ubuntu 14.04 LTS AMD64 in us-east-1
  instance_type   = "t2.micro"
  key_name        = "${aws_key_pair.matomo_server_key.key_name}"
  security_groups = ["${aws_security_group.allow_ssh.name}"]
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
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Create a container
resource "docker_container" "matomo_server" {
  image = "${docker_image.matomo.latest}"
  name  = "matomo_server"

  # restart = "unless-stopped"
  logs   = true
  attach = true

  ports {
    internal = 80
    external = 80

    protocol = "-1"
  }
}

resource "docker_image" "matomo" {
  name = "dgolant/matomo:latest"
}

output "matomo_public_dns" {
  value = "${aws_instance.matomo_server.public_dns}"
}
