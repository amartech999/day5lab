#!/bin/bash
sudo yum update -y
sudo yum install -y httpd
echo "<h1>Hello from Web Tier</h1>" > /var/www/html/index.html
sudo systemctl enable httpd
sudo systemctl start httpd