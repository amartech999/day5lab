#!/bin/bash
set -e

# Detect OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  OS=$(uname -s)
fi
echo "Detected OS: $OS" > /tmp/os_detected.log

# Install Apache
if [[ "$OS" == "amzn" || "$OS" == "rhel" || "$OS" == "centos" ]]; then
  yum update -y
  yum install -y httpd mod_proxy mod_proxy_http
  WEB_SERVICE="httpd"
elif [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
  apt update -y
  apt install -y apache2 libapache2-mod-proxy-html libxml2-dev
  a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests
  WEB_SERVICE="apache2"
else
  echo "Unsupported OS: $OS" > /tmp/os_error.log
  exit 1
fi

# Web identity page
echo "<h1>Hello from Web Server $(hostname)</h1>" > /var/www/html/index.html

# Proxy load balancing config
cat <<EOF | tee /etc/${WEB_SERVICE}/conf.d/proxy.conf >/dev/null
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

systemctl enable ${WEB_SERVICE}
systemctl restart ${WEB_SERVICE}
systemctl status ${WEB_SERVICE} --no-pager
