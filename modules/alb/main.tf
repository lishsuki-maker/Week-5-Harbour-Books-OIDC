resource "aws_security_group" "alb" {
  name        = "harbour-books-reformation-alb-sg"
  description = "Security group for the ALB"
  vpc_id      = var.vpc_id

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

resource "aws_alb" "this" {
  name               = "harbour-books-reformation-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = var.public_subnet_ids

  security_groups = [aws_security_group.alb.id]
}

resource "aws_alb_target_group" "this" {
  name     = "harbour-books-reformation-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = var.vpc_id
}

resource "aws_alb_listener" "this" {
  load_balancer_arn = aws_alb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.this.arn
  }
}
