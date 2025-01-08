# Shell Project

## Introduction

Welcome to the Shell Project! This tool provides various functionalities to enhance your shell experience. To get started, you need to source the `main.sh` file.

## Installation

#### Automatic installation

You can run the following command to automatically install the tool:
```bash
curl -sL https://raw.githubusercontent.com/2501-ai/supershell/refs/heads/feature/iss-224-shell-installation/install.sh | bash
```

#### Manual installation

1. Clone this repository or download the project files
   ```bash
   git clone git@github.com:2501-ai/supershell.git "$HOME/.supershell" 
   ```
2. Make sure the `main.sh` file has execution permissions:
   ```bash
   chmod +x main.sh
   ```
3. Add the source command to your shell's configuration file (`.bashrc`, `.zshrc`, etc.):
   ```bash
   echo "source $HOME/.supershell/main.sh" >> ~/.$(basename $SHELL)rc
   ```
4. Source the `main.sh` file in your current terminal session to activate supershell:
   ```bash
   source "$HOME/.supershell/main.sh"
   ```

## Getting Started

To use the tool, please follow these steps:

1. Open your terminal
2. Start typing
3. Press the down arrow key to see the suggestions:
   1. Select the desired suggestion and press Enter to execute it.
   2. Start the autonomous agent suggestion by pressing Ctrl + J

**Important Notes:**
- The tool needs to be sourced (not executed) to work properly
- You need to source the file each time you open a new terminal session
- You can add the source command to your shell's configuration file (`.bashrc`, `.zshrc`, etc.) to automatically load it on terminal startup

## Usage

Once the `main.sh` file is sourced, you can start using the tool's functionalities. The following features are available:

## Troubleshooting

If the tool is not working as expected, please verify:
- The file has proper execution permissions
- You are using the `source` command (or `.`) and not trying to execute the file directly
- You are in the correct directory when sourcing the file
- Your shell is compatible (Bash and Zsh are supported)

## Support

If you encounter any issues or have questions, feel free to join the discord server at https://discord.gg/uuCma4eHBF or open an issue on GitHub https://github.com/2501-ai/supershell.

## License

This project is licensed under the MIT License. See the LICENSE file for more details.