#!/usr/bin/env bash

# Get user-data-dir from running code-server process
get_user_data_dir() {
    # Use ps with POSIX-compliant options
    local process_info
    if command -v ps >/dev/null 2>&1; then
        # Try BSD-style first (macOS), fallback to POSIX
        process_info=$(ps aux 2>/dev/null | grep -v grep | grep "code-server" | head -n 1) ||
        process_info=$(ps -ef 2>/dev/null | grep -v grep | grep "code-server" | head -n 1)
    fi

    if [ -n "$process_info" ]; then
        echo "$process_info" | grep -o -- '--user-data-dir=[^ ]*' | sed 's/--user-data-dir=//'
    fi
}

# Install extension directly
install_extension() {
    local extension_id="$1"
    local user_data_dir="$2"

    echo "Installing $extension_id..."

    # Install with user-data-dir if provided, let code-server handle the version
    if [ -n "$user_data_dir" ]; then
        if code-server --user-data-dir="$user_data_dir" --force --install-extension "$extension_id" 2>&1; then
            echo "  ✓ $extension_id installed successfully!"
            return 0
        else
            echo "  ✗ Installation failed for $extension_id"
            return 1
        fi
    else
        if code-server --force --install-extension "$extension_id" 2>&1; then
            echo "  ✓ $extension_id installed successfully!"
            return 0
        else
            echo "  ✗ Installation failed for $extension_id"
            return 1
        fi
    fi
}

# Check for required dependencies
check_dependencies() {
    local missing_deps=()

    # Check for required commands
    for cmd in code-server; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done

    if [ "${#missing_deps[@]}" -gt 0 ]; then
        echo "Error: Missing required dependencies: ${missing_deps[*]}"
        echo "Please install the missing dependencies and try again."
        exit 1
    fi
}

# Main script
echo "GitHub Copilot Extensions Installer"
echo "===================================="
echo ""

# Check dependencies
check_dependencies

echo "VS Code: $(code-server --version | head -1)"

# Check for user-data-dir in running code-server
USER_DATA_DIR="$(get_user_data_dir)"
if [ -n "$USER_DATA_DIR" ]; then
    echo "Detected user-data-dir: $USER_DATA_DIR"
fi
echo ""

# Extensions to install
# Use portable array declaration
EXTENSIONS="GitHub.copilot GitHub.copilot-chat"
FAILED=0

# Iterate through space-separated list for portability
for ext in $EXTENSIONS; do
    echo "Processing $ext..."

    # Install extension directly (let code-server handle version compatibility)
    if ! install_extension "$ext" "$USER_DATA_DIR"; then
        FAILED="$((FAILED + 1))"
    fi
    echo ""
done

# Summary
echo "===================================="
if [ $FAILED -eq 0 ]; then
    echo "✓ All extensions installed successfully!"
else
    echo "⚠ Completed with $FAILED error(s)"
    exit 1
fi
