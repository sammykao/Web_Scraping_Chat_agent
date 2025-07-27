# Domain-Specific Q&A Agent

A specialized Q&A agent that searches specific documentation websites using Tavily search and OpenAI GPT-4o-mini for intelligent responses.

## 🏗️ Architecture Overview

### **Core Components**

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   FastAPI App   │───▶│  Session Store  │───▶│  DomainQAAgent  │
│   (main.py)     │    │ (per user)      │    │  (qa_agent.py)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   HTTP Memory   │    │  Chat History   │    │  Agent Executor │
│  (Cookies)      │    │ (Last 5 msgs)   │    │  (LangChain)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  Search Tool    │    │ Scraping Tool   │    │  LLM (OpenAI)  │
│ (Tavily)        │    │ (Chromium)      │    │  (GPT-4o-mini) │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### **Memory System**

The agent uses a **two-tier memory system**:

1. **HTTP Session Memory** (Cookies):
   - Session ID stored in browser cookies
   - 1-hour expiration
   - Links user to their agent instance

2. **Chat History Memory** (In-Memory):
   - Last 5 messages stored per session
   - Context window limitation for performance
   - Reset via `/reset` endpoint

### **Data Flow**

```
User Question → FastAPI → Session Lookup → Agent Instance → 
Search Tool → Scraping Tool (if needed) → LLM Processing → 
Response + Memory Update → User
```

## 🚀 Quick Start

### Prerequisites

- Python 3.11+
- OpenAI API key
- Tavily API key

### Local Development

1. **Clone and setup:**
```bash
git clone <repository-url>
cd qagent
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements.txt
```

2. **Create environment file:**
```bash
# Create .env file
cat > .env << EOF
OPENAI_API_KEY=your_openai_api_key_here
TAVILY_API_KEY=your_tavily_api_key_here
MAX_RESULTS=10
SEARCH_DEPTH=basic
MAX_CONTENT_SIZE=10000
MAX_SCRAPE_LENGTH=20000
LLM_TEMPERATURE=0.1
LLM_MAX_TOKENS=3000
REQUEST_TIMEOUT=30
LLM_TIMEOUT=60
ENABLE_SEARCH_SUMMARIZATION=false
EOF
```

3. **Install Playwright for web scraping:**
```bash
playwright install chromium
```

4. **Run the application:**
```bash
python main.py
```

The API will be available at `http://localhost:8000`

### Docker Deployment

#### Local Docker

1. **Build and run with Docker Compose:**
```bash
# Create .env file first (see above)
docker-compose up --build
```

2. **Or build manually:**
```bash
docker build -t qa-agent .
docker run -p 8000:8000 --env-file .env qa-agent
```

#### EC2 Deployment

1. **Launch EC2 instance:**
   - Use Ubuntu 22.04 LTS
   - t3.medium or larger recommended
   - Security group: Allow port 22 (SSH) and 8000 (API)

2. **Connect and setup:**
```bash
# SSH into your instance
ssh -i your-key.pem ubuntu@your-ec2-ip

# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker ubuntu
newgrp docker

# Clone your repository
git clone <your-repo-url>
cd qagent

# Create .env file with your API keys
nano .env
# Add your API keys and configuration

# Build and run
docker-compose up -d --build
```

3. **Production considerations:**
```bash
# Use systemd for auto-restart
sudo nano /etc/systemd/system/qa-agent.service

[Unit]
Description=QA Agent Docker Compose
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/home/ubuntu/qagent
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target

# Enable and start
sudo systemctl enable qa-agent
sudo systemctl start qa-agent
```

4. **Nginx reverse proxy (optional):**
```bash
sudo apt install nginx
sudo nano /etc/nginx/sites-available/qa-agent

server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

sudo ln -s /etc/nginx/sites-available/qa-agent /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

## 📡 API Endpoints

### Health Check
```bash
GET /health
```

### Chat
```bash
POST /chat
Content-Type: application/json

{
  "message": "How do I create a custom tool in LangChain?",
  "reset_memory": false
}
```

### Reset Memory
```bash
POST /reset
```

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OPENAI_API_KEY` | Required | OpenAI API key |
| `TAVILY_API_KEY` | Required | Tavily search API key |
| `MAX_RESULTS` | 10 | Maximum search results |
| `SEARCH_DEPTH` | basic | Search depth (basic/advanced) |
| `MAX_CONTENT_SIZE` | 10000 | Max content size for search results |
| `MAX_SCRAPE_LENGTH` | 20000 | Max content size for scraped pages |
| `LLM_TEMPERATURE` | 0.1 | LLM creativity (0-1) |
| `LLM_MAX_TOKENS` | 3000 | Max tokens for LLM response |
| `ENABLE_SEARCH_SUMMARIZATION` | false | Enable search result summarization |

## 📊 Performance Tips

1. **Memory Management:**
   - Chat history limited to last 5 messages
   - Session timeout: 1 hour
   - Use `/reset` to clear memory

2. **Search Optimization:**
   - Use `basic` depth for quick answers
   - Use `advanced` depth for comprehensive research
   - Enable summarization for long results

3. **Cost Optimization:**
   - Using GPT-4o-mini for cost efficiency
   - Limit max tokens and content sizes
   - Use search before scraping

## 🛠️ Development

### Project Structure
```
qagent/
├── main.py              # FastAPI application
├── qa_agent.py          # Core Q&A agent logic
├── search_tool.py       # Tavily search integration
├── scraping_tool.py     # Web scraping with Chromium
├── sites_data.csv       # Domain configuration
├── requirements.txt     # Python dependencies
├── Dockerfile          # Docker configuration
├── docker-compose.yml  # Docker Compose setup
└── README.md           # This file
```

### Adding New Domains

Edit `sites_data.csv`:
```csv
domain,site,description
langchain,docs.langchain.com,LangChain documentation
fastapi,fastapi.tiangolo.com,FastAPI framework documentation
```

## 🔒 Security

- Session cookies are HTTP-only and secure
- API keys stored in environment variables
- Non-root user in Docker container
- Health checks for monitoring

## 📈 Monitoring

- Health check endpoint: `/health`
- Docker health checks configured
- Logging at INFO level
- Session count tracking

## 🐛 Troubleshooting

### Common Issues

1. **Playwright not installed:**
```bash
playwright install chromium
```

2. **API key errors:**
   - Check `.env` file exists
   - Verify API keys are valid
   - Check environment variable names

3. **Docker build fails:**
   - Ensure Dockerfile is in root directory
   - Check Python version compatibility
   - Verify all files are copied

4. **Memory issues:**
   - Increase Docker memory limits
   - Reduce max content sizes
   - Use basic search depth

## 📝 License

[Your License Here]
