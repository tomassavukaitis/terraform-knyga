provider "aws" {
  region = "us-east-2"
}

resource "aws_launch_template" "example" {
  image_id                    = "ami-060a84cbcb5c14844" # Amazon Linux 2 AMI
  instance_type               = "t2.micro"
  vpc_security_group_ids = [aws_security_group.apache_sg.id]


  user_data = base64encode(<<-EOF
    #!/bin/bash
    sudo set -e

    # Update packages
    sudo yum update -y

    # Install Apache (httpd)
    sudo yum install -y httpd

    # Enable and start Apache service
    sudo systemctl enable httpd
    sudo systemctl start httpd

  

    # Create a custom index.html
    sudo echo "Hello Tomas ;)" > /var/www/html/index.html

    # Adjust permissions (optional but clean)
    sudo chown apache:apache /var/www/html/index.html
    sudo chmod 755 /var/www/html/index.html
  EOF
  )
 
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "apache_sg" {
  name_prefix = "apache-sg-"

  description = "Allow HTTP (80) and SSH (22) traffic"

  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
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

variable "server_port" {
  description = "The port server will use for http requests"
  type = number
  default = 80
}

#output "public_ip" {
#  value = aws_launch_template.example.public_ip
#  description = "The public IP address of the apache server" 
#}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_autoscaling_group" "example" {
  
  max_size            = 5
  min_size            = 2
  
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.asg.arn]

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "asg-example-instance"
    propagate_at_launch = true
  }
}


resource "aws_lb" "example" {

name               = "aws-asg-example"
load_balancer_type = "application"
subnets            = data.aws_subnets.default.ids 
security_groups    = [aws_security_group.alb.id] 
}


resource "aws_lb_listener" "http" {
   load_balancer_arn = aws_lb.example.arn
   port              = 80
   protocol          = "HTTP"


  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }

  
}

resource "aws_security_group" "alb" {
  name = "terraform-exmaple-alb"

  ingress {
    from_port   = 80
    to_port     = 80
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

resource "aws_lb_target_group" "asg" {
  name     = "terraform-asg-example"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
    
    }
  
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
    path_pattern {
      values = ["*"]
    }
  }

  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }
  
}

