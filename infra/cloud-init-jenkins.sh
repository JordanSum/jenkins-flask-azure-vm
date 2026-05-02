#!/bin/bash
# Cloud-init script to set up Jenkins, Docker, Nginx, and Certbot on the VM. This will be run on first boot. Immediately exit if any command returns a non-zerio exit code.
set -e
exec > /var/log/user-data.log 2>&1
export DEBIAN_FRONTEND=noninteractive

sudo apt update

# Install Java and Jenkins
sudo apt install -y fontconfig openjdk-21-jre
sudo mkdir -p /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install -y jenkins
sudo systemctl enable --now jenkins

# wait for jenkins to finish installing
sleep 60

# Install Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker jenkins
sudo chmod 666 /var/run/docker.sock

# Nginx and Certbot for SSL for the flask app
sudo apt install -y nginx certbot python3-certbot-nginx

# Configure Nginx as a reverse proxy for the Flask app
sudo tee /etc/nginx/sites-available/app > /dev/null <<'NGINX'
server {
    listen 80;
    server_name __FQDN__;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

# Replace __FQDN__ with the actual domain name in the Nginx config
sudo sed -i "s/__FQDN__/${fqdn}/" /etc/nginx/sites-available/app

# Enable the Nginx config and reload Nginx
sudo ln -sf /etc/nginx/sites-available/app /etc/nginx/sites-enabled/app
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx

# Wait for Route 53 record to be resolvable
for i in {1..30}; do
  getent hosts ${fqdn} >/dev/null && break
  sleep 10
done

# Issue cert + auto-configure HTTPS + HTTP->HTTPS redirect
sudo certbot --nginx -n --agree-tos -m ${email} -d ${fqdn} --redirect
