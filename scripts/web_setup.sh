#!/bin/bash
set -e

echo "Starting Web Tier setup on $(hostname)" > /tmp/web_setup.log

yum update -y
yum install -y httpd mod_proxy mod_proxy_http

systemctl enable httpd
systemctl start httpd

echo "<h1>Hello from Web Server $(hostname)</h1>" > /var/www/html/index.html

cat <<EOF > /etc/httpd/conf.d/proxy.conf
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

systemctl restart httpd
echo "Web setup completed successfully at $(date)" >> /tmp/web_setup.log
