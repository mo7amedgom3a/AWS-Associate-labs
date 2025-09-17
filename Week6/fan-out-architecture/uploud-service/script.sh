#!/bin/bash

# Replace with your EC2 instance's public IP address
EC2_IP="18.234.59.46"
# Replace with the path to your AWS key pair
SSH_KEY_PATH="~/aws_keys.pem"

# 1. Install Node.js, npm, and yarn on the EC2 instance
ssh -i "$SSH_KEY_PATH" ec2-user@"$EC2_IP" << EOF
  sudo yum update -y
  sudo amazon-linux-extras install python3.8 -y
  sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1
  sudo update-alternatives --set python3 /usr/bin/python3.8
  sudo amazon-linux-extras install -y nodejs
  sudo npm install -g yarn
  sudo mkdir -p /var/www/html/uploud-service
  sudo chown -R ec2-user:ec2-user /var/www/html/uploud-service
EOF

# 2. Copy the current directory (React app) to the EC2 instance
scp -i "$SSH_KEY_PATH" -r ./* ec2-user@"$EC2_IP":/var/www/html/uploud-service/

echo "React app deployment script finished. You may need to manually build and configure Nginx on the EC2 instance."
