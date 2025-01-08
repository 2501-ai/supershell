#!/bin/bash
# Configuration variables

API_KEY=""
DEBOUNCE_DELAY=0.3  # seconds
API_ENDPOINT="http://localhost:1337/api/v1/completion"
MAX_SUGGESTIONS=5

# Configure logger (optional - override defaults)
LOGGER_BASE_DIR="/tmp/2501/logs"
LOGGER_FILE="supershell.log"
LOGGER_LEVEL="DEBUG"