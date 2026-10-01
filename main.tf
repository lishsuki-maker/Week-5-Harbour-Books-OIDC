terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "harbour-books-reformation-bucket"
    key            = "Week-6/Harbour_Books_Reformation-terraform.tfstate"
    region         = "ap-southeast-2"
    dynamodb_table = "harbour-books-reformation-tf-lock"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "harbour_books_reformation" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Class = "week5-demo-vpc"
    Owner = "Students"
  }
}

resource "aws_internet_gateway" "harbour_books_reformation" {
  vpc_id = aws_vpc.harbour_books_reformation.id
}

resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.harbour_books_reformation.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "ap-southeast-2a"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.harbour_books_reformation.id
  cidr_block              = "10.20.2.0/24"
  availability_zone       = "ap-southeast-2b"
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.harbour_books_reformation.id
  cidr_block        = "10.20.11.0/24"
  availability_zone = "ap-southeast-2a"
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.harbour_books_reformation.id
  cidr_block        = "10.20.12.0/24"
  availability_zone = "ap-southeast-2b"
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.harbour_books_reformation.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.harbour_books_reformation.id
  }
}

resource "aws_route_table_association" "public_a" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_a.id
}

resource "aws_route_table_association" "public_b" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public_b.id
}

module "alb" {
  source = "./modules/alb"

  vpc_id = aws_vpc.harbour_books_reformation.id

  public_subnet_ids = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id
  ]
}

module "web_sg" {
  source              = "./modules/security_group"
  sg_name             = "${var.name_prefix}-web-sg"
  vpc_id              = aws_vpc.harbour_books_reformation.id
  ingress_port        = 80
  allowed_cidr_blocks = [var.my_ip]
}

resource "aws_vpc_security_group_ingress_rule" "web_from_alb" {
  security_group_id            = module.web_sg.sg_id
  referenced_security_group_id = module.alb.alb_security_group_id

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"
}

module "ec2_instance" {
  source = "./modules/ec2_instance"

  for_each = var.instances

  ami_id              = var.ami_id
  instance_type       = each.value.instance_type
  subnet_id           = aws_subnet.public_a.id
  sg_ids              = [module.web_sg.sg_id]
  instance_name       = "${var.name_prefix}-${var.environment}-${each.key}"
  associate_public_ip = true
}

resource "aws_lb_target_group_attachment" "web" {
  for_each = module.ec2_instance

  target_group_arn = module.alb.target_group_arn
  target_id        = each.value.instance_id
  port             = 8080
}

module "db_sg" {
  source       = "./modules/security_group"
  sg_name      = "${var.name_prefix}-db-sg"
  vpc_id       = aws_vpc.harbour_books_reformation.id
  ingress_port = 3306
  allowed_sg   = module.web_sg.sg_id
}

resource "aws_db_subnet_group" "harbour_books_reformation" {
  name       = "harbour-books-reformation-subnets"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_db_instance" "harbour_books_reformation" {
  identifier        = "${var.name_prefix}-${var.environment}-db"
  engine            = "mysql"
  instance_class    = "db.t4g.micro"
  allocated_storage = 20

  db_name  = "harbour_books_reformation_db"
  username = var.db_username
  password = var.db_user_password

  db_subnet_group_name   = aws_db_subnet_group.harbour_books_reformation.name
  vpc_security_group_ids = [module.db_sg.sg_id]

  publicly_accessible     = false
  backup_retention_period = 0
  multi_az                = false
  skip_final_snapshot     = true
}
