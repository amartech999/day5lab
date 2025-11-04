#!/bin/bash
sudo yum update -y
sudo yum install -y httpd mod_proxy mod_proxy_http -y

# Create HTML page for instance identification
echo "<h1>Hello from Web Server $(hostname)</h1>" > /var/www/html/index.html

# Proxy load balancing config
sudo tee /etc/httpd/conf.d/proxy.conf <<EOF
<VirtualHost *:80>
    ProxyPreserveHost On
    <Proxy balancer://appcluster>
        BalancerMember http://${app1_ip}:8080
        BalancerMember http://${app2_ip}:8080
        ProxySet lbmethod=byrequests
    </Proxy>
    ProxyPass / balancer://appcluster/
    ProxyPassReverse / balancer://appcluster/
</VirtualHost>
EOF

sudo systemctl enable httpd
sudo systemctl restart httpd
