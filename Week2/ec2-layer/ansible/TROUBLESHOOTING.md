# SSH Connection Troubleshooting Guide

## Common SSH Connection Issues

### 1. Connection Timeout Error
```
ssh: connect to host 52.55.35.4 port 22: Connection timed out
```

**Possible Causes:**
- EC2 instance is not running
- Security group doesn't allow SSH (port 22)
- Network connectivity issues
- Wrong IP address

**Solutions:**

#### A. Check EC2 Instance Status
1. Go to AWS Console → EC2 → Instances
2. Verify your instance is running
3. Check the public IP address matches `52.55.35.4`

#### B. Check Security Group
1. Go to AWS Console → EC2 → Security Groups
2. Find the security group attached to your instance
3. Verify it has an inbound rule for SSH (port 22) from your IP or 0.0.0.0/0

#### C. Test Connection Locally
```bash
# Test from your local machine
ssh -i ~/aws_keys.pem ec2-user@52.55.35.4

# Test with verbose output
ssh -v -i ~/aws_keys.pem ec2-user@52.55.35.4
```

### 2. Authentication Failed
```
Permission denied (publickey)
```

**Possible Causes:**
- Wrong private key
- Wrong username
- Key permissions incorrect

**Solutions:**

#### A. Verify Private Key
```bash
# Check key format
cat ~/aws_keys.pem

# Should look like:
# -----BEGIN RSA PRIVATE KEY-----
# MIIEpAIBAAKCAQEA...
# -----END RSA PRIVATE KEY-----
```

#### B. Check Key Permissions
```bash
chmod 400 ~/aws_keys.pem
```

#### C. Verify Username
- Amazon Linux: `ec2-user`
- Ubuntu: `ubuntu`
- RHEL: `ec2-user`

### 3. GitHub Actions Specific Issues

#### A. Check GitHub Secret
1. Go to your repository → Settings → Secrets and variables → Actions
2. Verify `PRIVATE_KEY` secret exists
3. Check the secret value includes the entire private key (BEGIN and END lines)

#### B. Test SSH Key in Workflow
Add this step to your workflow for debugging:
```yaml
- name: Debug SSH key
  run: |
    echo "SSH key length: $(wc -c < ~/aws_keys.pem)"
    echo "SSH key permissions: $(ls -la ~/aws_keys.pem)"
    echo "First line: $(head -1 ~/aws_keys.pem)"
    echo "Last line: $(tail -1 ~/aws_keys.pem)"
```

### 4. Network Issues

#### A. Check Instance Network
```bash
# SSH into instance (if possible)
ssh -i ~/aws_keys.pem ec2-user@52.55.35.4

# Check network interfaces
ip addr show

# Check if SSH service is running
sudo systemctl status sshd
```

#### B. Check Security Group Rules
```bash
# From AWS CLI
aws ec2 describe-security-groups --group-ids sg-xxxxxxxxx
```

### 5. EC2 Instance Issues

#### A. Instance State
- **Running**: Instance is operational
- **Stopped**: Instance is stopped, needs to be started
- **Terminated**: Instance is deleted, needs to be recreated

#### B. Instance Health
- Check instance status checks in AWS Console
- Verify instance has enough resources (CPU, memory)

## Debugging Steps

### Step 1: Verify EC2 Instance
1. Go to AWS Console → EC2 → Instances
2. Find your instance
3. Check:
   - State: Should be "Running"
   - Public IP: Should be `52.55.35.4`
   - Security Group: Should allow SSH

### Step 2: Test Local Connection
```bash
# Test basic connectivity
ping 52.55.35.4

# Test SSH connection
ssh -i ~/aws_keys.pem ec2-user@52.55.35.4
```

### Step 3: Check Security Group
1. Go to AWS Console → EC2 → Security Groups
2. Find the security group attached to your instance
3. Check Inbound Rules:
   - Type: SSH
   - Protocol: TCP
   - Port: 22
   - Source: Your IP or 0.0.0.0/0

### Step 4: Verify Private Key
```bash
# Check key format
cat ~/aws_keys.pem

# Check permissions
ls -la ~/aws_keys.pem

# Should show: -r-------- (400 permissions)
```

### Step 5: Test with Ansible
```bash
# Test connection
ansible all -m ping -i inventory.yml

# Run troubleshooting playbook
ansible-playbook troubleshoot_connection.yml -i inventory.yml
```

## Quick Fixes

### Fix 1: Restart EC2 Instance
1. Go to AWS Console → EC2 → Instances
2. Select your instance
3. Actions → Instance State → Reboot

### Fix 2: Update Security Group
1. Go to AWS Console → EC2 → Security Groups
2. Find your instance's security group
3. Edit Inbound Rules
4. Add rule: SSH, TCP, Port 22, Source 0.0.0.0/0

### Fix 3: Regenerate Key Pair
1. Go to AWS Console → EC2 → Key Pairs
2. Create new key pair
3. Download and update your local key
4. Update GitHub secret

### Fix 4: Check Instance Type
1. Verify instance type supports your workload
2. Check if instance has enough resources
3. Consider upgrading if needed

## Common Solutions

### Solution 1: Instance Not Running
```bash
# Start instance via AWS CLI
aws ec2 start-instances --instance-ids i-xxxxxxxxx

# Wait for running state
aws ec2 wait instance-running --instance-ids i-xxxxxxxxx
```

### Solution 2: Security Group Issue
```bash
# Add SSH rule via AWS CLI
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxxxxxxxx \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0
```

### Solution 3: Key Permissions
```bash
# Fix key permissions
chmod 400 ~/aws_keys.pem

# Test connection
ssh -i ~/aws_keys.pem ec2-user@52.55.35.4
```

## Monitoring and Logs

### Check EC2 Logs
1. Go to AWS Console → EC2 → Instances
2. Select your instance
3. Actions → Monitor and troubleshoot → Get system log

### Check Security Group Logs
1. Go to AWS Console → VPC → Security Groups
2. Select your security group
3. Check the "Flow logs" tab

### Check GitHub Actions Logs
1. Go to your repository → Actions
2. Click on the failed workflow
3. Review the logs for each step

## Prevention

1. **Regular Monitoring**: Check instance status regularly
2. **Backup Keys**: Keep backup copies of your SSH keys
3. **Security Groups**: Use least privilege principle
4. **Documentation**: Keep track of your infrastructure setup
5. **Testing**: Test deployments in staging environment first 