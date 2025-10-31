#!/bin/bash
sudo yum update -y
sudo yum install -y httpd curl

# Fetch EC2 metadata (instance info)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)
HOSTNAME=$(hostname)

# Create a simple HTML page showing instance info
cat <<EOF > /var/www/html/index.html
<html>
  <head><title>Web Tier</title></head>
  <body style="font-family: Arial; text-align: center; margin-top: 50px;">
    <h1>Hello from Web Tier</h1>
    <h2>Instance ID: ${INSTANCE_ID}</h2>
    <h3>Private IP: ${PRIVATE_IP}</h3>
    <h3>Hostname: ${HOSTNAME}</h3>
  </body>
</html>
EOF

# Start Apache
sudo systemctl enable httpd
sudo systemctl start httpd
