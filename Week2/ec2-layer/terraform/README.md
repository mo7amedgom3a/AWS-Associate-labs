# AWS Infrastructure Terraform Setup

This directory contains Terraform configuration to provision AWS infrastructure for the Django web application.

## Infrastructure Provisioned

- VPC with Internet Gateway
- Public subnet with public IP mapping
- Route table with Internet Gateway route
- Security group for web and SSH access
- EC2 instance with the specified AMI
- ECR repository for Docker images
- SSH key pair for EC2 access

## Prerequisites

- Terraform installed
- AWS CLI configured with appropriate credentials

## Usage

1. Initialize Terraform:

```bash
terraform init
```

2. Review the planned changes:

```bash
terraform plan
```

3. Apply the configuration:

```bash
terraform apply
```

4. To test the infrastructure:

```bash
chmod +x test.sh
./test.sh
```

5. To destroy the infrastructure:

```bash
terraform destroy
```

## Key Features

- **Automated Key Generation**: Terraform automatically generates an SSH key pair and saves the private key locally
- **Infrastructure Details**: Creates an `infrastructure-details.txt` file with all relevant information
- **Security**: Restricts SSH access to your current IP address
- **Reusable Components**: Configurable through variables

## Customization

Edit `variables.tf` to customize:

- AWS region
- Instance type and AMI
- VPC and subnet CIDR blocks
- SSH key paths
- Project tags

## Outputs

After applying, you'll get:
- EC2 instance ID and public IP
- ECR repository URL
- SSH command to connect to the instance
- VPC ID

These outputs are saved both to the console and to the `infrastructure-details.txt` file.
