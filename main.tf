terraform {
  backend "s3" {
    bucket = "day5-terrform-state-bucket1234"
    key    = "global/terraform.tfstate"    # the path inside that bucket
    region = "us-east-1"                   # your AWS region
  }
}

# ------------------ VPC ------------------
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "demo-vpc" }
}

# ------------------ Subnets ------------------
resource "aws_subnet" "web_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.web_subnet_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags                    = { Name = "web-subnet" }
}

resource "aws_subnet" "app_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.app_subnet_cidr
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "app-subnet" }
}

resource "aws_subnet" "db_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.db_subnet_cidr
  availability_zone       = "us-east-1c"
  map_public_ip_on_launch = true
  tags                    = { Name = "db-subnet" }
}

# ------------------ Internet Gateway & Routing ------------------
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags   = { Name = "demo-igw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "web_rta" {
  subnet_id      = aws_subnet.web_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "app_rta" {
  subnet_id      = aws_subnet.app_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "db_rta" {
  subnet_id      = aws_subnet.db_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ------------------ Security Groups ------------------
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  vpc_id      = aws_vpc.main_vpc.id
  description = "Allow HTTP and SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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
  tags = { Name = "web-sg" }
}

resource "aws_security_group" "app_sg" {
  name        = "app-sg"
  vpc_id      = aws_vpc.main_vpc.id
  description = "Allow traffic from Web tier and ALB"

  # Allow from Web Tier
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # ✅ Allow from ALB
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # SSH (optional)
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

  tags = { Name = "app-sg" }
}


resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  vpc_id      = aws_vpc.main_vpc.id
  description = "Allow MySQL from App tier"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "db-sg" }
}

# ------------------ EC2 Instances ------------------
# Web Tier (Simple HTTP Server)
resource "aws_instance" "web" {
  count                  = 2
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.web_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = var.key_name

  user_data = file("scripts/web_setup.sh")

  tags = { Name = "web-${count.index + 1}" }
}

# Application Tier (Flask API)
resource "aws_instance" "app" {
  count                  = 2
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.app_subnet.id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  key_name               = var.key_name
  #security_groups = [aws_security_group.app_sg.name]

  user_data = file("${path.module}/scripts/app_setup.sh")

  tags = { Name = "app-${count.index + 1}" }
}

# DB Tier (MySQL)
resource "aws_instance" "db" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.db_subnet.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  key_name               = var.key_name

  user_data = file("scripts/db_setup.sh")

  tags = { Name = "db-server" }
}

# ------------------ Application Load Balancer (ALB) ------------------

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  vpc_id      = aws_vpc.main_vpc.id
  description = "Allow HTTP access to the ALB"

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

  tags = { Name = "alb-sg" }
}

# ALB Resource
resource "aws_lb" "app_alb" {
  name               = "app-tier-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.web_subnet.id,
    aws_subnet.app_subnet.id
  ]

  tags = {
    Name = "app-tier-alb"
  }
}

# Target Group for App EC2s
resource "aws_lb_target_group" "app_tg" {
  name     = "app-tier-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "8080"
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 15
    matcher             = "200-399"
  }

  tags = {
    Name = "app-tier-tg"
  }
}

# Attach App Instances to Target Group
resource "aws_lb_target_group_attachment" "app_tg_attach" {
  count            = length(aws_instance.app)
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = aws_instance.app[count.index].id
  port             = 8080
}

# Listener for ALB
resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}
