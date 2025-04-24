provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "example" {
  ami           = "ami-060a84cbcb5c14844"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids = [aws_security_group.instance.id]

 user_data = <<-EOF
    #!/bin/bash
    sudo wget https://busybox.net/downloads/binaries/1.28.1-defconfig-multiarch/busybox-x86_64
    sudo mv busybox-x86_64 busybox
    sudo chmod +x busybox
    sudo mv busybox /usr/local/bin/
    sudo yum install iptables -y
    sudo yum install iptables-services -y
    sudo systemctl start iptables
    sudo systemctl enable iptables
    sudo iptables -I INPUT -p tcp --dport 8080 -j ACCEPT
    sudo service iptables save
    echo "Hello Tomas ;)" > /home/ec2-user/index.html
    sudo chown ec2-user:ec2-user /home/ec2-user/index.html
    sudo chmod -R 755 /home/ec2-user
    sudo nohup /usr/local/bin/busybox httpd -f -p 8080 -h /home/ec2-user &
  EOF



  tags = {
    Name = "Terraform-example"
  }

}



resource "aws_security_group" "instance" {
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
 
  ingress {
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

}


