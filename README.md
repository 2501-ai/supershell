# Supershell

## Overview

The Supershell is an innovative tool designed to enhance your terminal experience by providing intelligent command suggestions and system information. This project aims to streamline your workflow and improve productivity for developers and power users alike.

![Command Suggestions](https://github.com/2501-ai/supershell/blob/main/ai_responses.gif)

## Table of Contents

- [Shell Project](#shell-project)
  - [Overview](#overview)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Installation](#installation)
    - [Requirements](#requirements)
    - [Automatic Installation](#automatic-installation)
    - [Manual Installation](#manual-installation)
  - [Getting Started](#getting-started)
  - [Examples](#examples)
    - [Example 1: Command Suggestions](#example-1-command-suggestions)
    - [Example 2: Autonomous Agent Suggestions](#example-2-autonomous-agent-suggestions)
  - [Contributing](#contributing)
  - [Troubleshooting](#troubleshooting)
  - [Support](#support)
  - [License](#license)

## Features

- **Intelligent Command Suggestions**: Get context-aware suggestions as you type.
- **Autonomous Agent**: Activate an AI-powered suggestion mode for enhanced assistance.
- **System Information**: Display RAM and CPU details directly in your terminal.
- **Customizable**: Easily configure settings to suit your workflow.

## Installation

### Requirements

- **MacOS 14.0+** (Linux support coming soon)
- **zsh** (Support for bash and fish coming soon)

### Automatic Installation

Run the following command to automatically install the tool:

```bash
curl -sL https://raw.githubusercontent.com/2501-ai/supershell/refs/heads/main/install.sh | sh
```

### Manual Installation

1. Clone this repository or download the project files:
   ```bash
   git clone git@github.com:2501-ai/supershell.git "$HOME/.supershell"
   ```
2. Ensure the `main.sh` file has execution permissions:
   ```bash
   chmod +x main.sh
   ```
3. Add the source command to your shell's configuration file (`.bashrc`, `.zshrc`, etc.):
   ```bash
   echo "source $HOME/.supershell/main.sh" >> ~/.$(basename $SHELL)rc
   ```
4. Source the `main.sh` file in your current terminal session to activate SuperShell:
   ```bash
   source "$HOME/.supershell/main.sh"
   ```

## Getting Started

To start using the tool:

1. Open your terminal.
2. Begin typing your command.
3. write something and it will show you suggestions :
   - Select a suggestion and press Enter to execute it.
   - Start the autonomous agent suggestion by pressing `Ctrl + J`.

**Important Notes:**
- The tool must be sourced (not executed) to function properly.
- To automatically load it on terminal startup, add the source command to your shell's configuration file.

## Examples

Here are some examples of how to use the tool effectively:

### Example 1: Command Suggestions

![Command Suggestions](https://github.com/2501-ai/supershell/blob/main/ai_responses.gif)

In this example, you can see how the tool provides command suggestions as you type. Simply press the down arrow key to navigate through the suggestions.

### Example 2: Autonomous Agent Suggestions

![Autonomous Agent Suggestions](https://github.com/2501-ai/supershell/blob/main/natural_language.gif)

This GIF demonstrates how to start the autonomous agent suggestion by pressing `Ctrl + J`. The agent will provide context-aware suggestions based on your input.

## Contributing

We welcome contributions from the community! To contribute to the Shell Project, please follow these steps:

1. **Fork the repository**.
2. **Create your feature branch**:
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. **Commit your changes**:
   ```bash
   git commit -m 'Add some AmazingFeature'
   ```
4. **Push to the branch**:
   ```bash
   git push origin feature/AmazingFeature
   ```
5. **Open a Pull Request**.

For major changes, please open an issue first to discuss your ideas.

## Troubleshooting

If the tool is not working as expected, please verify:

- The file has proper execution permissions.
- You are using the `source` command (or `.`) and not trying to execute the file directly.
- You are in the correct directory when sourcing the file.
- Your shell is compatible (Bash and Zsh are supported).
- Set the environment variable `export SUPERSHELL_DEBUG=true` to see debug logs (in `/tmp/2501/logs/supershell.log` file).

## Support

If you encounter any issues or have questions, feel free to join our Discord server at [Discord Link](https://discord.gg/uuCma4eHBF) or open an issue on GitHub [GitHub Link](https://github.com/2501-ai/supershell).

## License

This project is licensed under the MIT License. See the LICENSE file for more details.

---

Thank you for checking out the Shell Project! We hope you find it useful and look forward to your contributions.
