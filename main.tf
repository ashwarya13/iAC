terraform {

  required_providers {

    aws = {

      source = "hashicorp/aws"

      version = "~> 3.27"

    }

  }



  required_version = ">= 0.14.9"

}



provider "aws" {

  profile = "default"

  region = "us-east-1"

}

resource "aws_security_group" "allow_SSH" {

  name = "allow_SSH"

  description = "Allow SSH inbound traffic"

  #   vpc_id      = aws_vpc.main.id





  ingress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

    ipv6_cidr_blocks = ["::/0"]

    # description      = "SSH from VPC"

    # from_port        = 22

    # to_port          = 22

    # protocol         = "tcp"

    # cidr_blocks      = ["61.6.14.46/32"]

    # # ipv6_cidr_blocks = [aws_vpc.main.ipv6_cidr_block]

  }



  egress {

    from_port = 0

    to_port = 0

    protocol = "-1"

    cidr_blocks = ["0.0.0.0/0"]

    ipv6_cidr_blocks = ["::/0"]

  }

}



resource "aws_key_pair" "deployer1" {

  key_name = "deployer-key1"

  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDncB3MiNMnMSElCSYp/z+fxAo4/jc2fmsFoPVea3C2UYtKhJcaqYLD3F9+usuyUCeMUtbjo+mvzHjlhqwOZS2kdrSma1obWNQ4Ulowk6r8+lFOpqF+quUXrLvtjDQSFMLqrRXw9vh+gDE8Cz870ODDsEQm/oYoxrgseein59hjAG+aV+7QpU2OsY81bVtShLAHY0ze+LPQNomdkS8B2dy4PMEhHj/2j20h8jdJzfSxD3j/XMSJyZuDy+8L9bz29NAn+4ajHu5lsE32KvYNMZTiwtgEf45cX8QBA9FQAoYxQaFTcI+1zYhF8K89YyH+3HRZTkP0vDb58SnBaPaDah/RbgKgCaREsxxVkE8KTqHFLu9NOA1+CnWf+PiF6Jb9g1ROtaw5WbwgY4oHxVbS7TIr2AkSia6uN2FOEkj/RkupUq7Yj+zJ0oF5uvOwjUHgoaLKhg3beNX8+M2kz7PttrsQu43KsIXM6bM/0rCUVI64ZwPWG606en7gDnzmRd2nHFk= root@ip-172-31-26-78"

}



resource "aws_instance" "linux" {

  ami = "ami-0c02fb55956c7d316"

  instance_type = "t2.micro"

  key_name = aws_key_pair.deployer1.key_name

  # count         = 1

  vpc_security_group_ids = ["${aws_security_group.allow_SSH.id}"]

  tags = {

    "Name" = "Linux-Node"

    "ENV" = "Dev"

  }



  depends_on = [aws_key_pair.deployer1]



}



####### Ubuntu VM #####





resource "aws_instance" "ubuntu" {

  ami = "ami-04505e74c0741db8d"

  instance_type = "t2.micro"

  key_name = aws_key_pair.deployer1.key_name

  vpc_security_group_ids = ["${aws_security_group.allow_SSH.id}"]

  tags = {

    "Name" = "UBUNTU-Node"

    "ENV" = "Dev"

  }

  # Type of connection to be established

  connection {

    type = "ssh"

    user = "ubuntu"

    private_key = file("./deployer")

    host = self.public_ip

  }

  # Remotely execute commands to install Java, Python, Jenkins

  provisioner "remote-exec" {

    inline = [

      "sudo apt update && upgrade",

      "sudo apt install -y python3.8",

      "wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -",

      "sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ >  /etc/apt/sources.list.d/jenkins.list'",

      "sudo apt-get update",

      "sudo apt-get install -y openjdk-8-jre",

      "sudo apt-get install -y jenkins",

    ]

  }



  depends_on = [aws_key_pair.deployer1]


}
