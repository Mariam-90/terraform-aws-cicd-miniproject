#!/bin/bash
set -e

apt-get update -y
apt-get upgrade -y
apt-get install -y python3.11 python3.11-venv python3-pip git

useradd -m -s /bin/bash appuser || true

mkdir -p /home/appuser/app
chown -R appuser:appuser /home/appuser/app

runuser -u appuser -- git clone https://github.com/Mariam-90/terraform-aws-cicd-miniproject.git /home/appuser/app

runuser -u appuser -- python3.11 -m venv /home/appuser/app/venv

runuser -u appuser -- /home/appuser/app/venv/bin/pip install -r /home/appuser/app/app/requirements.txt

runuser -u appuser -- /home/appuser/app/venv/bin/pip install gunicorn

cat > /etc/systemd/system/flask-app.service <<EOF
[Unit]
Description=Flask application running with Gunicorn
After=network.target

[Service]
User=appuser
Group=appuser
WorkingDirectory=/home/appuser/app/app
Environment="PATH=/home/appuser/app/venv/bin"
ExecStart=/home/appuser/app/venv/bin/gunicorn --workers 3 --bind 0.0.0.0:5000 main:app
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable flask-app
systemctl start flask-app
