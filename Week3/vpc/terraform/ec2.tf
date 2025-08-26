resource "aws_instance" "web" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  key_name                    = var.key_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y nginx
    systemctl start nginx
    systemctl enable nginx
    cat > /var/www/html/index.html << EOT
    <!DOCTYPE html>
    <html>
    <head>
         <title>Hello World</title>
    </head>
    <body>
         <h1>Welcome to Hello World</h1>
         <p>This server is running in the public subnet of our VPC.</p>
         <p>Server IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)</p>
    </body>
    </html>
    EOT
    chown nginx:nginx /var/www/html/index.html
    chmod 644 /var/www/html/index.html
    systemctl restart nginx
  EOF

  tags = {
    Name = "Lab Web Server"
  }
}