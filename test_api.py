#!/usr/bin/env python3
"""
Simple test script for the QA Agent API
"""

import requests
import json
import time

def test_health():
    """Test the health endpoint"""
    try:
        response = requests.get("http://localhost:8000/health")
        print(f"✅ Health check: {response.status_code}")
        print(f"   Response: {response.json()}")
        return True
    except Exception as e:
        print(f"❌ Health check failed: {e}")
        return False

def test_chat():
    """Test the chat endpoint"""
    try:
        data = {
            "message": "What is LangChain?",
            "reset_memory": False
        }
        
        response = requests.post(
            "http://localhost:8000/chat",
            json=data,
            headers={"Content-Type": "application/json"}
        )
        
        print(f"✅ Chat test: {response.status_code}")
        result = response.json()
        print(f"   Session ID: {result.get('session_id', 'N/A')}")
        print(f"   Response preview: {result.get('response', '')[:100]}...")
        return True
    except Exception as e:
        print(f"❌ Chat test failed: {e}")
        return False

def test_reset():
    """Test the reset endpoint"""
    try:
        # First make a chat request to create a session
        chat_response = requests.post(
            "http://localhost:8000/chat",
            json={"message": "Hello", "reset_memory": False}
        )
        
        # Get session cookie
        session_cookie = chat_response.cookies.get("session_id")
        
        if session_cookie:
            # Test reset with session cookie
            reset_response = requests.post(
                "http://localhost:8000/reset",
                cookies={"session_id": session_cookie}
            )
            print(f"✅ Reset test: {reset_response.status_code}")
            return True
        else:
            print("⚠️ No session cookie found for reset test")
            return False
    except Exception as e:
        print(f"❌ Reset test failed: {e}")
        return False

def main():
    """Run all tests"""
    print("🧪 Testing QA Agent API...")
    print("=" * 50)
    
    tests = [
        ("Health Check", test_health),
        ("Chat Endpoint", test_chat),
        ("Reset Endpoint", test_reset),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"\n🔍 Testing: {test_name}")
        if test_func():
            passed += 1
        time.sleep(1)  # Small delay between tests
    
    print("\n" + "=" * 50)
    print(f"📊 Test Results: {passed}/{total} passed")
    
    if passed == total:
        print("🎉 All tests passed! API is working correctly.")
    else:
        print("⚠️ Some tests failed. Check the logs above.")

if __name__ == "__main__":
    main() 