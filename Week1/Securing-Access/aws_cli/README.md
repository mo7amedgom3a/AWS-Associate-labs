# AWS CLI Implementation Instructions

This directory contains bash scripts to implement the IAM users, groups, and policies management solution using AWS Command Line Interface (CLI).

## Prerequisites

1. AWS CLI installed and configured with appropriate credentials
2. Sufficient IAM permissions to create users, groups, and policies
3. `jq` command-line JSON processor (required for the test script)

## Files

- `setup.sh`: Script to create all required IAM resources
- `test.sh`: Script to test the access permissions of the created IAM users
- `cleanup.sh`: Script to remove all created IAM resources

## Setup Instructions

1. Make the scripts executable:

```bash
chmod +x setup.sh test.sh cleanup.sh
```

2. Run the setup script:

```bash
./setup.sh
```

The script will:
- Create 3 IAM users: user-1, user-2, user-3
- Create 3 IAM groups: EC2-Admin, EC2-Support, S3-Support
- Create and attach an inline policy to EC2-Admin for EC2 full access
- Attach managed policies to EC2-Support and S3-Support
- Add users to their respective groups

## Testing the Setup

### Automated Testing with test.sh

Run the test script to automatically verify permissions:

```bash
./test.sh
```

The test script will:
1. Create temporary access keys for each IAM user
2. Configure temporary AWS CLI profiles
3. Test each user's permissions based on their group membership:
   - EC2 read permissions (describe instances)
   - EC2 write permissions (start/stop instances)
   - S3 read permissions (list buckets)
   - S3 write permissions (create buckets)
4. Display color-coded results for each test
5. Clean up temporary access keys and profiles

### Manual Testing

You can also verify the setup by:

1. Sign in to the AWS Management Console using the IAM users created
2. Test the permissions:
   - user-1 should be able to view, start, and stop EC2 instances
   - user-2 should be able to view but not modify EC2 resources
   - user-3 should be able to view but not modify S3 resources

## Clean Up

When you're done with the lab, run the cleanup script to remove all resources:

```bash
./cleanup.sh
```

The script will:
- Remove users from groups
- Delete the inline policy from the EC2-Admin group
- Detach managed policies from the EC2-Support and S3-Support groups
- Delete all IAM groups
- Delete all IAM users

## Troubleshooting

If you encounter any errors:

1. Ensure your AWS CLI is properly configured with the correct credentials
2. Verify that you have sufficient permissions to create IAM resources
3. Check the AWS CloudTrail logs for any permission-related issues
4. Run the cleanup script and try again
