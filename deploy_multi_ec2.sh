#!/bin/bash

# Multi-Instance EC2 Deployment Script for QA Agent
# This script deploys multiple QA Agent instances on different ports with different CSV files
# Optimized for t2.micro instances (1 vCPU, 1GB RAM)

set -e  # Exit on any error

echo "🚀 Multi-Instance EC2 Deployment Script for QA Agent"
echo "====================================================="
echo "📊 Optimized for t2.micro instances (1 vCPU, 1GB RAM)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if script is being run locally or on EC2
if [[ "$1" == "--remote" ]]; then
    # This is running on the EC2 instance
    print_status "Running deployment on EC2 instance..."
    REMOTE_DEPLOYMENT=true
else
    # This is running locally - need to connect to EC2
    print_status "This script needs to be run on your EC2 instance."
    echo ""
    echo "📋 Prerequisites:"
    echo "1. Launch an EC2 instance (Ubuntu 22.04 LTS recommended)"
    echo "2. Configure Security Group to allow ports: 22 (SSH), 8000, 10000 (API)"
    echo "3. Download your SSH key (.pem file)"
    echo ""
    echo "⚠️  T2.MICRO CONSTRAINTS:"
    echo "- 1 vCPU, 1GB RAM"
    echo "- Limited burst performance"
    echo "- Reduced concurrent connections"
    echo ""
    echo "🔗 Connection Options:"
    echo ""
    echo "Option 1: Manual SSH and run script"
    echo "-----------------------------------"
    echo "1. SSH into your EC2 instance:"
    echo "   ssh -i your-key.pem ubuntu@your-ec2-public-ip"
    echo ""
    echo "2. Download and run this script on EC2:"
    echo "   wget https://raw.githubusercontent.com/yourusername/qagent/main/deploy_multi_ec2.sh"
    echo "   chmod +x deploy_multi_ec2.sh"
    echo "   ./deploy_multi_ec2.sh --remote"
    echo ""
    echo "Option 2: Use the automated deployment script"
    echo "---------------------------------------------"
    echo "1. Create a local deployment script with your EC2 details:"
    echo "   ./create_ec2_deployment.sh"
    echo ""
    echo "2. Run the automated deployment:"
    echo "   ./deploy_to_ec2.sh"
    echo ""
    echo "📝 Your EC2 Details:"
    echo "- Instance IP: [Your EC2 Public IP]"
    echo "- SSH Key: [Your .pem file path]"
    echo "- Username: ubuntu (for Ubuntu AMI)"
    echo ""
    print_warning "Please SSH into your EC2 instance and run this script with --remote flag"
    exit 1
fi

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

print_success "Starting multi-instance deployment on EC2 (t2.micro optimized)..."

# Check system resources
print_status "Checking system resources..."
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
print_warning "Available memory: ${TOTAL_MEM}MB (t2.micro constraint)"

if [ "$TOTAL_MEM" -lt 900 ]; then
    print_warning "Low memory detected. Optimizing for t2.micro..."
    T2_MICRO_MODE=true
else
    T2_MICRO_MODE=false
fi

# Update system packages
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker if not present
if ! command -v docker &> /dev/null; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_success "Docker installed successfully"
else
    print_warning "Docker is already installed"
fi

# Install Docker Compose if not present
if ! command -v docker-compose &> /dev/null; then
    print_status "Installing Docker Compose..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
else
    print_warning "Docker Compose is already installed"
fi

# Create application directory
print_status "Setting up application directory..."
APP_DIR="/home/$USER/qa-agent-multi"
mkdir -p $APP_DIR
cd $APP_DIR

# Clone repository (if not already present)
if [ ! -d ".git" ]; then
    print_status "Cloning repository..."
    # Replace with your actual repository URL
    git clone https://github.com/yourusername/qagent.git .
else
    print_status "Repository already exists, pulling latest changes..."
    git pull
fi

# Create environment file for multi-instance setup (t2.micro optimized)
print_status "Creating environment file for multi-instance setup (t2.micro optimized)..."
cat > .env << 'EOF'
# API Keys (Required - Replace with your actual keys)
OPENAI_API_KEY=your_openai_api_key_here
TAVILY_API_KEY=your_tavily_api_key_here

# Search Configuration (Reduced for t2.micro)
MAX_RESULTS=5
SEARCH_DEPTH=basic
MAX_CONTENT_SIZE=5000
MAX_SCRAPE_LENGTH=10000

# LLM Configuration (Optimized for t2.micro)
LLM_TEMPERATURE=0.1
LLM_MAX_TOKENS=1500
LLM_TIMEOUT=30

# Request Configuration (Reduced timeouts)
REQUEST_TIMEOUT=15

# Optional Features (Disabled for t2.micro)
ENABLE_SEARCH_SUMMARIZATION=false
EOF

print_warning "Please edit .env file with your actual API keys before continuing"
print_status "You can edit the .env file with: nano .env"

# Create CSV files for different instances
print_status "Creating CSV files for different instances..."

# First CSV for port 8000 (Programming/Development) - Reduced for t2.micro
cat > sites_data_8000.csv << 'EOF'
domain,site,description
langchain,docs.langchain.com,LangChain documentation and tutorials
fastapi,fastapi.tiangolo.com,FastAPI framework documentation
python,docs.python.org,Python official documentation
django,docs.djangoproject.com,Django web framework documentation
flask,flask.palletsprojects.com,Flask web framework documentation
react,react.dev,React JavaScript library documentation
vue,vuejs.org,Vue.js framework documentation
nodejs,nodejs.org,Node.js runtime documentation
EOF

# Second CSV for port 10000 (DevOps/Infrastructure) - Reduced for t2.micro
cat > sites_data_10000.csv << 'EOF'
domain,site,description
aws,docs.aws.amazon.com,Amazon Web Services documentation
azure,docs.microsoft.com,Microsoft Azure documentation
gcp,cloud.google.com,Google Cloud Platform documentation
terraform,developer.hashicorp.com,Terraform infrastructure documentation
ansible,docs.ansible.com,Ansible automation documentation
git,git-scm.com,Git version control documentation
github,docs.github.com,GitHub platform documentation
docker,docs.docker.com,Docker containerization documentation
EOF

print_success "CSV files created successfully (optimized for t2.micro)"

# Create Docker Compose file optimized for t2.micro
print_status "Creating Docker Compose file optimized for t2.micro..."
cat > docker-compose.micro.yml << 'EOF'
version: '3.8'

services:
  # First QA Agent Instance (Port 8000) - t2.micro optimized
  qa-agent-8000:
    build: .
    ports:
      - "8000:8000"
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - TAVILY_API_KEY=${TAVILY_API_KEY}
      - MAX_RESULTS=${MAX_RESULTS:-5}
      - SEARCH_DEPTH=${SEARCH_DEPTH:-basic}
      - MAX_CONTENT_SIZE=${MAX_CONTENT_SIZE:-5000}
      - MAX_SCRAPE_LENGTH=${MAX_SCRAPE_LENGTH:-10000}
      - LLM_TEMPERATURE=${LLM_TEMPERATURE:-0.1}
      - LLM_MAX_TOKENS=${LLM_MAX_TOKENS:-1500}
      - REQUEST_TIMEOUT=${REQUEST_TIMEOUT:-15}
      - LLM_TIMEOUT=${LLM_TIMEOUT:-30}
      - ENABLE_SEARCH_SUMMARIZATION=${ENABLE_SEARCH_SUMMARIZATION:-false}
      - CSV_FILE_PATH=sites_data_8000.csv
      - INSTANCE_NAME=qa-agent-8000
    volumes:
      - ./sites_data_8000.csv:/app/sites_data_8000.csv:ro
      - ./logs:/app/logs
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 400M
          cpus: '0.5'
        reservations:
          memory: 200M
          cpus: '0.25'
    healthcheck:
      test: ["CMD", "python", "-c", "import requests; requests.get('http://localhost:8000/health')"]
      interval: 60s
      timeout: 10s
      retries: 3
      start_period: 120s

  # Second QA Agent Instance (Port 10000) - t2.micro optimized
  qa-agent-10000:
    build: .
    ports:
      - "10000:8000"
    environment:
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      - TAVILY_API_KEY=${TAVILY_API_KEY}
      - MAX_RESULTS=${MAX_RESULTS:-5}
      - SEARCH_DEPTH=${SEARCH_DEPTH:-basic}
      - MAX_CONTENT_SIZE=${MAX_CONTENT_SIZE:-5000}
      - MAX_SCRAPE_LENGTH=${MAX_SCRAPE_LENGTH:-10000}
      - LLM_TEMPERATURE=${LLM_TEMPERATURE:-0.1}
      - LLM_MAX_TOKENS=${LLM_MAX_TOKENS:-1500}
      - REQUEST_TIMEOUT=${REQUEST_TIMEOUT:-15}
      - LLM_TIMEOUT=${LLM_TIMEOUT:-30}
      - ENABLE_SEARCH_SUMMARIZATION=${ENABLE_SEARCH_SUMMARIZATION:-false}
      - CSV_FILE_PATH=sites_data_10000.csv
      - INSTANCE_NAME=qa-agent-10000
    volumes:
      - ./sites_data_10000.csv:/app/sites_data_10000.csv:ro
      - ./logs:/app/logs
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 400M
          cpus: '0.5'
        reservations:
          memory: 200M
          cpus: '0.25'
    healthcheck:
      test: ["CMD", "python", "-c", "import requests; requests.get('http://localhost:8000/health')"]
      interval: 60s
      timeout: 10s
      retries: 3
      start_period: 120s

networks:
  default:
    driver: bridge
EOF

# Create systemd service for multi-instance setup (t2.micro optimized)
print_status "Creating systemd service for multi-instance setup (t2.micro optimized)..."
sudo tee /etc/systemd/system/qa-agent-multi.service > /dev/null << 'EOF'
[Unit]
Description=QA Agent Multi-Instance Docker Compose (t2.micro optimized)
Requires=docker.service
After=docker.service
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/qa-agent-multi
ExecStart=/usr/local/bin/docker-compose -f docker-compose.micro.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.micro.yml down
TimeoutStartSec=300
Restart=on-failure
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
print_status "Enabling and starting the service..."
sudo systemctl daemon-reload
sudo systemctl enable qa-agent-multi

# Create monitoring script optimized for t2.micro
print_status "Creating monitoring script optimized for t2.micro..."
cat > monitor-micro.sh << 'EOF'
#!/bin/bash

echo "🔍 Multi-Instance QA Agent Monitoring (t2.micro optimized)"
echo "=========================================================="

# Check system resources
echo "📊 System Resources:"
echo "Memory Usage:"
free -h

echo ""
echo "Disk Usage:"
df -h /

echo ""
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}'

echo ""
echo "📦 Docker Containers:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo "🌐 Health Checks:"
echo "Port 8000 (Programming/Development):"
curl -s --max-time 10 http://localhost:8000/health | jq '.' 2>/dev/null || echo "❌ Port 8000 not responding"

echo ""
echo "Port 10000 (DevOps/Infrastructure):"
curl -s --max-time 10 http://localhost:10000/health | jq '.' 2>/dev/null || echo "❌ Port 10000 not responding"

echo ""
echo "📈 Container Resource Usage:"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

echo ""
echo "⚠️  T2.MICRO PERFORMANCE NOTES:"
echo "- Limited to 1GB RAM total"
echo "- Burst CPU performance"
echo "- Reduced concurrent connections"
echo "- Slower response times under load"
EOF

chmod +x monitor-micro.sh

# Create test script optimized for t2.micro
print_status "Creating test script optimized for t2.micro..."
cat > test-micro.sh << 'EOF'
#!/bin/bash

echo "🧪 Testing Multi-Instance QA Agent (t2.micro optimized)"
echo "======================================================="

# Test Port 8000 (Programming/Development)
echo "Testing Port 8000 (Programming/Development):"
curl -X POST http://localhost:8000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is FastAPI?", "reset_memory": false}' \
  --max-time 30 \
  | jq '.' 2>/dev/null || echo "❌ Port 8000 test failed"

echo ""
echo "Testing Port 10000 (DevOps/Infrastructure):"
curl -X POST http://localhost:10000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "What is Docker?", "reset_memory": false}' \
  --max-time 30 \
  | jq '.' 2>/dev/null || echo "❌ Port 10000 test failed"

echo ""
echo "✅ Multi-instance testing completed"
echo ""
echo "⚠️  T2.MICRO PERFORMANCE EXPECTATIONS:"
echo "- Slower initial response times"
echo "- Limited concurrent requests"
echo "- May experience timeouts under load"
echo "- Consider upgrading to t3.small for better performance"
EOF

chmod +x test-micro.sh

# Create backup script
print_status "Creating backup script..."
cat > backup-micro.sh << 'EOF'
#!/bin/bash

BACKUP_DIR="/home/ubuntu/backups/qa-agent-multi"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

echo "💾 Creating backup: $BACKUP_DIR/backup_$DATE.tar.gz"

tar -czf $BACKUP_DIR/backup_$DATE.tar.gz \
  --exclude='.git' \
  --exclude='logs' \
  --exclude='__pycache__' \
  .

echo "✅ Backup created: $BACKUP_DIR/backup_$DATE.tar.gz"

# Keep only last 3 backups (t2.micro storage constraint)
cd $BACKUP_DIR
ls -t backup_*.tar.gz | tail -n +4 | xargs -r rm

echo "🧹 Cleaned up old backups"
EOF

chmod +x backup-micro.sh

print_success "Multi-instance deployment setup completed (t2.micro optimized)!"
print_status "Next steps:"
echo "1. Edit .env file with your API keys: nano .env"
echo "2. Start the service: sudo systemctl start qa-agent-multi"
echo "3. Check status: sudo systemctl status qa-agent-multi"
echo "4. Monitor: ./monitor-micro.sh"
echo "5. Test: ./test-micro.sh"
echo ""
echo "🌐 Access URLs:"
echo "Port 8000 (Programming/Development): http://$(curl -s ifconfig.me):8000"
echo "Port 10000 (DevOps/Infrastructure): http://$(curl -s ifconfig.me):10000"
echo ""
echo "📁 CSV Files (Reduced for t2.micro):"
echo "- sites_data_8000.csv: Programming/Development sites (8 sites)"
echo "- sites_data_10000.csv: DevOps/Infrastructure sites (8 sites)"
echo ""
echo "⚠️  T2.MICRO CONSTRAINTS:"
echo "- Limited to 1GB RAM total"
echo "- Reduced concurrent connections"
echo "- Slower response times"
echo "- Consider upgrading to t3.small for better performance" 