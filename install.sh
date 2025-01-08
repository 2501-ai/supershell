#!/usr/bin/env zsh
INSTALL_DIR="$HOME/.supershell"
SHELL_CONFIG="$HOME/.$(basename $SHELL)rc"

# Check for required dependencies
check_deps() {
    local deps=(git curl jq)
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null; then
            echo "Missing dependency: $dep"
            install_dep "$dep"
        fi
    done
}

install_dep() {
    local dep="$1"
    if command -v apt-get >/dev/null; then
        sudo apt-get install -y "$dep"
        elif command -v brew >/dev/null; then
        brew install "$dep"
        elif command -v yum >/dev/null; then
        sudo yum install -y "$dep"
    else
        echo "Unable to install $dep. Please install manually."
        exit 1
    fi
}

# Install SuperShell
install_supershell() {
    echo "Installing SuperShell in $INSTALL_DIR"
    # Clone the repository silently
    git clone --quiet git@github.com:2501-ai/supershell.git "$INSTALL_DIR"

    # Setup shell integration
    echo "source $INSTALL_DIR/main.sh" >> "$SHELL_CONFIG"

    # Reload shell configuration
    source "$INSTALL_DIR/main.sh"

    echo "SuperShell installed !"
}

# Check for 2501 dependency
check_2501_dep() {
    if ! command -v @2501 >/dev/null; then
        echo "2501 is not installed. We will install it in order to use the agentic mode."
        # install the @2501 CLI if the OS is MacOS
        if [[ "$OSTYPE" == "darwin"* ]]; then
            curl -sL https://raw.githubusercontent.com/2501-ai/cli/main/installers/macOS-installer.sh | bash
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            curl -sL https://raw.githubusercontent.com/2501-ai/cli/main/installers/linux-installer.sh | bash
        elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
            iex "& {$(irm https://raw.githubusercontent.com/2501-ai/cli/main/installers/windows-installer.bat)}"
        else
            echo "Please install the @2501 CLI manually."
        fi
    fi

    local api_key="$(cat ~/.2501/2501.conf 2>/dev/null | jq -r '.api_key')"
    if [[ -z "$api_key" ]]; then
      local browser_cmd=""
      # Detect if there's a browser installed
      if command -v open >/dev/null; then
        browser_cmd="open https://accounts.2501.ai"
      elif command -v xdg-open >/dev/null; then
        browser_cmd="xdg-open https://accounts.2501.ai"
      elif command -v gnome-open >/dev/null; then
        browser_cmd="gnome-open https://accounts.2501.ai"
      fi

      # Open the browser
      echo "––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––"
      if [[ -n "$browser_cmd" ]]; then
        echo "You need to login at https://accounts.2501.ai and generate an API Key to use the agentic mode."
        echo ""
        echo "Once you have the API Key, run the following command to set it up:"
        echo "@2501 config set api_key <your_api_key>"
        echo ""
        echo "Press any key to open the browser..."
        # Wait for user input before opening the browser.
        read -n 1
        eval "$browser_cmd"
      else
        echo "No browser found. Please open https://accounts.2501.ai to continue."
        echo ""
        echo "Once you have the API Key, run the following command to set it up:"
        echo "@2501 config set api_key <your_api_key>"
      fi
    fi

}

main() {
    # Check if supershell is already installed
    if [[ -d "$INSTALL_DIR" ]]; then
        echo "SuperShell is already installed."
        return
    fi

    check_deps
    install_supershell
    check_2501_dep
}

main