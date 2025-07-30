# Ansible Playbooks for EC2 Instance Management

This directory contains Ansible playbooks to manage your EC2 instance, including nginx installation, Docker setup, and Django application deployment.

## Files

- `inventory.yml` - Defines the EC2 instance connection details
- `install_nginx.yml` - Basic nginx installation and configuration
- `install_docker.yml` - Install Docker and Docker Compose
- `deploy_django.yml` - Complete Django app deployment with Docker and nginx reverse proxy (downloads from GitHub)
- `deploy_django_only.yml` - Django deployment only (assumes Docker is installed)
- `configure_nginx_proxy.yml` - Configure nginx as reverse proxy for Django
- `ansible.cfg` - Ansible configuration file
- `README.md` - This file

## Prerequisites

1. Ansible installed on your local machine
2. SSH access to the EC2 instance (confirmed working with `ssh -i ~/aws_keys.pem ec2-user@52.55.35.4`)
3. The AWS key file at `~/aws_keys.pem`

## Usage

### Test Connection
First, test the connection to your EC2 instance:

```bash
ansible all -m ping -i inventory.yml
```

### Basic Nginx Installation
To install and configure nginx:

```bash
ansible-playbook install_nginx.yml -i inventory.yml
```

### Install Docker and Docker Compose
To install Docker and Docker Compose:

```bash
ansible-playbook install_docker.yml -i inventory.yml
```

### Deploy Django Application (Complete Setup from GitHub)
To deploy the Django application with Docker and configure nginx as reverse proxy (downloads from GitHub):

```bash
ansible-playbook deploy_django.yml -i inventory.yml
```

### Deploy Django Only (Docker already installed)
If Docker is already installed, deploy Django from GitHub:

```bash
ansible-playbook deploy_django_only.yml -i inventory.yml
```

### Configure Nginx as Reverse Proxy Only
If you already have Docker and Django running, configure nginx as reverse proxy:

```bash
ansible-playbook configure_nginx_proxy.yml -i inventory.yml
```

## What Each Playbook Does

### `install_nginx.yml`
1. **Updates yum cache** - Ensures package information is current
2. **Installs nginx** - Uses yum to install nginx package
3. **Starts and enables nginx** - Makes nginx start on boot and starts it now
4. **Creates a welcome page** - Adds a simple HTML page to verify the installation
5. **Verifies the installation** - Shows nginx service status

### `install_docker.yml`
1. **Updates system packages** - Ensures all packages are current
2. **Installs Docker** - Adds Docker repository and installs Docker CE
3. **Installs Docker Compose** - Downloads and installs Docker Compose
4. **Configures Docker** - Starts Docker service and adds user to docker group
5. **Verifies installation** - Tests Docker with hello-world container

### `deploy_django.yml` (Complete Setup)
1. **Installs Docker and Docker Compose** - Complete Docker setup
2. **Downloads project from GitHub** - Downloads and extracts the project from https://github.com/mo7amedgom3a/AWS-Associate-labs
3. **Creates application directory** - Sets up `/opt/django-app`
4. **Copies Django application** - Extracts Django files from the downloaded project
5. **Creates environment file** - Sets up `.env` with database configuration
6. **Builds and starts containers** - Runs `docker-compose up -d --build`
7. **Runs migrations** - Executes `python manage.py migrate --noinput`
8. **Creates superuser** - Sets up admin user (admin/admin123)
9. **Configures nginx reverse proxy** - Sets up nginx to proxy to Django
10. **Reloads nginx** - Applies new configuration

### `deploy_django_only.yml` (Django Only)
1. **Downloads project from GitHub** - Downloads and extracts the project
2. **Creates application directory** - Sets up `/opt/django-app`
3. **Copies Django application** - Extracts Django files from the downloaded project
4. **Creates environment file** - Sets up `.env` with database configuration
5. **Builds and starts containers** - Runs `docker-compose up -d --build`
6. **Runs migrations** - Executes `python manage.py migrate --noinput`
7. **Creates superuser** - Sets up admin user (admin/admin123)

### `configure_nginx_proxy.yml`
1. **Configures nginx** - Sets up reverse proxy configuration
2. **Removes default site** - Removes default nginx configuration
3. **Tests configuration** - Validates nginx configuration
4. **Reloads nginx** - Applies new configuration

## Django Application Details

The Django application includes:
- **Docker Compose setup** with Django web service and PostgreSQL database
- **REST API** with Django REST Framework
- **PostgreSQL database** with persistent volume
- **Environment configuration** via `.env` file
- **Nginx reverse proxy** for production deployment

## GitHub Repository

The playbooks download the Django application from:
https://github.com/mo7amedgom3a/AWS-Associate-labs/archive/refs/heads/main.zip

The Django app is located in the `Week2/ec2-layer/django-app` directory of the repository.

## Access Points

After deployment:
- **Django Admin**: http://52.55.35.4/admin/ (admin/admin123)
- **API Documentation**: http://52.55.35.4/api/
- **Health Check**: http://52.55.35.4/health/

## Verification

After running the deployment playbook, verify the installation:

1. **Check Docker containers:**
   ```bash
   ansible all -m command -a "sudo docker ps" -i inventory.yml
   ```

2. **Check nginx status:**
   ```bash
   ansible all -m command -a "sudo /etc/init.d/nginx status" -i inventory.yml
   ```

3. **Test web access:**
   ```bash
   curl http://52.55.35.4
   ```

4. **Check Django logs:**
   ```bash
   ansible all -m command -a "cd /opt/django-app && sudo docker-compose logs web" -i inventory.yml
   ```

## Troubleshooting

- **Docker issues**: Check if Docker service is running: `sudo systemctl status docker`
- **Nginx issues**: Check configuration: `sudo nginx -t`
- **Django issues**: Check container logs: `sudo docker-compose logs web`
- **Database issues**: Check PostgreSQL container: `sudo docker-compose logs db`
- **Download issues**: Check if wget and unzip are installed: `which wget && which unzip`

## Security Notes

- The `.env` file contains sensitive information - ensure proper file permissions
- Consider using AWS Secrets Manager for production secrets
- The nginx configuration includes basic security headers
- Docker containers run with appropriate user permissions 