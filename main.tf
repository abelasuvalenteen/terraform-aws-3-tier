# Create a VPC
resource "aws_vpc" "devops-vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "DevOps VPC"
  }
}

# Create Web Public Subnet
resource "aws_subnet" "devops-web-subnet" {
  count                   = var.item_count
  vpc_id                  = aws_vpc.devops-vpc.id
  cidr_block              = var.web_subnet_cidr[count.index]
  availability_zone       = var.availability_zone_names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "DevOps-Web-${count.index}"
  }
}

# Create Application Private Subnet
resource "aws_subnet" "devops-app-subnet" {
  count                   = var.item_count
  vpc_id                  = aws_vpc.devops-vpc.id
  cidr_block              = var.application_subnet_cidr[count.index]
  availability_zone       = var.availability_zone_names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "DevOps-Application-${count.index}"
  }
}

# Create Database Private Subnet
resource "aws_subnet" "devops-db-subnet" {
  count             = var.item_count
  vpc_id            = aws_vpc.devops-vpc.id
  cidr_block        = var.database_subnet_cidr[count.index]
  availability_zone = var.availability_zone_names[count.index]

  tags = {
    Name = "DevOps-Database-${count.index}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "devops-igw" {
  vpc_id = aws_vpc.devops-vpc.id

  tags = {
    Name = "DevOps IGW"
  }
}

# Create Web layer route table
resource "aws_route_table" "devops-web-rt" {
  vpc_id = aws_vpc.devops-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops-igw.id
  }

  tags = {
    Name = "DevOps WebRT"
  }
}

# Create Web Subnet association with Web route table
resource "aws_route_table_association" "devops_rt_association" {
  count          = var.item_count
  subnet_id      = aws_subnet.devops-web-subnet[count.index].id
  route_table_id = aws_route_table.devops-web-rt.id
}

#Create EC2 Bastion Instance
resource "aws_instance" "devops-bastion" {
  ami                         = var.ami_id
  key_name                    = aws_key_pair.devops-bastion_key.key_name
  instance_type               = var.instance_type
  availability_zone           = var.availability_zone_names[0]
  vpc_security_group_ids      = [aws_security_group.devops-bastion-sg.id]
  subnet_id                   = aws_subnet.devops-web-subnet[0].id
  associate_public_ip_address = true

    tags = {
      Name = "DevOps Bastion Host"
    }
}

resource "aws_security_group" "devops-bastion-sg" {
  name   = "devops-bastion-sg"
  vpc_id = aws_vpc.devops-vpc.id

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "devops-bastion_key" {
  key_name   = "hp@DESKTOP-DK6ONUE"
  public_key = var.public_key
}

#Create EC2 Instance
resource "aws_instance" "devops-webserver" {
  count                  = var.item_count
  ami                    = var.ami_id
  key_name               = aws_key_pair.devops-bastion_key.key_name
  instance_type          = var.instance_type
  availability_zone      = var.availability_zone_names[count.index]
  vpc_security_group_ids = [aws_security_group.devops-webserver-sg.id]
  subnet_id              = aws_subnet.devops-web-subnet[count.index].id
  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install httpd -y
              sudo service httpd start
              sudo chkconfig httpd on
              echo "<html><h1>Infra As Code sample using Terraform templates!!!</h1></html>" | sudo tee /var/www/html/index.html
              hostname -f >> /var/www/html/index.html
              EOF

  tags = {
    Name = "DevOps Web Server${count.index}"
  }
}

# Create Web Security Group
resource "aws_security_group" "devops-web-sg" {
  name        = "DevOps Web-SG"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.devops-vpc.id

  ingress {
    description = "HTTP from VPC"
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

  tags = {
    Name = "DevOps Web-SG"
  }
}

# Create Web Server Security Group
resource "aws_security_group" "devops-webserver-sg" {
  name        = "DevOps Webserver-SG"
  description = "Allow inbound traffic from ALB"
  vpc_id      = aws_vpc.devops-vpc.id

  ingress {
    description     = "Allow traffic from web layer"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.devops-web-sg.id]
  }

  ingress {
     description = "SSH from VPC"
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

  tags = {
    Name = "DevOps Webserver-SG"
  }
}


#Create EC2 Instance
resource "aws_instance" "devops-appserver" {
  count                  = var.item_count
  ami                    = var.ami_id
  key_name               = aws_key_pair.devops-bastion_key.key_name
  instance_type          = var.instance_type
  availability_zone      = var.availability_zone_names[count.index]
  vpc_security_group_ids = [aws_security_group.devops-app-sg.id]
  subnet_id              = aws_subnet.devops-app-subnet[count.index].id
  user_data              = <<-EOF
                           #!/bin/bash
                           sudo yum update -y
                           sudo yum install -y java-1.8.0-openjdk
                           EOF

  tags = {
    Name = "DevOps App Server${count.index}"
  }
}

# Create App Security Group
resource "aws_security_group" "devops-app-sg" {
  name        = "DevOps App-SG"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.devops-vpc.id

  ingress {
    description = "HTTP from WebServer"
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    security_groups = [aws_security_group.devops-webserver-sg.id]
  }

    ingress {
       description = "SSH from VPC"
       from_port   = 22
       to_port     = 22
       protocol    = "tcp"
       cidr_blocks = ["0.0.0.0/0"]
    }

  egress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DevOps App-SG"
  }
}


#Create Database Security Group
resource "aws_security_group" "devops-db-sg" {
  name        = "DevOps Database-SG"
  description = "Allow inbound traffic from application layer"
  vpc_id      = aws_vpc.devops-vpc.id

  ingress {
    description     = "Allow traffic from application layer"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.devops-webserver-sg.id]
  }

  egress {
    from_port   = 32768
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DevOps Database-SG"
  }
}

#Create Application Load Balancer
resource "aws_lb" "devops-external-elb" {
  name               = "DevOps-External-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.devops-web-sg.id]
  subnets            = [aws_subnet.devops-web-subnet[0].id, aws_subnet.devops-web-subnet[1].id]
}

resource "aws_lb_target_group" "devops-external-elb" {
  name     = "DevOps-ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.devops-vpc.id
}

resource "aws_lb_target_group_attachment" "devops-external-elb" {
  count            = var.item_count
  target_group_arn = aws_lb_target_group.devops-external-elb.arn
  target_id        = aws_instance.devops-webserver[count.index].id
  port             = 80

  depends_on = [
    aws_instance.devops-webserver[1]
  ]
}

resource "aws_lb_listener" "devops-external-elb" {
  load_balancer_arn = aws_lb.devops-external-elb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.devops-external-elb.arn
  }
}

#Create database
resource "aws_db_instance" "devops-default" {
  allocated_storage      = var.rds_instance.allocated_storage
  db_subnet_group_name   = aws_db_subnet_group.devops-default.id
  engine                 = var.rds_instance.engine
  engine_version         = var.rds_instance.engine_version
  instance_class         = var.rds_instance.instance_class
  multi_az               = var.rds_instance.multi_az
  name                   = var.rds_instance.name
  username               = var.user_information.username
  password               = var.user_information.password
  skip_final_snapshot    = var.rds_instance.skip_final_snapshot
  vpc_security_group_ids = [aws_security_group.devops-db-sg.id]
}

resource "aws_db_subnet_group" "devops-default" {
  name       = "devops-main"
  subnet_ids = [aws_subnet.devops-db-subnet[0].id, aws_subnet.devops-db-subnet[1].id]

  tags = {
    Name = "DevOps DB subnet group"
  }
}