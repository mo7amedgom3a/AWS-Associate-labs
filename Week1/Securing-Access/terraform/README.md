# IAM Management with Terraform

This directory contains Terraform code to implement the IAM users, groups, and policies management solution as described in the lab requirements.

## Prerequisites

1. [Terraform](https://www.terraform.io/downloads.html) installed (version 1.0.0 or later)
2. AWS credentials configured (either through environment variables, AWS CLI configuration, or other Terraform-supported methods)

## Files

- `main.tf`: Main Terraform configuration file with resource definitions
- `variables.tf`: Variable definitions for the Terraform configuration
- `outputs.tf`: Output definitions to display useful information after deployment
- `terraform.tfvars.example`: Example variable values (rename to terraform.tfvars to use)
- `test.sh`: Script to test the access permissions of the created IAM users

## Setup Instructions

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

When prompted, type `yes` to confirm the deployment.

The Terraform configuration will:
- Create 3 IAM users: user-1, user-2, user-3
- Create 3 IAM groups: EC2-Admin, EC2-Support, S3-Support
- Create and attach an inline policy to EC2-Admin for EC2 full access
- Attach AWS managed policies to EC2-Support and S3-Support
- Add users to their respective groups

## Testing the Setup

### Prerequisites for Testing

1. AWS CLI installed and configured 
2. `jq` command-line JSON processor installed

### Automated Testing with test.sh

Make the test script executable:

```bash
chmod +x test.sh
```

Run the test script to automatically verify permissions:

```bash
./test.sh
```

The test script will:
1. Verify that Terraform has been successfully applied
2. Create temporary access keys for each IAM user
3. Configure temporary AWS CLI profiles
4. Test each user's permissions based on their group membership:
   - EC2 read permissions (describe instances)
   - EC2 write permissions (start/stop instances)
   - S3 read permissions (list buckets)
   - S3 write permissions (create buckets)
5. Display color-coded results for each test
6. Clean up temporary access keys and profiles

### Manual Testing

You can also verify the setup by:

1. Sign in to the AWS Management Console using the IAM users created
2. Test the permissions:
   - user-1 should be able to view, start, and stop EC2 instances
   - user-2 should be able to view but not modify EC2 resources
   - user-3 should be able to view but not modify S3 resources

## Clean Up

When you're done with the lab, remove all created resources:

```bash
terraform destroy
```

When prompted, type `yes` to confirm the deletion.

## Troubleshooting

If you encounter any errors:

1. Ensure your AWS credentials have sufficient permissions
2. Check the Terraform state file for any inconsistencies
3. Run `terraform plan` again to identify any potential issues
4. If necessary, import existing resources into the Terraform state
