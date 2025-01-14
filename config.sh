#!/bin/bash
# Configuration variables

DEBOUNCE_DELAY=1  # seconds
API_ENDPOINT="https://engine.2501.ai/api/v1/completion"
MAX_SUGGESTIONS=5

# Configure logger (optional - override defaults)
LOGGER_BASE_DIR="/tmp/2501/logs"
LOGGER_FILE="supershell.log"
LOGGER_LEVEL="DEBUG"