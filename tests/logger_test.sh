#!/bin/bash
#
# Logger test suite
set -e  # Exit on error

# Add visual feedback
echo "Starting logger tests..."

# Get the absolute path to the project root
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
echo "Project root: $PROJECT_ROOT"

# Source the logger with error checking
echo "Sourcing logger from: ${PROJECT_ROOT}/core/logger.sh"
if [[ ! -f "${PROJECT_ROOT}/core/logger.sh" ]]; then
    echo "ERROR: Logger file not found"
    exit 1
fi

if ! source "${PROJECT_ROOT}/core/logger.sh"; then
    echo "ERROR: Failed to source logger.sh"
    exit 1
fi
echo "Successfully loaded logger"

# Also output to console for testing
_log_to_console() {
    local level="$1"
    local message="$2"
    local color
    
    # Set colors for different levels
    case "$level" in
        "DEBUG") color="\033[36m" ;;  # Cyan
        "INFO")  color="\033[32m" ;;  # Green
        "WARN")  color="\033[33m" ;;  # Yellow
        "ERROR") color="\033[31m" ;;  # Red
        "FATAL") color="\033[35m" ;;  # Magenta
        *) color="\033[0m"      ;;    # Default
    esac
    
    echo -e "${color}[${level}] ${message}\033[0m"
}

# Override logging functions to also show output
debug() { _log "DEBUG" "$1"; _log_to_console "DEBUG" "$1"; }
info()  { _log "INFO"  "$1"; _log_to_console "INFO"  "$1"; }
warn()  { _log "WARN"  "$1"; _log_to_console "WARN"  "$1"; }
error() { _log "ERROR" "$1"; _log_to_console "ERROR" "$1"; }
fatal() { _log "FATAL" "$1"; _log_to_console "FATAL" "$1"; exit 1; }

# Test setup
setup() {
    echo "Setting up test environment..."
    
    # Create test directory first
    export LOGGER_BASE_DIR="/tmp/2501/test"
    echo "Creating base directory: $LOGGER_BASE_DIR"
    mkdir -p "$LOGGER_BASE_DIR" || {
        echo "Failed to create directory: $LOGGER_BASE_DIR"
        return 1
    }
    
    # Set permissions
    chmod 0750 "$LOGGER_BASE_DIR" || {
        echo "Failed to set directory permissions"
        return 1
    }
    
    # Set other variables
    export LOGGER_FILE="supershell_test.log"
    export LOGGER_LEVEL="DEBUG"
    export LOGGER_MODE="0640"
    
    echo "Calling _logger_init..."
    if ! _logger_init; then
        echo "Logger initialization failed"
        return 1
    fi
    
    # Verify initialization
    if [[ -d "$LOGGER_BASE_DIR" && -f "$LOGGER_BASE_DIR/$LOGGER_FILE" ]]; then
        echo "Logger initialized successfully at: $LOGGER_BASE_DIR/$LOGGER_FILE"
        ls -la "$LOGGER_BASE_DIR"
        return 0
    else
        echo "Verification failed:"
        echo "Directory exists: $([[ -d "$LOGGER_BASE_DIR" ]] && echo "yes" || echo "no")"
        echo "File exists: $([[ -f "$LOGGER_BASE_DIR/$LOGGER_FILE" ]] && echo "yes" || echo "no")"
        return 1
    fi
}

# Test cleanup
cleanup() {
    echo "Cleaning up test environment..."
    if [[ -d "/tmp/2501/test" ]]; then
        rm -rf "/tmp/2501/test"
        echo "Test directory cleaned"
    fi
}

# Test basic logging
test_basic_logging() {
    echo -e "\n=== Testing basic logging functionality ==="
    
    # Ensure directory exists
    mkdir -p "${LOGGER_BASE_DIR}"
    
    debug "This is a debug message"
    info "This is an info message"
    warn "This is a warning message"
    error "This is an error message"
    
    # Add a small delay to ensure writes are complete
    sleep 1
    
    # Verify log file exists and has content
    if [[ -f "${LOGGER_BASE_DIR}/${LOGGER_FILE}" ]]; then
        echo "✓ Log file created and contains data"
        echo "Log contents:"
        cat "${LOGGER_BASE_DIR}/${LOGGER_FILE}"
        return 0
    else
        echo "✗ Log file empty or missing at ${LOGGER_BASE_DIR}/${LOGGER_FILE}"
        return 1
    fi
}

# Test log rotation
test_log_rotation() {
    echo -e "\n=== Testing log rotation ==="
    export LOGGER_MAX_SIZE="1K"  # Set small size for testing
    
    # Ensure directory exists
    mkdir -p "${LOGGER_BASE_DIR}"
    
    echo "Generating test logs..."
    for i in {1..50}; do
        debug "Test log entry $i for rotation testing"
        # Add some extra data to ensure we exceed 1K
        _log "DEBUG" "$(printf '%*s' 20 | tr ' ' 'x')"
    done
    
    # Add a small delay to ensure writes are complete
    sleep 1
    
    # Check if rotation occurred
    if [[ -f "${LOGGER_BASE_DIR}/${LOGGER_FILE}.1" ]]; then
        echo "✓ Log rotation successful"
        ls -l "${LOGGER_BASE_DIR}"
        return 0
    else
        echo "✗ Log rotation failed"
        ls -l "${LOGGER_BASE_DIR}" || true
        echo "Current log file size: $(stat -f%z "${LOGGER_BASE_DIR}/${LOGGER_FILE}" 2>/dev/null || stat -c%s "${LOGGER_BASE_DIR}/${LOGGER_FILE}" 2>/dev/null) bytes"
        return 1
    fi
}

# Test error handling
test_error_handling() {
    echo -e "\n=== Testing error handling ==="
    
    # Test invalid log level
    if ! _log "INVALID" "This should fail" 2>/dev/null; then
        echo "✓ Successfully caught invalid log level"
    else
        echo "✗ Failed to catch invalid log level"
        return 1
    fi
}

# Run all tests
run_tests() {
    local failed=0
    
    setup
    
    echo -e "\nRunning tests..."
    
    # Run each test and track failures
    test_basic_logging || ((failed++))
    test_log_rotation || ((failed++))
    test_error_handling || ((failed++))
    
    cleanup
    
    # Report results
    echo -e "\n=== Test Results ==="
    if ((failed == 0)); then
        echo "✓ All tests passed"
    else
        echo "✗ $failed test(s) failed"
        return 1
    fi
}

# Main execution
main() {
    echo "=== Logger Test Suite ==="
    run_tests
    echo "Tests completed"
}

# Run main if this script is being run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main
fi