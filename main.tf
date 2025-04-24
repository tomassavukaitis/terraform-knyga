provider "aws" {
  region = "us-east-2"
}

resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

user_data = <<-EOF
              #!/bin/bash
              yum install -y busybox
              echo "Hello Tomas ;)" > index.html
              nohup busybox httpd -f -p 8080 -h /home/ec2-user &
              EOF

  tags = {
    Name = "Terraform-example"
  }



}






resource "aws_security_group" "instance" {
  

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}


