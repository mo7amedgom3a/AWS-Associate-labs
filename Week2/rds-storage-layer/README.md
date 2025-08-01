# RDS Storage Layer Setup

This directory contains scripts for setting up Amazon RDS MySQL database infrastructure for the Django web application, following the architecture shown in the VPC diagram.

## Architecture Overview

Based on the VPC diagram, this setup creates:
- **Private Subnet** (10.0.2.0/24) in us-east-1b for the RDS instance
- **RDS MySQL Instance** in the private subnet with free tier configuration
- **Security Group** allowing MySQL access (port 3306) from the public subnet
- **DB Subnet Group** spanning both public and private subnets

## Script Overview

### Core Scripts

1. **`rds-setup.sh`** - Main RDS infrastructure setup script
   - Creates private subnet in us-east-1b
   - Creates RDS MySQL instance with free tier configuration
   - Sets up security groups and subnet groups
   - Generates `rds-details.txt` with database connection details

2. **`rds-cleanup.sh`** - RDS infrastructure cleanup script
   - Removes RDS instance, subnet group, and security groups
   - Cleans up private subnet and route table
   - Handles dependencies and safety checks

3. **`db-init.sh`** - Database initialization script (SSH-based)
   - Copies SQL files to EC2 instance via SCP
   - Connects to EC2 instance via SSH
   - Executes database initialization commands remotely
   - Supports both `init.sql` and `mydb_dump.sql` files
   - Cleans up temporary files after execution

### Utility Scripts

4. **`test-rds.sh`** - RDS setup verification script
   - Tests script permissions and AWS CLI connectivity
   - Verifies RDS instance status and connectivity
   - Tests EC2 connectivity and SSH key configuration
   - Validates configuration files

5. **`init.sql`** - Database initialization SQL
   - Creates database and tables
   - Inserts sample data

6. **`mydb_dump.sql`** - MySQL dump file (optional)
   - Complete database dump with structure and data
   - Used as primary initialization method if available

## Prerequisites

1. **Network Infrastructure**: Run the EC2 layer setup first:
   ```bash
   cd ../ec2-layer/aws_cli
   ./network-setup.sh
   ```

2. **EC2 Instance**: Create the EC2 instance:
   ```bash
   cd ../ec2-layer/aws_cli
   ./setup.sh
   ```

3. **AWS CLI**: Configured with appropriate permissions for RDS

4. **SSH Key**: The key pair created during EC2 setup must be available

## Usage

### Quick Start (All-in-One)
```bash
./rds-setup.sh    # Create RDS infrastructure
./db-init.sh      # Initialize database via EC2
```

### Step-by-Step Setup

1. **Create RDS Infrastructure:**
   ```bash
   ./rds-setup.sh
   ```

2. **Initialize Database:**
   ```bash
   ./db-init.sh
   ```

3. **Test the Setup:**
   ```bash
   ./test-rds.sh
   ```

### Cleanup

```bash
./rds-cleanup.sh
```

## Configuration Details

### RDS Instance Configuration
- **Instance Class**: `db.t3.micro` (Free tier eligible)
- **Engine**: MySQL 8.0.35
- **Storage**: 20 GB GP2 with auto-scaling up to 100 GB
- **Backup**: 7-day retention
- **Encryption**: Storage encrypted
- **Deletion Protection**: Enabled

### Network Configuration
- **Private Subnet**: 10.0.2.0/24 in us-east-1b
- **Security Group**: Allows MySQL (3306) from public subnet only
- **Publicly Accessible**: No (for security)

### Database Configuration
- **Database Name**: `mydb`
- **Username**: `admin`
- **Password**: `MySecurePassword123!`
- **Port**: 3306 (default MySQL port)

## Security Features

1. **Private Subnet**: RDS instance is in private subnet, not directly accessible from internet
2. **Security Group**: Only allows MySQL access from the public subnet (EC2 instance)
3. **Encryption**: Storage is encrypted at rest
4. **Deletion Protection**: Prevents accidental deletion
5. **SSH-based Access**: Database initialization done via EC2 instance for security

## Database Initialization Process

The `db-init.sh` script follows this secure process:

1. **Load Configuration**: Reads RDS and EC2 details from configuration files
2. **Test Connectivity**: Verifies EC2 instance accessibility
3. **Install MySQL Client**: Installs MySQL client on EC2 instance if needed
4. **Copy SQL Files**: Transfers `init.sql` and/or `mydb_dump.sql` to EC2
5. **Execute Remotely**: Runs database initialization commands via SSH
6. **Verify Results**: Checks database tables and sample data
7. **Clean Up**: Removes temporary SQL files from EC2

## Connection Details

After setup, the database connection details will be saved in `rds-details.txt`:

```
DB_ENDPOINT=<rds-endpoint>
DB_PORT=3306
DB_NAME=mydb
DB_USERNAME=admin
DB_PASSWORD=MySecurePassword123!
```

## Django Integration

For Django applications, use the connection string:
```
mysql://admin:MySecurePassword123!@<rds-endpoint>:3306/mydb
```

## Files Generated

- **`rds-details.txt`** - Contains all RDS connection details and resource IDs
- **`init.sql`** - Database initialization script (pre-existing)
- **`mydb_dump.sql`** - MySQL dump file (optional, pre-existing)

## Troubleshooting

### Common Issues

1. **RDS instance not available**: Wait for instance to become available (can take 5-10 minutes)
2. **EC2 connection failed**: Check security group rules and ensure EC2 instance is running
3. **SSH key not found**: Ensure the key pair was created during EC2 setup
4. **Permission denied**: Ensure AWS CLI has RDS permissions

### Testing Connectivity

```bash
# Test from EC2 instance
ssh -i ~/aws_keys.pem ec2-user@<ec2-public-ip>
mysql -h <rds-endpoint> -P 3306 -u admin -p'MySecurePassword123!' -e "SELECT 1;"
```

### Manual Database Access

```bash
# Connect to EC2
ssh -i ~/aws_keys.pem ec2-user@<ec2-public-ip>

# Connect to RDS from EC2
mysql -h <rds-endpoint> -P 3306 -u admin -p'MySecurePassword123!' mydb
```

## Cost Considerations

- **Free Tier**: `db.t3.micro` is eligible for AWS free tier (750 hours/month)
- **Storage**: 20 GB included in free tier
- **Backup**: 7-day retention may incur additional costs after free tier
- **Data Transfer**: In-VPC traffic is free

## Next Steps

After RDS setup, you can:
1. Configure Django to use the RDS database
2. Deploy your Django application to the EC2 instance
3. Test the full application stack 