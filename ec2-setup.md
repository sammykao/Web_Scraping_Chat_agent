# 🚀 EC2 Docker Deployment Guide

Complete guide to deploy the QA Agent on AWS EC2 using Docker.

## 📋 Prerequisites

### AWS Requirements
- AWS Account
- EC2 instance (Ubuntu 22.04 LTS recommended)
- Security Group with ports 22 (SSH) and 8000 (API) open
- At least 2GB RAM, 10GB storage

### API Keys Required
- OpenAI API key
- Tavily API key

## 🏗️ Step-by-Step Deployment

### 1. Launch EC2 Instance

```bash
# Launch Ubuntu 22.04 LTS instance
# Instance type: t3.medium (2 vCPU, 4GB RAM)
# Storage: 20GB gp3
# Security Group: Allow ports 22 (SSH) and 8000 (API)
```

### 2. Connect to EC2

```bash
# SSH into your instance
ssh -i your-key.pem ubuntu@your-ec2-ip
```

### 3. Run Automated Deployment

```bash
# Download and run the deployment script
wget https://raw.githubusercontent.com/yourusername/qagent/main/deploy_ec2.sh
chmod +x deploy_ec2.sh
./deploy_ec2.sh
```

### 4. Configure Environment

```bash
# Edit environment file with your API keys
nano .env

# Add your actual API keys:
OPENAI_API_KEY=sk-your-actual-openai-key
TAVILY_API_KEY=your-actual-tavily-key
```

### 5. Start the Service

```bash
# Start the QA Agent service
sudo systemctl start qa-agent

# Check status
sudo systemctl status qa-agent
```

### 6. Verify Deployment

```bash
# Check if containers are running
docker ps

# Test the API
curl http://localhost:8000/health

# Run monitoring script
./monitor.sh
```

## 🔧 Management Commands

### Service Management
```bash
# Start service
sudo systemctl start qa-agent

# Stop service
sudo systemctl stop qa-agent

# Restart service
sudo systemctl restart qa-agent

# Check status
sudo systemctl status qa-agent

# View logs
sudo journalctl -u qa-agent -f
```

### Docker Management
```bash
# View running containers
docker ps

# View logs
docker-compose logs -f

# Restart containers
docker-compose restart

# Stop all containers
docker-compose down

# Start containers
docker-compose up -d
```

### Monitoring
```bash
# Run monitoring script
./monitor.sh

# Health check
./health_check.sh

# View recent logs
docker-compose logs --tail=20
```

## 🔒 Security Configuration

### 1. Update Security Group
```bash
# In AWS Console:
# - Allow port 22 (SSH) from your IP
# - Allow port 8000 (API) from your IP or 0.0.0.0/0
# - Consider using Application Load Balancer for production
```

### 2. SSL/HTTPS Setup (Optional)
```bash
# Install Certbot for Let's Encrypt
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 3. Firewall Configuration
```bash
# Install UFW
sudo apt install ufw

# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 8000
sudo ufw enable
```

## 📊 Production Optimizations

### 1. Resource Limits
```bash
# Edit docker-compose.yml to add resource limits
# Memory: 2GB limit, 512MB reservation
# CPU: 1.0 limit, 0.5 reservation
```

### 2. Logging Configuration
```bash
# Configure log rotation
sudo nano /etc/logrotate.d/qa-agent

# Add:
/home/ubuntu/qa-agent/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 ubuntu ubuntu
}
```

### 3. Monitoring Setup
```bash
# Install monitoring tools
sudo apt install htop iotop nethogs

# Create monitoring dashboard
cat > dashboard.sh << 'EOF'
#!/bin/bash
echo "=== QA Agent Dashboard ==="
echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}')"
echo "Memory Usage: $(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}')"
echo "Disk Usage: $(df -h | awk '$NF=="/"{printf "%s", $5}')"
echo "Active Sessions: $(curl -s http://localhost:8000/health | jq -r '.active_sessions')"
EOF
chmod +x dashboard.sh
```

## 🔄 Update Process

### 1. Update Application
```bash
# Pull latest changes
git pull

# Restart service
sudo systemctl restart qa-agent

# Verify update
./monitor.sh
```

### 2. Backup Before Updates
```bash
# Create backup
./backup.sh

# Update application
git pull
sudo systemctl restart qa-agent
```

## 🐛 Troubleshooting

### Common Issues

#### 1. Service Won't Start
```bash
# Check service status
sudo systemctl status qa-agent

# View detailed logs
sudo journalctl -u qa-agent -f

# Check Docker
docker ps
docker-compose ps
```

#### 2. API Not Responding
```bash
# Check if container is running
docker ps

# Check container logs
docker-compose logs qa-agent

# Test API directly
curl http://localhost:8000/health
```

#### 3. Memory Issues
```bash
# Check memory usage
free -h
docker stats

# Increase swap if needed
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

#### 4. Network Issues
```bash
# Check if port is open
sudo netstat -tlnp | grep 8000

# Check security group
# Verify in AWS Console that port 8000 is open
```

### Debug Commands
```bash
# Check system resources
htop
df -h
free -h

# Check Docker resources
docker system df
docker stats

# Check application logs
docker-compose logs --tail=50

# Test API endpoints
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello", "reset_memory": false}'
```

## 📈 Performance Monitoring

### 1. System Monitoring
```bash
# Install monitoring tools
sudo apt install htop iotop nethogs

# Monitor in real-time
htop
iotop
nethogs
```

### 2. Application Monitoring
```bash
# Check API performance
curl -w "@curl-format.txt" -o /dev/null -s "http://localhost:8000/health"

# Monitor active sessions
watch -n 5 'curl -s http://localhost:8000/health | jq .'
```

### 3. Log Analysis
```bash
# View recent errors
docker-compose logs | grep ERROR

# Monitor request patterns
docker-compose logs | grep "Processing chat request"
```

## 🔧 Advanced Configuration

### 1. Environment Variables
```bash
# Production environment
cat > .env.prod << EOF
OPENAI_API_KEY=your-key
TAVILY_API_KEY=your-key
MAX_RESULTS=15
SEARCH_DEPTH=advanced
LLM_TEMPERATURE=0.1
LLM_MAX_TOKENS=4000
ENABLE_SEARCH_SUMMARIZATION=true
EOF
```

### 2. Docker Compose Overrides
```bash
# Create production override
cat > docker-compose.override.yml << EOF
version: '3.8'
services:
  qa-agent:
    environment:
      - LOG_LEVEL=INFO
    deploy:
      resources:
        limits:
          memory: 3G
          cpus: '1.5'
EOF
```

### 3. Auto-scaling (Future)
```bash
# Consider using AWS ECS or Kubernetes for auto-scaling
# For now, monitor and manually scale if needed
```

## 📞 Support

### Useful Commands
```bash
# Quick status check
./monitor.sh

# View all logs
docker-compose logs -f

# Restart everything
sudo systemctl restart qa-agent

# Check system resources
htop
```

### Emergency Procedures
```bash
# Emergency restart
sudo systemctl stop qa-agent
docker-compose down
sudo systemctl start qa-agent

# Rollback to previous version
git log --oneline
git checkout <previous-commit>
sudo systemctl restart qa-agent
```

## 🎯 Success Checklist

- [ ] EC2 instance launched with correct specs
- [ ] Security group configured properly
- [ ] Deployment script completed successfully
- [ ] API keys configured in .env file
- [ ] Service started and running
- [ ] Health check passes
- [ ] API responds to requests
- [ ] Monitoring scripts working
- [ ] Backup system configured
- [ ] SSL certificate installed (optional)
- [ ] Firewall configured
- [ ] Log rotation configured
- [ ] Performance monitoring active

Your QA Agent is now ready for production use! 🚀 