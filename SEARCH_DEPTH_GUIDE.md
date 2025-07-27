# 🔍 Search Depth Configuration Guide

## Overview

The `SEARCH_DEPTH` parameter controls how thoroughly the Tavily search API searches for information. This setting affects both the quality and speed of search results.

## Available Options

### 1. `basic` (Default)
- **Speed**: Fast (2-5 seconds)
- **Comprehensiveness**: Quick surface-level search
- **Use Cases**: 
  - Quick answers to simple questions
  - When you need fast responses
  - General overview questions
  - Development and testing

### 2. `advanced`
- **Speed**: Slower (5-15 seconds)
- **Comprehensiveness**: Deep, thorough search
- **Use Cases**:
  - Complex technical questions
  - Research-intensive queries
  - When you need comprehensive answers
  - Production environments where quality > speed

## Detailed Comparison

| Aspect | `basic` | `advanced` |
|--------|---------|------------|
| **Search Time** | 2-5 seconds | 5-15 seconds |
| **Result Quality** | Good | Excellent |
| **Coverage** | Surface-level | Deep dive |
| **Cost** | Lower | Higher |
| **API Calls** | Fewer | More |
| **Best For** | Quick answers | Comprehensive research |

## Configuration Examples

### Quick Search Configuration
```bash
# Fast responses for simple questions
SEARCH_DEPTH=basic
MAX_RESULTS=5
LLM_TEMPERATURE=0.1
LLM_MAX_TOKENS=2000
```

### Comprehensive Search Configuration
```bash
# Thorough research for complex questions
SEARCH_DEPTH=advanced
MAX_RESULTS=15
LLM_TEMPERATURE=0.1
LLM_MAX_TOKENS=4000
ENABLE_SEARCH_SUMMARIZATION=true
```

## When to Use Each Option

### Use `basic` when:
- ✅ You need fast responses
- ✅ Questions are straightforward
- ✅ You're in development/testing
- ✅ Cost optimization is important
- ✅ General overview questions
- ✅ Simple "how to" questions

### Use `advanced` when:
- ✅ You need comprehensive answers
- ✅ Questions are complex or technical
- ✅ You're in production environment
- ✅ Quality is more important than speed
- ✅ Research-intensive queries
- ✅ Complex troubleshooting questions

## Performance Impact

### `basic` Search:
```
Query: "How to install FastAPI"
Time: ~3 seconds
Results: 5-10 relevant results
Quality: Good for quick answers
```

### `advanced` Search:
```
Query: "How to implement OAuth2 with FastAPI and custom middleware"
Time: ~10 seconds
Results: 10-15 comprehensive results
Quality: Excellent for detailed answers
```

## Cost Considerations

### API Usage:
- **`basic`**: ~1-2 API calls per search
- **`advanced`**: ~3-5 API calls per search

### Token Usage:
- **`basic`**: Lower token consumption
- **`advanced`**: Higher token consumption due to more content

## Best Practices

### 1. Development Environment
```bash
# Use basic for faster iteration
SEARCH_DEPTH=basic
MAX_RESULTS=5
```

### 2. Production Environment
```bash
# Use advanced for better user experience
SEARCH_DEPTH=advanced
MAX_RESULTS=10
```

### 3. Hybrid Approach
```bash
# Use basic for simple queries, advanced for complex ones
# This would require code changes to detect query complexity
```

## Troubleshooting

### If searches are too slow:
```bash
# Switch to basic
SEARCH_DEPTH=basic
MAX_RESULTS=5
```

### If answers are incomplete:
```bash
# Switch to advanced
SEARCH_DEPTH=advanced
MAX_RESULTS=15
```

### If costs are too high:
```bash
# Use basic with summarization
SEARCH_DEPTH=basic
MAX_RESULTS=10
ENABLE_SEARCH_SUMMARIZATION=true
```

## Monitoring Search Performance

### Check search times:
```bash
# Monitor in logs
grep "Searching:" logs/app.log | grep "depth=basic"
grep "Searching:" logs/app.log | grep "depth=advanced"
```

### Compare result quality:
```bash
# Check result counts
grep "Received.*results" logs/app.log
```

## Environment Variable Examples

### Development (.env.dev):
```bash
SEARCH_DEPTH=basic
MAX_RESULTS=5
LLM_TEMPERATURE=0.2
```

### Production (.env.prod):
```bash
SEARCH_DEPTH=advanced
MAX_RESULTS=10
LLM_TEMPERATURE=0.1
ENABLE_SEARCH_SUMMARIZATION=true
```

### Testing (.env.test):
```bash
SEARCH_DEPTH=basic
MAX_RESULTS=3
LLM_TEMPERATURE=0.0
```

## Migration Guide

### From `basic` to `advanced`:
1. Update environment variable
2. Test with simple queries first
3. Monitor response times
4. Adjust `MAX_RESULTS` if needed

### From `advanced` to `basic`:
1. Update environment variable
2. Test with complex queries
3. Verify answer quality
4. Consider enabling summarization

## Advanced Configuration

### Dynamic Search Depth (Future Enhancement):
```python
# This would require code changes
def determine_search_depth(query_complexity):
    if query_complexity == "simple":
        return "basic"
    elif query_complexity == "complex":
        return "advanced"
    else:
        return "basic"  # default
```

### A/B Testing:
```bash
# Test both configurations
SEARCH_DEPTH=basic   # Group A
SEARCH_DEPTH=advanced # Group B
```

## Summary

- **`basic`**: Fast, cost-effective, good for simple queries
- **`advanced`**: Thorough, higher quality, better for complex queries
- **Default**: `basic` (recommended for most use cases)
- **Production**: Consider `advanced` for better user experience
- **Development**: Use `basic` for faster iteration

Choose based on your specific needs for speed vs. quality! 