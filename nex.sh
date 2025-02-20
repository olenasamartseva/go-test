#!/bin/bash
set -e

echo "Updating package lists..."
sudo apt update  # Doesn't require confirmation but good to include

# Combined dependencies installation with -y flag for auto-approval
echo "Installing build essentials and dependencies..."
sudo apt install -y build-essential pkg-config libssl-dev git-all

# Rust installation with -y flag for auto-approval
echo "Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

echo "Sourcing Rust environment..."
source $HOME/.cargo/env

# Downloading protoc (no confirmation needed)
echo "Downloading Protocol Buffers..."
wget https://github.com/protocolbuffers/protobuf/releases/download/v21.4/protoc-21.4-linux-x86_64.zip

# Unzipping (no confirmation needed)
echo "Extracting Protocol Buffers..."
unzip protoc-21.4-linux-x86_64.zip -d $HOME/protoc

echo "Updating PATH for Protocol Buffers..."
export PATH="$HOME/protoc/bin:$PATH"

# Cargo installation with -y flag
echo "Installing cargo..."
sudo apt install -y cargo

# Screen installation with -y flag
echo "Installing screen..."
sudo apt install -y screen

echo "Installation complete!"
