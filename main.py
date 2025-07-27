"""
FastAPI application for Domain-specific Q&A Agent

It reads the env variables from the .env file and uses them to initialize the Q&A agent.
It has a chat endpoint that allows you to chat with the agent.
"""

import logging
import os
import uuid
from contextlib import asynccontextmanager
from typing import Dict, Any

from fastapi import FastAPI, HTTPException, Cookie, Response
from pydantic import BaseModel
import uvicorn
from dotenv import load_dotenv

from qa_agent import DomainQAAgent

load_dotenv()
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


def get_int_env(key: str, default: int) -> int:
    """Parse integer from environment variable with fallback"""
    try:
        return int(os.getenv(key, default))
    except ValueError:
        logger.warning(f"Invalid {key} value, using default: {default}")
        return default


def get_float_env(key: str, default: float) -> float:
    """Parse float from environment variable with fallback"""
    try:
        return float(os.getenv(key, default))
    except ValueError:
        logger.warning(f"Invalid {key} value, using default: {default}")
        return default


def validate_api_keys() -> tuple[str, str]:
    """Validate required API keys"""
    openai_api_key = os.getenv("OPENAI_API_KEY")
    tavily_api_key = os.getenv("TAVILY_API_KEY")

    if not openai_api_key:
        raise ValueError("OPENAI_API_KEY environment variable is required")
    if not tavily_api_key:
        raise ValueError("TAVILY_API_KEY environment variable is required")

    return openai_api_key, tavily_api_key


def build_config() -> Dict[str, Any]:
    """Build configuration from environment variables"""
    openai_api_key, tavily_api_key = validate_api_keys()

    search_depth = os.getenv("SEARCH_DEPTH", "basic")
    if search_depth not in ["basic", "advanced"]:
        logger.warning(f"Invalid SEARCH_DEPTH '{search_depth}', using default: basic")
        search_depth = "basic"

    # Get CSV file path from environment, default to sites_data.csv
    csv_file_path = os.getenv("CSV_FILE_PATH", "sites_data.csv")
    instance_name = os.getenv("INSTANCE_NAME", "qa-agent")

    return {
        "openai_api_key": openai_api_key,
        "tavily_api_key": tavily_api_key,
        "max_results": get_int_env("MAX_RESULTS", 10),
        "search_depth": search_depth,
        "max_content_size": get_int_env("MAX_CONTENT_SIZE", 10000),
        "max_scrape_length": get_int_env("MAX_SCRAPE_LENGTH", 20000),
        "enable_search_summarization": os.getenv(
            "ENABLE_SEARCH_SUMMARIZATION", "false"
        ).lower()
        == "true",
        "llm_temperature": get_float_env("LLM_TEMPERATURE", 0.1),
        "llm_max_tokens": get_int_env("LLM_MAX_TOKENS", 3000),
        "request_timeout": get_int_env("REQUEST_TIMEOUT", 30),
        "llm_timeout": get_int_env("LLM_TIMEOUT", 60),
        "csv_file_path": csv_file_path,
        "instance_name": instance_name,
    }


# Global agent store
agents: Dict[str, DomainQAAgent] = {}


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan manager"""
    logger.info("🚀 Starting QA Agent application...")
    
    # Initialize global configuration
    global config
    config = build_config()
    
    logger.info(f"📊 Configuration loaded for instance: {config['instance_name']}")
    logger.info(f"📁 Using CSV file: {config['csv_file_path']}")
    logger.info(f"🔍 Search depth: {config['search_depth']}")
    logger.info(f"📈 Max results: {config['max_results']}")
    
    yield
    
    logger.info("🛑 Shutting down QA Agent application...")


app = FastAPI(
    title="Domain-Specific Q&A Agent",
    description="A specialized Q&A agent that searches specific documentation websites",
    version="1.0.0",
    lifespan=lifespan,
)


class ChatRequest(BaseModel):
    message: str
    reset_memory: bool = False


class ChatResponse(BaseModel):
    response: str
    session_id: str


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "instance": config.get("instance_name", "qa-agent"),
        "csv_file": config.get("csv_file_path", "sites_data.csv"),
        "search_depth": config.get("search_depth", "basic"),
        "active_sessions": len(agents),
    }


@app.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest, session_id: str = Cookie(None)):
    """Chat endpoint with session management"""
    try:
        # Generate session ID if not provided
        if not session_id:
            session_id = str(uuid.uuid4())
            logger.info(f"🆔 New session created: {session_id}")

        # Get or create agent for this session
        if session_id not in agents or request.reset_memory:
            logger.info(f"🤖 Creating new agent for session: {session_id}")
            agents[session_id] = DomainQAAgent(
                csv_file_path=config["csv_file_path"], config=config
            )
            if request.reset_memory:
                logger.info(f"🔄 Memory reset for session: {session_id}")

        agent = agents[session_id]
        logger.info(f"💬 Processing chat request for session: {session_id}")

        # Process the chat request
        response = await agent.achat(request.message)
        logger.info(f"✅ Chat response generated for session: {session_id}")

        # Create response with session cookie
        chat_response = ChatResponse(response=response, session_id=session_id)
        response_obj = Response(content=chat_response.model_dump_json())
        response_obj.set_cookie(
            key="session_id",
            value=session_id,
            max_age=3600,  # 1 hour
            httponly=True,
            secure=False,  # Set to True in production with HTTPS
        )

        return chat_response

    except Exception as e:
        logger.error(f"❌ Chat error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Chat error: {str(e)}")


@app.post("/reset")
async def reset_memory(session_id: str = Cookie(None)):
    """Reset memory for a session"""
    if session_id and session_id in agents:
        del agents[session_id]
        logger.info(f"🔄 Memory reset for session: {session_id}")
        return {"message": "Memory reset successfully"}
    else:
        return {"message": "No active session to reset"}


@app.get("/sessions")
async def list_sessions():
    """List active sessions (for debugging)"""
    return {
        "active_sessions": len(agents),
        "session_ids": list(agents.keys()),
        "instance": config.get("instance_name", "qa-agent"),
    }


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=8000,
        reload=True,
        log_level="info",
    )
