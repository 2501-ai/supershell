#!/bin/bash

# Features:
# - Log rotation
# - Multiple log levels
# - Configurable log paths
# - Log file permissions management
# - Log format validation
# - Error handling
# - Performance optimization

# ==============================================================================
# Configuration
# ==============================================================================

# Default configuration (can be overridden by environment variables)
LOGGER_BASE_DIR=${LOGGER_BASE_DIR:-"/tmp/2501/logs"}
LOGGER_FILE=${LOGGER_FILE:-"supershell.log"}
LOGGER_LEVEL=${LOGGER_LEVEL:-"INFO"}
LOGGER_MAX_SIZE=${LOGGER_MAX_SIZE:-"10M"}
LOGGER_KEEP_FILES=${LOGGER_KEEP_FILES:-5}
LOGGER_MODE=${LOGGER_MODE:-"0640"}
LOGGER_TIMESTAMP_FORMAT=${LOGGER_TIMESTAMP_FORMAT:-"+%Y-%m-%d %H:%M:%S.%3N"}

# Log file path - Move this into a function so it's dynamic
_get_logger_path() {
    echo "${LOGGER_BASE_DIR}/${LOGGER_FILE}"
}

# Initialize LOGGER_PATH
LOGGER_PATH=$(_get_logger_path)

# ==============================================================================
# Log Levels (using simple variables instead of associative array)
# ==============================================================================

readonly LOG_LEVEL_DEBUG=0
readonly LOG_LEVEL_INFO=1
readonly LOG_LEVEL_WARN=2
readonly LOG_LEVEL_ERROR=3
readonly LOG_LEVEL_FATAL=4

# Convert string level to numeric value
_get_level_value() {
    case "$1" in
        "DEBUG") echo "$LOG_LEVEL_DEBUG" ;;
        "INFO")  echo "$LOG_LEVEL_INFO" ;;
        "WARN")  echo "$LOG_LEVEL_WARN" ;;
        "ERROR") echo "$LOG_LEVEL_ERROR" ;;
        "FATAL") echo "$LOG_LEVEL_FATAL" ;;
        *)       echo "$LOG_LEVEL_INFO" ;;  # Default to INFO
    esac
}

# ==============================================================================
# Helper Functions
# ==============================================================================

_logger_init() {
    echo "Initializing logger..."
    # Update path in case environment variables changed
    LOGGER_PATH=$(_get_logger_path)
    
    echo "LOGGER_BASE_DIR: $LOGGER_BASE_DIR"
    echo "LOGGER_FILE: $LOGGER_FILE"
    echo "LOGGER_PATH: $LOGGER_PATH"

    # Create log directory with proper permissions
    if [[ ! -d "$LOGGER_BASE_DIR" ]]; then
        echo "Creating directory: $LOGGER_BASE_DIR"
        mkdir -p "$LOGGER_BASE_DIR" || {
            echo "Failed to create directory: $LOGGER_BASE_DIR"
            return 1
        }
        chmod 0750 "$LOGGER_BASE_DIR" || {
            echo "Failed to set directory permissions"
            return 1
        }
    fi

    # Create or touch log file with proper permissions
    if [[ ! -f "$LOGGER_PATH" ]]; then
        echo "Creating log file: $LOGGER_PATH"
        touch "$LOGGER_PATH" || {
            echo "Failed to create log file: $LOGGER_PATH"
            return 1
        }
        chmod "$LOGGER_MODE" "$LOGGER_PATH" || {
            echo "Failed to set file permissions"
            return 1
        }
    fi

    echo "Logger initialization complete"
    return 0
}

_logger_rotate() {
    local log_size
    
    if [[ -f "$LOGGER_PATH" ]]; then
        log_size=$(stat -f%z "$LOGGER_PATH" 2>/dev/null || stat -c%s "$LOGGER_PATH" 2>/dev/null)
        
        # Convert LOGGER_MAX_SIZE to bytes
        local max_size
        case "$LOGGER_MAX_SIZE" in
            *K) max_size=$((${LOGGER_MAX_SIZE%K} * 1024)) ;;
            *M) max_size=$((${LOGGER_MAX_SIZE%M} * 1024 * 1024)) ;;
            *G) max_size=$((${LOGGER_MAX_SIZE%G} * 1024 * 1024 * 1024)) ;;
            *) max_size=$LOGGER_MAX_SIZE ;;
        esac

        if (( log_size > max_size )); then
            # Rotate files
            for i in $(seq $((LOGGER_KEEP_FILES - 1)) -1 1); do
                [[ -f "$LOGGER_PATH.$i" ]] && mv "$LOGGER_PATH.$i" "$LOGGER_PATH.$((i + 1))"
            done
            [[ -f "$LOGGER_PATH" ]] && mv "$LOGGER_PATH" "$LOGGER_PATH.1"
            touch "$LOGGER_PATH"
            chmod "$LOGGER_MODE" "$LOGGER_PATH"
        fi
    fi
}

_logger_validate_level() {
    case "$1" in
        "DEBUG"|"INFO"|"WARN"|"ERROR"|"FATAL") return 0 ;;
        *) return 1 ;;
    esac
}

# ==============================================================================
# Core Logging Function
# ==============================================================================

_log() {
    local level="$1"
    shift  # Remove level from arguments
    local message="$*"  # Combine all remaining arguments
    local timestamp
    local log_entry
    
    # Update path in case it changed
    LOGGER_PATH=$(_get_logger_path)
    
    # Validate input
    _logger_validate_level "$level" || return 1
    
    # Get numeric values for comparison
    local current_level=$(_get_level_value "$LOGGER_LEVEL")
    local msg_level=$(_get_level_value "$level")
    
    # Check if we should log this message
    if [ "$msg_level" -ge "$current_level" ]; then
        # Get timestamp
        timestamp=$(date "$LOGGER_TIMESTAMP_FORMAT")
        
        # Format log entry
        printf -v log_entry "[%s] [%s] [%s] [%s] %s\n" \
            "$timestamp" \
            "$level" \
            "$$" \
            "${FUNCNAME[2]:-main}" \
            "$message"
        
        # Write to log file
        printf "%s" "$log_entry" >> "$LOGGER_PATH" || {
            printf "Failed to write to log file: %s\n" "$LOGGER_PATH" >&2
            return 1
        }
        
        # Rotate if needed
        _logger_rotate
    fi
}

# ==============================================================================
# Public Interface
# ==============================================================================

debug() { _log "DEBUG" "$@"; }

info() {
    # SUPERSHELL_DEBUG is an environment variable
    if [ "$SUPERSHELL_DEBUG" = "true" ]; then
        _log "INFO" "$@"
    else
        return 0
    fi
}
warn()  { _log "WARN"  "$@"; }
error() { _log "ERROR" "$@"; }
fatal() { _log "FATAL" "$@"; exit 1; }
