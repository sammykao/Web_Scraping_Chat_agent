# 🚀 Multi-Instance QA Agent Deployment Guide

## Overview

This guide shows how to deploy multiple QA Agent instances on different ports, each using different CSV files for domain-specific searches.

## 📋 Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Port 8000     │    │   Port 10000    │    │   Nginx Proxy   │
│  (Programming)  │    │  (DevOps/Infra) │    │   (Optional)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ sites_data_8000 │    │sites_data_10000│    │ Load Balancing  │
│    .csv         │    │    .csv         │    │ & Routing       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🏗️ Instance Configuration

### Port 8000 - Programming/Development
- **CSV File**: `sites_data_8000.csv`
- **Domains**: LangChain, FastAPI, Python, Django, React, etc.
- **Use Case**: Programming language and framework documentation

### Port 10000 - DevOps/Infrastructure  
- **CSV File**: `sites_data_10000.csv`
- **Domains**: AWS, Azure, Docker, Kubernetes, Git, Jenkins, etc.
- **Use Case**: DevOps tools and cloud infrastructure documentation

## 🚀 Quick Start

### 1. Deploy on EC2

```bash
# Download and run the multi-instance deployment script
wget https://raw.githubusercontent.com/yourusername/qagent/main/deploy_multi_ec2.sh
chmod +x deploy_multi_ec2.sh
./deploy_multi_ec2.sh
```

### 2. Configure Environment

```bash
# Edit the environment file with your API keys
nano .env

# Required variables:
OPENAI_API_KEY=your_openai_api_key_here
TAVILY_API_KEY=your_tavily_api_key_here
```

### 3. Start Services

```bash
# Start all instances
sudo systemctl start qa-agent-multi

# Check status
sudo systemctl status qa-agent-multi

# View logs
sudo journalctl -u qa-agent-multi -f
```

## 🔧 Docker Commands

### Start All Instances
```bash
docker-compose -f docker-compose.multi.yml up -d
```

### Start Specific Instance
```bash
# Start only port 8000 instance
docker-compose -f docker-compose.multi.yml up -d qa-agent-8000

# Start only port 10000 instance  
docker-compose -f docker-compose.multi.yml up -d qa-agent-10000
```

### Stop All Instances
```bash
docker-compose -f docker-compose.multi.yml down
```

### View Logs
```bash
# All instances
docker-compose -f docker-compose.multi.yml logs -f

# Specific instance
docker-compose -f docker-compose.multi.yml logs -f qa-agent-8000
docker-compose -f docker-compose.multi.yml logs -f qa-agent-10000
```

## 🌐 API Endpoints

### Port 8000 (Programming/Development)
```bash
# Health check
curl http://localhost:8000/health

# Chat with programming focus
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is FastAPI?", "reset_memory": false}'

# List sessions
curl http://localhost:8000/sessions
```

### Port 10000 (DevOps/Infrastructure)
```bash
# Health check
curl http://localhost:10000/health

# Chat with DevOps focus
curl -X POST http://localhost:10000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is Docker?", "reset_memory": false}'

# List sessions
curl http://localhost:10000/sessions
```

## 🔄 Nginx Load Balancing (Optional)

### Enable Nginx
```bash
# Start with Nginx proxy
docker-compose -f docker-compose.multi.yml --profile nginx up -d
```

### Access via Nginx
```bash
# Route to port 8000 instance
curl -X POST http://localhost/api/8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is Python?"}'

# Route to port 10000 instance
curl -X POST http://localhost/api/10000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is AWS?"}'
```

## 📊 Monitoring

### System Monitoring
```bash
# Run monitoring script
./monitor-multi.sh

# Check resource usage
docker stats

# View container logs
docker-compose -f docker-compose.multi.yml logs --tail=100
```

### Health Checks
```bash
# Test both instances
./test-multi.sh

# Individual health checks
curl -s http://localhost:8000/health | jq '.'
curl -s http://localhost:10000/health | jq '.'
```

## 🔧 Configuration

### Environment Variables
```bash
# Core API Keys
OPENAI_API_KEY=your_openai_api_key
TAVILY_API_KEY=your_tavily_api_key

# Search Configuration
MAX_RESULTS=10
SEARCH_DEPTH=basic  # or advanced
MAX_CONTENT_SIZE=10000
MAX_SCRAPE_LENGTH=20000

# LLM Configuration
LLM_TEMPERATURE=0.1
LLM_MAX_TOKENS=3000
LLM_TIMEOUT=60

# Request Configuration
REQUEST_TIMEOUT=30

# Optional Features
ENABLE_SEARCH_SUMMARIZATION=false
```

### CSV File Configuration
Each instance uses a different CSV file:

- **Port 8000**: `sites_data_8000.csv` (Programming/Development)
- **Port 10000**: `sites_data_10000.csv` (DevOps/Infrastructure)

### Custom CSV Files
To use your own CSV files:

1. Create your CSV files with the format:
```csv
domain,site,description
example,example.com,Example documentation
```

2. Update the Docker Compose file:
```yaml
volumes:
  - ./your_csv_file.csv:/app/sites_data_8000.csv:ro
```

## 🛠️ Troubleshooting

### Common Issues

#### Instance Not Starting
```bash
# Check logs
docker-compose -f docker-compose.multi.yml logs qa-agent-8000
docker-compose -f docker-compose.multi.yml logs qa-agent-10000

# Check environment variables
docker-compose -f docker-compose.multi.yml config
```

#### API Key Issues
```bash
# Verify API keys are set
echo $OPENAI_API_KEY
echo $TAVILY_API_KEY

# Test API keys
curl -H "Authorization: Bearer $OPENAI_API_KEY" \
  https://api.openai.com/v1/models
```

#### Port Conflicts
```bash
# Check if ports are in use
sudo netstat -tlnp | grep :8000
sudo netstat -tlnp | grep :10000

# Kill processes using ports
sudo fuser -k 8000/tcp
sudo fuser -k 10000/tcp
```

### Performance Optimization

#### Resource Limits
```yaml
deploy:
  resources:
    limits:
      memory: 1G
      cpus: '0.5'
    reservations:
      memory: 256M
      cpus: '0.25'
```

#### Scaling
```bash
# Scale instances
docker-compose -f docker-compose.multi.yml up -d --scale qa-agent-8000=2
docker-compose -f docker-compose.multi.yml up -d --scale qa-agent-10000=2
```

## 🔄 Backup and Recovery

### Create Backup
```bash
./backup-multi.sh
```

### Restore from Backup
```bash
# Stop services
docker-compose -f docker-compose.multi.yml down

# Restore from backup
tar -xzf backup_YYYYMMDD_HHMMSS.tar.gz

# Restart services
docker-compose -f docker-compose.multi.yml up -d
```

## 📈 Scaling Considerations

### Horizontal Scaling
- Each instance can be scaled independently
- Use load balancer for distribution
- Consider database for session persistence

### Vertical Scaling
- Increase memory and CPU limits
- Optimize CSV file size
- Use advanced search depth for better results

### Monitoring
- Set up alerts for resource usage
- Monitor API rate limits
- Track response times

## 🎯 Use Cases

### Port 8000 (Programming/Development)
- Programming language questions
- Framework documentation
- Code examples and tutorials
- Best practices

### Port 10000 (DevOps/Infrastructure)
- Cloud platform documentation
- Infrastructure as Code
- CI/CD pipeline questions
- Monitoring and logging

## 🔐 Security Considerations

### API Key Security
- Use environment variables
- Rotate keys regularly
- Monitor API usage

### Network Security
- Use HTTPS in production
- Implement rate limiting
- Restrict access to admin endpoints

### Container Security
- Keep base images updated
- Scan for vulnerabilities
- Use non-root users 