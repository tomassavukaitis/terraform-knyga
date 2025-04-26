provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "apache_server" {
  ami           = "ami-060a84cbcb5c14844" # Amazon Linux 2 AMI
  instance_type = "t2.micro"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.apache_sg.id]

  user_data = <<-EOF
    #!/bin/bash
    sudo set -e

    # Update packages
    sudo yum update -y

    # Install Apache (httpd)
    sudo yum install -y httpd

    # Enable and start Apache service
    sudo systemctl enable httpd
    sudo systemctl start httpd

    # Modify Apache config to listen on port 8080
    sudo sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf

    # Create a custom index.html
    sudo echo "Hello Tomas ;)" > /var/www/html/index.html

    # Adjust permissions (optional but clean)
    sudo chown apache:apache /var/www/html/index.html
    sudo chmod 755 /var/www/html/index.html
  EOF

  tags = {
    Name = "Apache-Tomas-Server"
  }
}

resource "aws_security_group" "apache_sg" {
  name_prefix = "apache-sg-"

  description = "Allow HTTP (80) and SSH (22) traffic"

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
    protocol    = "-1" # Allow all outbound
    cidr_blocks = ["0.0.0.0/0"]
  }
}