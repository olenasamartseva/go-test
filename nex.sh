#!/bin/bash
set -e

echo "Updating package lists..."
sudo apt update

echo "Installing build essentials and dependencies..."
sudo apt install -y build-essential pkg-config libssl-dev git-all

echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

echo "Sourcing Rust environment..."
source $HOME/.cargo/env

echo "Downloading Protocol Buffers..."
wget https://github.com/protocolbuffers/protobuf/releases/download/v21.4/protoc-21.4-linux-x86_64.zip

echo "Extracting Protocol Buffers..."
unzip protoc-21.4-linux-x86_64.zip -d $HOME/protoc

echo "Setting up Protocol Buffers PATH..."
# Add to PATH for this session
export PATH="$HOME/protoc/bin:$PATH"
# Make it persistent by appending to .bashrc (for Bash users)
if ! grep -q "$HOME/protoc/bin" ~/.bashrc; then
    echo 'export PATH="$HOME/protoc/bin:$PATH"' >> ~/.bashrc
    echo "Added protoc to PATH in ~/.bashrc"
else
    echo "protoc PATH already in ~/.bashrc"
fi

echo "Installing cargo..."
sudo apt install -y cargo

echo "Installing screen..."
sudo apt install -y screen

# Verify protoc installation
echo "Verifying protoc installation..."
if command -v protoc >/dev/null 2>&1; then
    echo "protoc is installed successfully. Version: $(protoc --version)"
else
    echo "Error: protoc is not in PATH or not installed correctly."
    exit 1
fi

# Start a screen session named 'nexus'
echo "Starting screen session 'nexus'..."
screen -S nexus -d -m  # Detached mode to continue script execution
sleep 1  # Brief pause to ensure screen session initializes

# Install Nexus CLI within the screen session and auto-accept Terms of Use
echo "Installing Nexus CLI and accepting Terms of Use..."
screen -S nexus -X stuff "echo 'Y' | curl https://cli.nexus.xyz/ | sh\n"

echo "Installation complete!"
echo "Note: If you're starting a new terminal session, run 'source ~/.bashrc' to update your PATH"
echo "To attach to the 'nexus' screen session, run: screen -r nexus"
