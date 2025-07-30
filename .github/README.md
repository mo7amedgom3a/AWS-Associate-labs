# GitHub Actions for Django Deployment

This directory contains GitHub Actions workflows to automate the deployment of your Django application to the EC2 instance using Ansible.

## Available Workflows

### 1. `deploy.yml` - Basic Deployment
- Simple deployment using existing Ansible playbooks
- Runs tests and deploys to EC2
- Uses PRIVATE_KEY secret for SSH authentication

### 2. `deploy-advanced.yml` - Advanced Deployment (Recommended)
- Full CI/CD pipeline with comprehensive testing
- Includes backup and rollback capabilities
- Better error handling and health checks
- Uses PRIVATE_KEY secret for SSH authentication

## Setup Instructions

### 1. Add GitHub Secret

Go to your GitHub repository → Settings → Secrets and variables → Actions, and add:

**Required Secret:**
- `PRIVATE_KEY`: Your AWS private key content (the content of `~/aws_keys.pem`)

### 2. How to Add the PRIVATE_KEY Secret

1. **Get your private key content:**
   ```bash
   cat ~/aws_keys.pem
   ```

2. **Copy the entire output** (including the BEGIN and END lines):
   ```
   -----BEGIN RSA PRIVATE KEY-----
   MIIEpAIBAAKCAQEA...
   ... (your private key content) ...
   -----END RSA PRIVATE KEY-----
   ```

3. **In GitHub repository settings:**
   - Go to Settings → Secrets and variables → Actions
   - Click "New repository secret"
   - Name: `PRIVATE_KEY`
   - Value: Paste the entire private key content
   - Click "Add secret"

### 3. How the SSH Key is Used

The workflow automatically:
1. Creates `~/.ssh/aws_keys.pem` from the `PRIVATE_KEY` secret
2. Sets proper permissions (600) for the key file
3. Adds the EC2 host to known_hosts
4. Uses this key for all SSH connections to the EC2 instance

### 4. Enable GitHub Actions

1. Push the workflow files to your repository
2. Go to the "Actions" tab in your GitHub repository
3. You should see the workflows listed
4. The workflows will automatically run on:
   - Push to main branch
   - Pull requests to main branch
   - Manual trigger (workflow_dispatch)

## Workflow Details

### Test Job
- Runs on every push and pull request
- Installs Python dependencies
- Runs linting with flake8
- Tests Django application
- Runs security checks
- Must pass before deployment

### Deploy Job
- Only runs on pushes to main branch
- Installs Ansible
- Sets up SSH key from PRIVATE_KEY secret
- Tests SSH connection to EC2
- Creates backup of current deployment
- Runs Ansible deployment playbook
- Verifies deployment with health checks
- Includes rollback capability on failure

## Security Features

- **SSH Key Security**: Private key is stored as GitHub secret
- **Automatic Rollback**: Failed deployments automatically rollback to previous version
- **Health Checks**: Comprehensive verification of deployment
- **Backup Creation**: Automatic backup before deployment
- **Branch Protection**: Only main branch triggers deployments

## Manual Deployment

You can manually trigger a deployment:

1. Go to your GitHub repository
2. Click on "Actions" tab
3. Select the workflow you want to run
4. Click "Run workflow"
5. Select the branch and click "Run workflow"

## Troubleshooting

### Common Issues

1. **SSH Connection Failed**
   - Verify the `PRIVATE_KEY` secret is correctly set
   - Check that the EC2 instance is running
   - Ensure the security group allows SSH access
   - Verify the private key format (should include BEGIN and END lines)

2. **Ansible Deployment Failed**
   - Check the Ansible logs in the GitHub Actions output
   - Verify the EC2 instance has the required packages
   - Check if Docker is properly installed

3. **Django Application Not Responding**
   - Check if containers are running: `sudo docker ps`
   - Check nginx status: `sudo /etc/init.d/nginx status`
   - Check Django logs: `sudo docker-compose logs web`

### Debugging Steps

1. **Check GitHub Actions Logs**
   - Go to the Actions tab
   - Click on the failed workflow run
   - Review the logs for each step

2. **SSH into EC2 and Check**
   ```bash
   ssh -i ~/aws_keys.pem ec2-user@52.55.35.4
   cd /opt/django-app
   sudo docker-compose ps
   sudo docker-compose logs web
   ```

3. **Test Application Manually**
   ```bash
   curl -I http://52.55.35.4/admin/
   ```

## Environment Variables

You can modify these environment variables in the workflow files:
- `EC2_HOST`: Your EC2 instance IP (52.55.35.4)
- `EC2_USER`: SSH user (ec2-user)
- `ANSIBLE_DIR`: Path to Ansible playbooks (Week2/ec2-layer/ansible)
- `DJANGO_APP_DIR`: Path to Django app (Week2/ec2-layer/django-app)

## Rollback Process

If deployment fails, the advanced workflow automatically:
1. Stops the current containers
2. Restores from the backup created before deployment
3. Restarts the containers with the previous version
4. Logs the rollback process

## Monitoring

After deployment, you can monitor:
- **Application Health**: http://52.55.35.4/admin/
- **Container Status**: Check Docker containers
- **Nginx Status**: Check web server status
- **Django Logs**: Check application logs

## Best Practices

1. **Always test on a branch** before pushing to main
2. **Monitor the deployment logs** in GitHub Actions
3. **Keep your private key secure** and rotate it regularly
4. **Review the rollback logs** if deployment fails
5. **Set up monitoring** for your application 