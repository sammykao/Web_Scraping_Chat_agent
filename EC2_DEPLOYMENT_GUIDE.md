# 🚀 EC2 Deployment Guide - How It Works

## Overview

The bash script doesn't automatically know which EC2 instance to connect to. You need to provide the EC2 details manually. Here are the different ways to deploy:

## 🔧 **How the Script Knows Which EC2 to Connect To**

### **The Script Doesn't Auto-Detect EC2**

The deployment script (`deploy_multi_ec2.sh`) doesn't automatically know which EC2 instance to SSH into. You must provide the connection details manually.

### **Two Deployment Approaches:**

## 🎯 **Option 1: Manual SSH Deployment**

### **Step 1: Get Your EC2 Details**
```bash
# You need these details from your AWS Console:
# - EC2 Public IP Address
# - SSH Key (.pem file)
# - Username (usually 'ubuntu' for Ubuntu AMI)
```

### **Step 2: SSH into EC2 and Run Script**
```bash
# SSH into your EC2 instance
ssh -i your-key.pem ubuntu@your-ec2-public-ip

# Download the deployment script
wget https://raw.githubusercontent.com/yourusername/qagent/main/deploy_multi_ec2.sh

# Make it executable
chmod +x deploy_multi_ec2.sh

# Run with --remote flag (tells script it's running on EC2)
./deploy_multi_ec2.sh --remote
```

### **Step 3: Configure and Start**
```bash
# Edit environment file with your API keys
nano .env

# Start the services
sudo systemctl start qa-agent-multi

# Check status
sudo systemctl status qa-agent-multi
```

## 🤖 **Option 2: Automated Deployment**

### **Step 1: Create Configuration**
```bash
# Run the helper script locally
./create_ec2_deployment.sh

# This will prompt for:
# - EC2 Public IP Address
# - SSH Key file path
# - EC2 Username
# - Repository URL
```

### **Step 2: Run Automated Deployment**
```bash
# The helper script creates deploy_to_ec2.sh
./deploy_to_ec2.sh

# This script will:
# 1. Test SSH connection
# 2. Copy deployment script to EC2
# 3. Execute deployment remotely
# 4. Provide access URLs
```

## 📋 **EC2 Prerequisites**

### **1. Launch EC2 Instance**
```bash
# Recommended specifications:
# - Instance Type: t3.medium (2 vCPU, 4GB RAM)
# - AMI: Ubuntu 22.04 LTS
# - Storage: 20GB gp3
# - Security Group: Allow ports 22, 8000, 10000
```

### **2. Configure Security Group**
```bash
# Inbound Rules:
# - Port 22 (SSH): 0.0.0.0/0
# - Port 8000 (QA Agent): 0.0.0.0/0
# - Port 10000 (QA Agent): 0.0.0.0/0
```

### **3. Download SSH Key**
```bash
# Download your .pem file from AWS Console
# Make it executable:
chmod 400 your-key.pem
```

## 🔍 **How the Script Works**

### **Script Detection Logic**
```bash
# The script checks if it's running locally or on EC2
if [[ "$1" == "--remote" ]]; then
    # Running on EC2 - proceed with deployment
    print_status "Running deployment on EC2 instance..."
else
    # Running locally - show connection instructions
    print_status "This script needs to be run on your EC2 instance."
    # Show manual steps and automated options
fi
```

### **SSH Connection Process**
```bash
# Test SSH connection
ssh -i "$SSH_KEY" -o ConnectTimeout=10 "$EC2_USER@$EC2_IP" "echo 'SSH connection successful'"

# Copy script to EC2
scp -i "$SSH_KEY" deploy_multi_ec2.sh "$EC2_USER@$EC2_IP:/home/$EC2_USER/"

# Execute remotely
ssh -i "$SSH_KEY" "$EC2_USER@$EC2_IP" "./deploy_multi_ec2.sh --remote"
```

## 🛠️ **Troubleshooting**

### **SSH Connection Issues**
```bash
# Check SSH key permissions
chmod 400 your-key.pem

# Test SSH connection
ssh -i your-key.pem ubuntu@your-ec2-ip

# Check Security Group
# Ensure port 22 is open in AWS Console
```

### **Port Access Issues**
```bash
# Check if ports are accessible
curl http://your-ec2-ip:8000/health
curl http://your-ec2-ip:10000/health

# Check Security Group rules
# Ensure ports 8000 and 10000 are open
```

### **Script Execution Issues**
```bash
# Check script permissions
chmod +x deploy_multi_ec2.sh

# Run with verbose output
bash -x deploy_multi_ec2.sh --remote

# Check logs
sudo journalctl -u qa-agent-multi -f
```

## 📊 **Monitoring Your Deployment**

### **Local Monitoring**
```bash
# SSH into EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# Check service status
sudo systemctl status qa-agent-multi

# View logs
sudo journalctl -u qa-agent-multi -f

# Monitor containers
docker ps
docker logs qa-agent-multi_qa-agent-8000_1
docker logs qa-agent-multi_qa-agent-10000_1
```

### **Remote Monitoring**
```bash
# Health checks
curl http://your-ec2-ip:8000/health
curl http://your-ec2-ip:10000/health

# Test chat endpoints
curl -X POST http://your-ec2-ip:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is FastAPI?", "reset_memory": false}'
```

## 🔐 **Security Considerations**

### **SSH Key Security**
```bash
# Secure your SSH key
chmod 400 your-key.pem

# Use SSH config for easier access
# Create ~/.ssh/config:
Host qa-agent-ec2
    HostName your-ec2-ip
    User ubuntu
    IdentityFile ~/.ssh/your-key.pem
    StrictHostKeyChecking no
```

### **Firewall Configuration**
```bash
# On EC2, configure UFW if needed
sudo ufw allow 22/tcp
sudo ufw allow 8000/tcp
sudo ufw allow 10000/tcp
sudo ufw enable
```

## 🚀 **Quick Start Commands**

### **Complete Automated Deployment**
```bash
# 1. Create configuration
./create_ec2_deployment.sh

# 2. Run deployment
./deploy_to_ec2.sh

# 3. Access your instances
# http://your-ec2-ip:8000  (Programming)
# http://your-ec2-ip:10000 (DevOps)
```

### **Manual Deployment**
```bash
# 1. SSH into EC2
ssh -i your-key.pem ubuntu@your-ec2-ip

# 2. Download and run script
wget https://raw.githubusercontent.com/yourusername/qagent/main/deploy_multi_ec2.sh
chmod +x deploy_multi_ec2.sh
./deploy_multi_ec2.sh --remote

# 3. Configure and start
nano .env  # Add your API keys
sudo systemctl start qa-agent-multi
```

## 📝 **Summary**

The script doesn't automatically know which EC2 to connect to because:

1. **Security**: EC2 instances are private by default
2. **Flexibility**: Different users have different EC2 setups
3. **Best Practice**: Explicit connection details prevent errors

**You must provide:**
- EC2 Public IP Address
- SSH Key file (.pem)
- Username (usually 'ubuntu')

**The script then:**
- Tests SSH connection
- Copies deployment files
- Executes deployment remotely
- Provides access URLs 