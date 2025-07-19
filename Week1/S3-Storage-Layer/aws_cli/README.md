# Deploying a Static Website on S3 Using AWS CLI

This directory contains scripts to automate the deployment of a static website on Amazon S3 using AWS Command Line Interface (CLI).

## Prerequisites

Before using these scripts, ensure you have:

1. **AWS CLI installed and configured**:
   ```bash
   # Install AWS CLI
   pip install awscli

   # Configure AWS credentials
   aws configure
   ```

2. **Required permissions**:
   Your AWS user must have permissions for the following actions:
   - s3:CreateBucket
   - s3:PutBucketPolicy
   - s3:PutBucketWebsite
   - s3:PutObject
   - s3:DeleteObject
   - s3:ListBucket
   - s3:DeleteBucket

3. **Static website files**:
   The `../static-website` directory should contain your website files (HTML, CSS, JavaScript, images).

## Available Scripts

### 1. Setup Script (`setup.sh`)

This script automates the process of deploying a static website to Amazon S3:

- Creates a new S3 bucket with a unique name
- Configures the bucket for public access
- Uploads all website files from the `../static-website` directory
- Enables static website hosting on the bucket
- Sets the appropriate bucket policy for public read access
- Provides the URL where the website is accessible

**Usage:**
```bash
chmod +x setup.sh
./setup.sh
```

### 2. Test Script (`test.sh`)

This script verifies that your website is accessible:

- Checks if the website responds with HTTP 200 status
- Provides the option to open the website in a browser (if running in a GUI environment)

**Usage:**
```bash
chmod +x test.sh
./test.sh
```

### 3. Cleanup Script (`cleanup.sh`)

This script removes all resources created by the setup script:

- Deletes all objects in the S3 bucket
- Deletes the S3 bucket itself

**Usage:**
```bash
chmod +x cleanup.sh
./cleanup.sh
```

## Step-by-Step Deployment Process

1. **Deploy the website**:
   ```bash
   ./setup.sh
   ```
   - The script will create a unique bucket name by appending a timestamp
   - All website files will be uploaded with public-read permissions
   - The script will save the bucket name and region for future reference

2. **Verify the deployment**:
   ```bash
   ./test.sh
   ```
   - The script will check if the website is accessible
   - You can open the website in a browser if desired

3. **Clean up resources when done**:
   ```bash
   ./cleanup.sh
   ```
   - This will remove all created resources to avoid ongoing charges

## Important Notes

- The setup script generates a unique bucket name by appending a timestamp to avoid name conflicts
- Bucket names and regions are saved in local hidden files (.bucket_name and .bucket_region)
- The cleanup script will use these files to identify resources to remove
- These scripts assume the static website files are in the `../static-website` directory

## Customization

To customize the deployment:

1. Edit `setup.sh` to change:
   - The base bucket name (default is "mycafe-website")
   - The AWS region (default is "us-east-1")
   - The path to website files (default is "../static-website")

2. If you need error handling:
   - Create an error.html file in your website directory
   - The script already configures it as the error document
