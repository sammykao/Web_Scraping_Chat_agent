# Makefile for QA Agent EC2 Deployment
# Usage: make <target>

.PHONY: help deploy start stop restart status logs test backup update clean

# Default target
help:
	@echo "QA Agent EC2 Deployment Commands:"
	@echo ""
	@echo "Deployment:"
	@echo "  deploy     - Deploy the application to EC2"
	@echo "  start      - Start the QA Agent service"
	@echo "  stop       - Stop the QA Agent service"
	@echo "  restart    - Restart the QA Agent service"
	@echo ""
	@echo "Monitoring:"
	@echo "  status     - Check service status"
	@echo "  logs       - View application logs"
	@echo "  test       - Test API endpoints"
	@echo "  monitor    - Run monitoring script"
	@echo ""
	@echo "Maintenance:"
	@echo "  backup     - Create backup"
	@echo "  update     - Update application"
	@echo "  clean      - Clean up Docker resources"
	@echo "  health     - Run health check"

# Deployment
deploy:
	@echo "🚀 Deploying QA Agent..."
	@if [ ! -f .env ]; then \
		echo "❌ .env file not found. Please create it with your API keys."; \
		exit 1; \
	fi
	@echo "📦 Building Docker image..."
	docker-compose build
	@echo "🔧 Starting services..."
	docker-compose up -d
	@echo "⏳ Waiting for service to start..."
	@sleep 10
	@echo "✅ Deployment completed!"
	@make status

# Service management
start:
	@echo "▶️  Starting QA Agent service..."
	sudo systemctl start qa-agent
	@echo "✅ Service started"

stop:
	@echo "⏹️  Stopping QA Agent service..."
	sudo systemctl stop qa-agent
	@echo "✅ Service stopped"

restart:
	@echo "🔄 Restarting QA Agent service..."
	sudo systemctl restart qa-agent
	@echo "✅ Service restarted"

# Monitoring
status:
	@echo "📊 QA Agent Status:"
	@echo "=================="
	@sudo systemctl status qa-agent --no-pager -l || true
	@echo ""
	@echo "🐳 Docker Containers:"
	@docker-compose ps
	@echo ""
	@echo "🏥 Health Check:"
	@curl -f -s http://localhost:8000/health > /dev/null && echo "✅ API is responding" || echo "❌ API is not responding"

logs:
	@echo "📋 Viewing logs..."
	docker-compose logs -f

test:
	@echo "🧪 Testing API endpoints..."
	@echo "Testing health endpoint..."
	@curl -s http://localhost:8000/health | jq '.' 2>/dev/null || curl -s http://localhost:8000/health
	@echo ""
	@echo "Testing chat endpoint..."
	@curl -X POST http://localhost:8000/chat \
		-H "Content-Type: application/json" \
		-d '{"message": "Hello", "reset_memory": false}' \
		-s | jq '.' 2>/dev/null || echo "Chat endpoint test completed"

monitor:
	@echo "📊 Running monitoring script..."
	@if [ -f monitor.sh ]; then \
		./monitor.sh; \
	else \
		echo "❌ monitor.sh not found"; \
	fi

# Maintenance
backup:
	@echo "📦 Creating backup..."
	@if [ -f backup.sh ]; then \
		./backup.sh; \
	else \
		echo "❌ backup.sh not found"; \
	fi

update:
	@echo "🔄 Updating application..."
	@git pull
	@echo "🔧 Restarting service..."
	@make restart
	@echo "✅ Update completed"
	@make status

clean:
	@echo "🧹 Cleaning up Docker resources..."
	docker system prune -f
	docker volume prune -f
	@echo "✅ Cleanup completed"

health:
	@echo "🏥 Running health check..."
	@if [ -f health_check.sh ]; then \
		./health_check.sh; \
	else \
		echo "❌ health_check.sh not found"; \
	fi

# Development
dev:
	@echo "🔧 Starting development environment..."
	docker-compose up --build

dev-logs:
	@echo "📋 Viewing development logs..."
	docker-compose logs -f

# Production
prod:
	@echo "🚀 Starting production environment..."
	docker-compose -f docker-compose.prod.yml up -d

prod-logs:
	@echo "📋 Viewing production logs..."
	docker-compose -f docker-compose.prod.yml logs -f

# SSL Setup
ssl-setup:
	@echo "🔒 Setting up SSL certificate..."
	@if command -v certbot > /dev/null; then \
		echo "Certbot is installed. Run: sudo certbot --nginx -d your-domain.com"; \
	else \
		echo "Installing Certbot..."; \
		sudo apt update && sudo apt install -y certbot python3-certbot-nginx; \
		echo "Certbot installed. Run: sudo certbot --nginx -d your-domain.com"; \
	fi

# Security
firewall:
	@echo "🔥 Configuring firewall..."
	sudo ufw default deny incoming
	sudo ufw default allow outgoing
	sudo ufw allow ssh
	sudo ufw allow 8000
	sudo ufw --force enable
	@echo "✅ Firewall configured"

# Performance
performance:
	@echo "📊 Performance Information:"
	@echo "CPU Usage:"
	@top -bn1 | grep "Cpu(s)" | awk '{print $2}'
	@echo "Memory Usage:"
	@free -h | grep "Mem:" | awk '{print $3 "/" $2}'
	@echo "Disk Usage:"
	@df -h / | awk 'NR==2 {print $5}'
	@echo "Docker Resources:"
	@docker system df

# Quick setup
setup:
	@echo "🚀 Quick setup for EC2..."
	@if [ ! -f deploy_ec2.sh ]; then \
		echo "❌ deploy_ec2.sh not found"; \
		exit 1; \
	fi
	@chmod +x deploy_ec2.sh
	@./deploy_ec2.sh

# Emergency procedures
emergency-restart:
	@echo "🚨 Emergency restart..."
	@make stop
	docker-compose down
	@make start
	@echo "✅ Emergency restart completed"

rollback:
	@echo "⏪ Rolling back to previous version..."
	@git log --oneline -5
	@echo "Enter commit hash to rollback to:"
	@read commit_hash; \
	git checkout $$commit_hash
	@make restart
	@echo "✅ Rollback completed" 