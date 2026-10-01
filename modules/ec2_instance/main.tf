resource "aws_instance" "this" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.sg_ids
  associate_public_ip_address = var.associate_public_ip

  user_data = <<-EOF
    #!/bin/bash
    exec > /var/log/user-data.log 2>&1
    set -x

    apt-get update -y
    apt-get install -y python3

    mkdir -p /var/www/harbour-books

    cat > /var/www/harbour-books/index.html <<'HTML'
    <html>
      <body>
        <h1>Harbour Books</h1>
        <p>ALB is working!</p>
      </body>
    </html>
    HTML

    cd /var/www/harbour-books
    nohup python3 -m http.server 8080 --bind 0.0.0.0 > /var/log/harbour-books.log 2>&1 &
  EOF

  tags = {
    Name = var.instance_name
  }
}
