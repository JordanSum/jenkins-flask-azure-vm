# Python Flask App Using Jenkins CI/CD Pipeline

Welcome to my repository to deploy a Python Flask application using Jenkins pipelines to a Virtual Machine (VM) in Azure.  Here you will find everything needed in order to deploy this web application to Azure cloud using IaC.  This project deploys a Flask web application + MySQL database for tracking a "To Do" list, (I know, very basic).  Some key services this project uses in Azure are VNET, Azure VM, MySQL, and Jenkins. Please remember to study, apply, and learn but most importantly, have fun!

Thanks!

> [!NOTE]
> Always follow best practices and policies when deploying this project.

## Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Local Development](#local-development)
- [Cloud Deployment](#cloud-deployment)
  - [Create Azure Infrastructure](#create-azure-infrastructure)
  - [Unlock Jenkins Pipeline](#unlock-jenkins-pipeline)
- [Troubleshooting](#troubleshooting)
- [License](#license)

## Overview

This project is a Python Flask web application deployed through a Jenkins CI/CD pipeline that creates, reads, updates, and deletes "To Do" tasks stored in a MySQL database running on an Azure VM.  The VM hosts Jenkins, Docker, MySQL, and the application.

## Architecture

**Components:**
| Component | Description |
|-----------|-------------|
| VNET | Virtual network isolating Azure resources |
| Virtual Machine | VM running Jenkins, MySQL, and the TO-DO application |
| MySQL | Managed database for "To Do" entries |
| Jenkins | Virtual machine server running Jenkins CI/CD pipeline |
| Docker | Hosting the containerized application on the VM |
| AWS Route53 | DNS routing, maps a custom domain name to the Azure VM's public IP address |

## Prerequisites

### Local Development
- Git
- Docker Desktop
- Python 3.12
- Azure Account

### Cloud Deployment
- Terraform
- GitHub CLI (`gh` and/or `git`)
- Docker and/or Docker Desktop

## Local Development

**Quick Start**
```bash
# Clone the repository
git clone https://github.com/JordanSum/jenkins-flask-azure-vm.git
cd jenkins-flask-app-vm

# Open in VS Code
code .
```

**Create venv**
```bash
python3 -m venv <venv-name>

# macOS/Linux
source venv/bin/activate

# Windows
venv/Scripts/activate

# Install packages
pip install <package-name>

# Save dependencies
pip freeze > requirements.txt

# Recreate from requirements
pip install -r requirements.txt
```

Open Docker Desktop if installed

In your terminal run the following command to test your dev application locally:

```bash
# Use docker compose
docker compose -f docker-compose.dev.yml up --build
```

Once the containers are running, navigate to `http://localhost:8000` in your browser to view the application.

## Cloud Deployment

### Create Azure Infrastructure

```bash
cd infra

terraform validate

terraform plan

terraform apply --auto-approve

# Wait for your azure infrastructure to finish deploying and then move on to the next steps
```
> [!NOTE]
> When the environment has deployed successfully wait a few minutes before logging into Jenkins.  The custom_data from the cloud-init-jenkins.sh file is still processing in the background in your deployed VM.  Jenkins, Docker, and Nginx are finishing installing.

### Unlock Jenkins Pipeline

When your Azure infrastructure has finished deploying, go into your Azure account and open your Resource Group that was just created. Inside that resource group you will locate your Jenkins Virtual Machine (VM).  Click on your Jenkins VM and locate the public IP (PIP) address, open a separate internet tab and paste the PIP in the address bar with port 8080. (http://ip-address:8080).  You should be introduced to an 'Unlock Jenkins' page.  On this page you will see a file path that is holding the Jenkins server password. Use this file path in the next step to locate the password to paste into this page.

<img src="docs/images/Screenshot 2026-04-24 at 13.24.42.png" alt="Jenkins Unlock Jenkins splash page displaying the initial admin password file path" width="900">
<br><br>

Back in your Azure account, on your Jenkins VM page, locate the "Connect" hyperlink and click on it. Or, access the VM instance via your IDE terminal.

<img src="docs/images/Screenshot 2026-04-24 at 13.26.34.png" alt="Azure portal Jenkins VM overview page with the Connect hyperlink highlighted" width="900">
<br><br>

On the connect page you will see a "Native SSH" page.  At the bottom of the page it will show the ssh command to connect to this VM.  Copy the ssh link and paste this into your terminal of choice.

<img src="docs/images/Screenshot 2026-04-24 at 13.26.44.png" alt="Azure portal Native SSH connection page showing the SSH command to connect to the Jenkins VM" width="900">
<br><br>

Once pasted, replace "private-key-file-path" with your private key used when creating the VM.

<img src="docs/images/Screenshot 2026-04-24 at 13.27.13.png" alt="Terminal SSH command with private-key-file-path placeholder to be replaced with your actual private key path" width="900">
<br><br>

You should now be logged into your Jenkins VM.  Run the `cat` command to reveal your password with the file path that was given from the "Unlock Jenkins" splash page.

<img src="docs/images/Screenshot 2026-04-24 at 13.28.03.png" alt="Terminal running the cat command to reveal the Jenkins initial admin password" width="900">
<br><br>

Once logged into your Jenkins VM click the "Install suggested plugins". This will install the necessary plugins needed to run and configure this Jenkins server.

<img src="docs/images/Screenshot 2026-04-24 at 13.28.20.png" alt="Jenkins setup page prompting to Install Suggested Plugins" width="900">
<br><br>

<img src="docs/images/Screenshot 2026-04-24 at 13.28.47.png" alt="Jenkins plugin installation progress screen showing suggested plugins being installed" width="900">
<br><br>

On the next page fill out the fields to create your first user.  This is going to be used to log into the Jenkins server.

<img src="docs/images/Screenshot 2026-04-24 at 13.29.19.png" alt="Jenkins Create First Admin User form with fields for username, password, and email" width="900">
<br><br>

On the "Instance Configuration" page keep the current settings and click "Save and Finish"

<img src="docs/images/Screenshot 2026-04-24 at 13.29.42.png" alt="Jenkins Instance Configuration page showing the Jenkins URL with the Save and Finish button" width="900">
<br><br>

On your "Welcome to Jenkins" page, click on "New Item" in the top left corner.

<img src="docs/images/Screenshot 2026-04-24 at 13.30.17.png" alt="Jenkins Welcome page with New Item option in the left-hand navigation menu" width="900">
<br><br>

In your "New Item" page, enter your item name, select "Pipeline," and click on "Ok".

<img src="docs/images/Screenshot 2026-04-24 at 13.31.00.png" alt="Jenkins New Item page with a name entered and the Pipeline type selected" width="900">
<br><br>

On your "General" page, give a brief description, and under "Build Triggers" select "GitHub hook trigger for GITScm polling". In "Pipeline" select "Pipeline Script from SCM" under "Definition". Git needs to be selected under SCM, use the GitHub repo URL in the "Repository URL" input box, the "Branch Specifier" should read "*/main", and set the "Script Path" to "Jenkinsfile".

<img src="docs/images/Screenshot 2026-04-24 at 13.39.22.png" alt="Jenkins pipeline General configuration page with GitHub hook trigger for GITScm polling selected under Build Triggers" width="900">
<br><br>

<img src="docs/images/Screenshot 2026-04-24 at 13.39.31.png" alt="Jenkins pipeline Pipeline section with Definition set to Pipeline Script from SCM and SCM set to Git" width="900">
<br><br>

<img src="docs/images/Screenshot 2026-04-24 at 13.39.34.png" alt="Jenkins pipeline SCM settings showing the GitHub repository URL, branch specifier set to main, and Script Path set to Jenkinsfile" width="900">
<br><br>

Set up a webhook in your GitHub repository so when a push trigger is activated in GitHub it runs the build in Jenkins of the updated code. GitHub Repository/Settings/Webhook. Your PayloadURL is going to be the same as your vm pip with the jenkins port. Set the events to trigger on "just push".
<img src="docs/images/Screenshot 2026-04-24 at 13.42.26.png" alt="GitHub repository Webhooks settings page for configuring a webhook to trigger Jenkins builds on push" width="900">
<br><br>

Back in your Jenkins server application, make your way to the settings page, and click on "Credentials" --> "System" --> "Global" --> "+ Add Credentials". Make sure to click on "Secret Text". Here you will be putting in your variables to allow your Jenkins Server to push your GitHub code to your Azure VM.

<img src="docs/images/Screenshot 2026-04-24 at 13.43.13.png" alt="Jenkins Add Credentials page with Secret Text kind selected for storing Azure and ACR credentials" width="900">
<br><br>

| Name | Secret |
|------|--------|
| MYSQL_USER | Username to access MySQL on the VM|
| MYSQL_PASSWORD | Password associated with the user created |
| MYSQL_DB | MySQL database name |
| MYSQL_ROOT_PASSWORD | Root password for root access |
| SECRET_KEY | Flask secret key used to sign sessions and cookies (any random string) |

<img src="docs/images/Screenshot 2026-05-01 at 19.51.06.png" alt="Jenkins Global Credentials page listing all added secret text credentials including Azure and ACR variables" width="900">
<br><br>

Now go to your Jenkins home page and click on the pipeline you just created and click "Build Now". You should see your build spinning up below the left hand menu bar.

<img src="docs/images/Screenshot 2026-04-24 at 13.52.55.png" alt="Jenkins pipeline page with Build Now option and the build running in the build history" width="900">
<br><br>

Once your build has completed successfully, navigate back to your VM that is hosting the application. Give it a few minutes, and click on the public IP address in the Overview page of the VM. Also, since Terraform associated your VM's public IP with your domain in Route53, you should be able to access the application that way.  Add several tasks to your application.  You will be looking up these entries in MySQL.

<img src="docs/images/Screenshot 2026-04-24 at 13.59.26.png" alt="Deployed Flask To Do web application running live in the browser via Azure VM" width="900">
<br><br>

Back in your IDE, (I use VS Code) log into your database and check that your actual entries are being created in the database.

Check the database
```bash
mysql -u <username> -p <password>
SHOW DATABASES;
USE <database-name>;
SHOW TABLES;
SELECT * FROM <table-name>;
```

Once completed, navigate to the infra folder in your IDE or CLI in this project and run the following to destroy your cloud infrastructure.  You don't want to build up any charges.

```bash
terraform destroy --auto-approve
```

## Troubleshooting

Below are common issues you may run into while deploying or running this project, along with steps to resolve them.

### Terraform

**`terraform apply` fails with an authentication error**
- Make sure you are logged into Azure: `az login`.
- Confirm the correct subscription is selected: `az account show` and, if needed, `az account set --subscription <subscription-id>`.
- Verify the values in `infra/terraform.tfvars` match your environment (subscription ID, resource names, region, SSH public key path).

**Resource name or quota conflicts**
- Azure resource names (especially for public DNS labels) must be globally unique. Update the name in `infra/terraform.tfvars` and re-run `terraform apply`.
- If you hit a vCPU quota error, choose a different VM size in `infra/variables.tf` or request a quota increase in the target region.

**State is out of sync / partial deploy**
- Run `terraform plan` to see drift.
- If a resource was deleted manually in the portal, remove it from state with `terraform state rm <address>` and re-apply.

### VM / Cloud-init

**Jenkins page does not load on `http://<public-ip>:8080`**
- Wait 3–5 minutes after `terraform apply` completes — `cloud-init-jenkins.sh` is still installing Jenkins, Docker, and Nginx in the background.
- SSH into the VM and check progress: `sudo cloud-init status --wait` and `sudo tail -f /var/log/cloud-init-output.log`.
- Confirm the NSG rule allows inbound traffic on port 8080 (and 80/443 if using Nginx).

**SSH connection refused or times out**
- Ensure you are using the private key that matches the public key referenced in `terraform.tfvars`.
- Verify your client public IP is allowed by the NSG SSH rule.
- On Windows, fix key permissions if SSH complains: `icacls <key> /inheritance:r /grant:r "$($env:USERNAME):R"`.
- On Linux/macOS, fix key permissions if SSH complains about them being too open: `chmod 600 <key>` (and `chmod 700 ~/.ssh` if needed).
- Test connectivity to port 22: `nc -vz <vm-public-ip> 22` (Linux/macOS) or `Test-NetConnection <vm-public-ip> -Port 22` (Windows). A timeout usually indicates an NSG/firewall block; "connection refused" means the host is reachable but sshd is not listening.
- Confirm the VM is running and has finished provisioning (cloud-init can take a few minutes after `terraform apply`).
- If you recently redeployed the VM, remove the stale host key: `ssh-keygen -R <vm-public-ip>` (Linux/macOS/Windows OpenSSH).
- Add `-v` (or `-vvv`) to the ssh command for verbose output to pinpoint the failure: `ssh -vvv -i <key> azureuser@<vm-public-ip>`.

### Jenkins

**"Unlock Jenkins" page asks for the initial admin password**
- SSH into the VM and run: `sudo cat /var/lib/jenkins/secrets/initialAdminPassword`.

**Pipeline build does not trigger on `git push`**
- In GitHub, go to **Settings → Webhooks** and confirm the most recent delivery returned `200 OK`.
- Confirm the webhook URL is `http://<jenkins-public-ip>:8080/github-webhook/` (trailing slash matters).
- In the Jenkins job, ensure **GitHub hook trigger for GITScm polling** is checked.

**Build fails with "missing credential" or undefined environment variable**
- Re-check that every credential in the table above (`MYSQL_USER`, `MYSQL_PASSWORD`, `MYSQL_DB`, `MYSQL_ROOT_PASSWORD`, `SECRET_KEY`) exists under **Manage Jenkins → Credentials → System → Global** as **Secret text** with the exact ID used in the `Jenkinsfile`.

**Docker permission denied inside the Jenkins build**
- The `jenkins` user must be in the `docker` group: `sudo usermod -aG docker jenkins && sudo systemctl restart jenkins`.

### Application / MySQL

**App returns 502 / cannot reach the site**
- In your VM terminal
- Check the container is running on the VM: `docker ps`.
- Inspect logs: `docker logs <container-name>`.
- Confirm Nginx is up: `sudo systemctl status nginx` and review `/var/log/nginx/error.log`.

**App loads but database operations fail**
- Verify the MySQL container is healthy: `docker ps` and `docker logs <mysql-container>`.
- Confirm the app's `MYSQL_*` environment variables exactly match the credentials used to initialize the MySQL container.
- Connect manually to validate access:
  ```bash
  mysql -u <username> -p
  SHOW DATABASES;
  USE <database-name>;
  SHOW TABLES;
  ```

**Route53 domain does not resolve to the VM**
- DNS propagation can take a few minutes — test with `nslookup <your-domain>` or `dig <your-domain>`.
- Confirm the A record in Route53 points to the VM's current public IP (it changes if the VM is recreated).

### Cleanup

**`terraform destroy` leaves resources behind**
- Some resources (managed disks, network interfaces) can be locked by the Azure portal. Refresh state with `terraform refresh`, then re-run `terraform destroy --auto-approve`.
- As a last resort, delete the resource group from the portal or with `az group delete --name <resource-group> --yes --no-wait`.

## License

MIT License

Copyright (c) 2026 Jordan Sumner

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
