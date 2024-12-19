#!/bin/bash
# Configuration variables

API_KEY="2501_ak_0bf83450ffe77028656b09226742f3aad8eae7a19b6cffbcbaf735c7d42072e8aed87b9de3e806ac35bbcaa9a63cb7228a44869974db51c7ccc8da33f10ba62345ecf7020a097fc071c5905275c3ff12"
DEBOUNCE_DELAY=0.3  # seconds
API_ENDPOINT="http://localhost:1337/api/v1/completion"
CURRENT_SUGGESTION=""
FETCHED_SUGGESTIONS=()

# Configure logger (optional - override defaults)
LOGGER_BASE_DIR="/tmp/2501/logs"
LOGGER_FILE="supershell.log"
LOGGER_LEVEL="DEBUG"