# 🚀 T2.Micro Deployment Guide

## Overview

Using a **t2.micro** instance requires significant optimizations due to its limited resources. This guide explains the changes and performance expectations.

## 📊 **T2.Micro Specifications**

| Resource | t2.micro | t3.small (Recommended) |
|----------|----------|------------------------|
| **vCPU** | 1 | 2 |
| **RAM** | 1GB | 2GB |
| **Network** | Low to Moderate | Up to 5 Gbps |
| **Storage** | EBS Only | EBS Only |
| **Cost** | ~$8/month | ~$16/month |

## ⚠️ **T2.Micro Constraints**

### **Memory Limitations**
- **Total RAM**: 1GB (shared between OS, Docker, and applications)
- **Docker Memory**: Limited to 400MB per container
- **Concurrent Requests**: Limited to 2-3 simultaneous requests
- **Response Times**: 5-15 seconds (vs 2-5 seconds on t3.small)

### **CPU Limitations**
- **Burst Performance**: Limited CPU credits
- **Processing Speed**: Slower LLM inference
- **Concurrent Processing**: Single-threaded operations

### **Network Limitations**
- **Bandwidth**: Lower network performance
- **Latency**: Higher response times under load

## 🔧 **Optimizations Made for T2.Micro**

### **1. Reduced Resource Usage**
```bash
# Docker Compose Resource Limits
deploy:
  resources:
    limits:
      memory: 400M    # Reduced from 1GB
      cpus: '0.5'     # Reduced from 1.0
    reservations:
      memory: 200M    # Minimum memory
      cpus: '0.25'    # Minimum CPU
```

### **2. Reduced Search Parameters**
```bash
# Environment Variables (t2.micro optimized)
MAX_RESULTS=5          # Reduced from 10
MAX_CONTENT_SIZE=5000  # Reduced from 10000
MAX_SCRAPE_LENGTH=10000 # Reduced from 20000
LLM_MAX_TOKENS=1500    # Reduced from 3000
REQUEST_TIMEOUT=15     # Reduced from 30
LLM_TIMEOUT=30         # Reduced from 60
```

### **3. Smaller CSV Files**
```bash
# Reduced from 15+ sites to 8 sites each
sites_data_8000.csv:  8 programming sites
sites_data_10000.csv: 8 DevOps sites
```

### **4. Optimized Health Checks**
```bash
# Longer intervals for t2.micro
healthcheck:
  interval: 60s        # Increased from 30s
  timeout: 10s         # Reduced from 15s
  start_period: 120s   # Increased from 60s
```

## 📈 **Performance Expectations**

### **Response Times**
| Operation | t2.micro | t3.small |
|-----------|----------|----------|
| **Health Check** | 2-5 seconds | 1-2 seconds |
| **Simple Query** | 10-20 seconds | 5-10 seconds |
| **Complex Query** | 20-40 seconds | 10-20 seconds |
| **Concurrent Requests** | 2-3 max | 5-10 max |

### **Memory Usage**
```bash
# Expected Memory Usage on t2.micro
System (Ubuntu):     ~200MB
Docker Engine:       ~100MB
Container 1:         ~400MB
Container 2:         ~400MB
Available:           ~100MB (buffer)
```

### **CPU Usage**
```bash
# Expected CPU Usage on t2.micro
Idle:                ~5-10%
Single Request:      ~80-90%
Multiple Requests:   ~100% (throttled)
```

## 🚀 **Deployment Steps for T2.Micro**

### **1. Launch EC2 Instance**
```bash
# Recommended t2.micro settings:
# - Instance Type: t2.micro
# - AMI: Ubuntu 22.04 LTS
# - Storage: 20GB gp3
# - Security Group: Ports 22, 8000, 10000
```

### **2. Deploy Using Optimized Script**
```bash
# SSH into your t2.micro instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Download and run t2.micro optimized script
wget https://raw.githubusercontent.com/yourusername/qagent/main/deploy_multi_ec2.sh
chmod +x deploy_multi_ec2.sh
./deploy_multi_ec2.sh --remote
```

### **3. Configure Environment**
```bash
# Edit environment file with your API keys
nano .env

# Start the optimized service
sudo systemctl start qa-agent-multi
```

## 📊 **Monitoring T2.Micro Performance**

### **Resource Monitoring**
```bash
# Check memory usage
free -h

# Check CPU usage
top -bn1 | grep "Cpu(s)"

# Check Docker containers
docker stats --no-stream

# Monitor service
sudo systemctl status qa-agent-multi
```

### **Performance Testing**
```bash
# Test basic functionality
./test-micro.sh

# Monitor performance
./monitor-micro.sh

# Check logs
sudo journalctl -u qa-agent-multi -f
```

## ⚡ **Performance Optimization Tips**

### **1. Reduce Concurrent Load**
```bash
# Limit concurrent requests
# Use connection pooling
# Implement request queuing
```

### **2. Optimize Docker Settings**
```bash
# Reduce Docker memory usage
sudo systemctl edit docker
# Add: --memory=800m

# Optimize Docker daemon
sudo nano /etc/docker/daemon.json
{
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

### **3. System Optimizations**
```bash
# Disable unnecessary services
sudo systemctl disable snapd
sudo systemctl disable cloud-init

# Optimize swap
sudo fallocate -l 1G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

## 🔄 **Upgrading from T2.Micro**

### **When to Upgrade**
- **High Response Times**: >30 seconds consistently
- **Memory Errors**: Out of memory errors
- **Concurrent Users**: >3 simultaneous users
- **Production Use**: Business-critical applications

### **Upgrade Options**
```bash
# Option 1: t3.small (Recommended)
# - 2 vCPU, 2GB RAM
# - ~$16/month
# - 2x performance improvement

# Option 2: t3.medium
# - 2 vCPU, 4GB RAM
# - ~$32/month
# - 4x performance improvement

# Option 3: t3.large
# - 2 vCPU, 8GB RAM
# - ~$64/month
# - 8x performance improvement
```

### **Migration Process**
```bash
# 1. Create AMI of current instance
# 2. Launch new instance with larger type
# 3. Attach EBS volumes
# 4. Update DNS/load balancer
# 5. Test and switch traffic
```

## 🛠️ **Troubleshooting T2.Micro Issues**

### **Memory Issues**
```bash
# Check memory usage
free -h

# Restart containers if needed
sudo systemctl restart qa-agent-multi

# Clear Docker cache
docker system prune -f
```

### **CPU Issues**
```bash
# Check CPU usage
top

# Monitor CPU credits (t2.micro specific)
curl http://169.254.169.254/latest/meta-data/instance-type

# Restart if CPU credits exhausted
sudo reboot
```

### **Network Issues**
```bash
# Check network connectivity
ping google.com

# Test API endpoints
curl http://localhost:8000/health
curl http://localhost:10000/health
```

## 📝 **Best Practices for T2.Micro**

### **1. Resource Management**
- Monitor memory usage closely
- Restart services if memory exceeds 90%
- Use swap file for memory overflow
- Limit concurrent Docker containers

### **2. Performance Monitoring**
- Set up CloudWatch alarms
- Monitor CPU credits
- Track response times
- Alert on memory usage >80%

### **3. Application Optimization**
- Use basic search depth only
- Limit search results to 5
- Reduce content size limits
- Disable search summarization

### **4. Cost Optimization**
- Use spot instances for testing
- Schedule shutdown during off-hours
- Monitor data transfer costs
- Use reserved instances for production

## 🎯 **Summary**

**T2.Micro is suitable for:**
- Development and testing
- Low-traffic applications
- Proof of concept
- Personal projects

**Consider upgrading to t3.small for:**
- Production use
- Multiple concurrent users
- Faster response times
- Better reliability

The optimized deployment script handles t2.micro constraints automatically, but expect slower performance compared to larger instance types. 