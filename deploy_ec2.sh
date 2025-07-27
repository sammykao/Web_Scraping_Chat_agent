#!/bin/bash

# EC2 Deployment Script for QA Agent
# This script automates the deployment of the QA Agent on an EC2 instance

set -e  # Exit on any error

echo "🚀 Starting EC2 deployment for QA Agent..."

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

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root"
   exit 1
fi

# Update system packages
print_status "Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
print_status "Installing essential packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

# Install Docker
print_status "Installing Docker..."
if ! command -v docker &> /dev/null; then
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    # Add Docker repository
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
else
    print_warning "Docker is already installed"
fi

# Add user to docker group
print_status "Adding user to docker group..."
sudo usermod -aG docker $USER
print_warning "You may need to log out and back in for docker group changes to take effect"

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
APP_DIR="/home/$USER/qa-agent"
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

# Create environment file
print_status "Creating environment file..."
cat > .env << 'EOF'
# API Keys (Required - Replace with your actual keys)
OPENAI_API_KEY=your_openai_api_key_here
TAVILY_API_KEY=your_tavily_api_key_here

# Search Configuration
MAX_RESULTS=10
SEARCH_DEPTH=basic
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
EOF

print_warning "Please edit .env file with your actual API keys before continuing"
print_status "You can edit the .env file with: nano .env"

# Create systemd service for auto-restart
print_status "Creating systemd service..."
sudo tee /etc/systemd/system/qa-agent.service > /dev/null << 'EOF'
[Unit]
Description=QA Agent Docker Compose
Requires=docker.service
After=docker.service
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/qa-agent
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
print_status "Enabling systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable qa-agent

# Create health check script
print_status "Creating health check script..."
cat > health_check.sh << 'EOF'
#!/bin/bash

# Health check script for QA Agent
HEALTH_URL="http://localhost:8000/health"
MAX_RETRIES=3
RETRY_DELAY=5

for i in $(seq 1 $MAX_RETRIES); do
    if curl -f -s $HEALTH_URL > /dev/null; then
        echo "✅ QA Agent is healthy"
        exit 0
    else
        echo "❌ Health check failed (attempt $i/$MAX_RETRIES)"
        if [ $i -lt $MAX_RETRIES ]; then
            sleep $RETRY_DELAY
        fi
    fi
done

echo "❌ QA Agent health check failed after $MAX_RETRIES attempts"
exit 1
EOF

chmod +x health_check.sh

# Create monitoring script
print_status "Creating monitoring script..."
cat > monitor.sh << 'EOF'
#!/bin/bash

# Monitoring script for QA Agent
echo "📊 QA Agent Status"
echo "=================="

# Check if service is running
if systemctl is-active --quiet qa-agent; then
    echo "✅ Service: Running"
else
    echo "❌ Service: Stopped"
fi

# Check Docker containers
echo ""
echo "🐳 Docker Containers:"
docker-compose ps

# Check health endpoint
echo ""
echo "🏥 Health Check:"
if curl -f -s http://localhost:8000/health > /dev/null; then
    echo "✅ API is responding"
    curl -s http://localhost:8000/health | jq '.' 2>/dev/null || curl -s http://localhost:8000/health
else
    echo "❌ API is not responding"
fi

# Check logs
echo ""
echo "📋 Recent Logs:"
docker-compose logs --tail=10
EOF

chmod +x monitor.sh

# Create backup script
print_status "Creating backup script..."
cat > backup.sh << 'EOF'
#!/bin/bash

# Backup script for QA Agent
BACKUP_DIR="/home/ubuntu/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="qa-agent-backup-$DATE.tar.gz"

echo "📦 Creating backup: $BACKUP_NAME"

mkdir -p $BACKUP_DIR

# Create backup of application files
tar -czf $BACKUP_DIR/$BACKUP_NAME \
    --exclude='.git' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    --exclude='.env' \
    .

echo "✅ Backup created: $BACKUP_DIR/$BACKUP_NAME"

# Keep only last 5 backups
cd $BACKUP_DIR
ls -t qa-agent-backup-*.tar.gz | tail -n +6 | xargs -r rm

echo "🧹 Cleaned up old backups"
EOF

chmod +x backup.sh

# Create deployment instructions
print_status "Creating deployment instructions..."
cat > DEPLOYMENT_INSTRUCTIONS.md << 'EOF'
# EC2 Deployment Instructions

## Prerequisites
- Ubuntu 22.04 LTS EC2 instance
- Security group with ports 22 (SSH) and 8000 (API) open
- At least 2GB RAM and 10GB storage

## Quick Start

1. **SSH into your EC2 instance:**
   ```bash
   ssh -i your-key.pem ubuntu@your-ec2-ip
   ```

2. **Run the deployment script:**
   ```bash
   chmod +x deploy_ec2.sh
   ./deploy_ec2.sh
   ```

3. **Edit environment file:**
   ```bash
   nano .env
   # Add your actual API keys
   ```

4. **Start the service:**
   ```bash
   sudo systemctl start qa-agent
   ```

5. **Check status:**
   ```bash
   ./monitor.sh
   ```

## Management Commands

### Start/Stop Service
```bash
sudo systemctl start qa-agent
sudo systemctl stop qa-agent
sudo systemctl restart qa-agent
```

### Check Status
```bash
sudo systemctl status qa-agent
./monitor.sh
```

### View Logs
```bash
docker-compose logs -f
```

### Update Application
```bash
git pull
sudo systemctl restart qa-agent
```

### Backup
```bash
./backup.sh
```

## Troubleshooting

### Check Service Status
```bash
sudo systemctl status qa-agent
journalctl -u qa-agent -f
```

### Check Docker
```bash
docker ps
docker-compose ps
```

### Check API Health
```bash
curl http://localhost:8000/health
```

### Restart Everything
```bash
sudo systemctl stop qa-agent
docker-compose down
sudo systemctl start qa-agent
```
EOF

print_success "Deployment script completed!"
echo ""
echo "📋 Next Steps:"
echo "1. Edit .env file with your API keys: nano .env"
echo "2. Start the service: sudo systemctl start qa-agent"
echo "3. Check status: ./monitor.sh"
echo "4. Test API: curl http://localhost:8000/health"
echo ""
echo "📚 See DEPLOYMENT_INSTRUCTIONS.md for detailed instructions" 