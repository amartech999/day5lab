#!/bin/bash
sudo yum update -y
sudo yum install -y python3 python3-pip

mkdir -p /home/ec2-user/app
cd /home/ec2-user/app

cat <<EOF > app.py
from flask import Flask
app = Flask(__name__)

@app.route('/')
def index():
    return "Hello from Application Tier!"

@app.route('/health')
def health():
    return "healthy", 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080)
EOF

pip3 install flask
nohup python3 app.py > app.log 2>&1 &