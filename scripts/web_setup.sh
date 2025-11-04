#!/bin/bash
set -e

# Log the start
echo "Starting Web Tier setup on $(hostname)" > /tmp/web_setup.log

# Install Apache and required modules
yum update -y
yum install -y httpd mod_proxy mod_proxy_http

# Enable & start Apache
systemctl enable httpd
systemctl start httpd

# Simple homepage (to test load balancing)
echo "<h1>Hello from Web Server $(hostname)</h1>" > /var/www/html/index.html

# Create reverse proxy configuration
cat <<'EOF' > /etc/httpd/conf.d/proxy.conf
<VirtualHost *:80>
    ProxyPreserveHost On
    <Proxy balancer://appcluster>
        BalancerMember http://${APP1_IP}:8080
        BalancerMember http://${APP2_IP}:8080
        ProxySet lbmethod=byrequests
    </Proxy>
    ProxyPass / balancer://appcluster/
    ProxyPassReverse / balancer://appcluster/
</VirtualHost>
EOF

# Replace placeholders with real app IPs
sed -i "s|\${APP1_IP}|${app1_ip}|g" /etc/httpd/conf.d/proxy.conf
sed -i "s|\${APP2_IP}|${app2_ip}|g" /etc/httpd/conf.d/proxy.conf

# Restart Apache after config update
systemctl restart httpd

# Log completion
echo "Web setup completed successfully at $(date)" >> /tmp/web_setup.log
