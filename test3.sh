#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Updating package list..."
sudo apt update -y

echo "Installing build-essential, pkg-config, libssl-dev, git-all..."
sudo apt install build-essential pkg-config libssl-dev git-all -y

# Reinstall to ensure all dependencies are met
echo "Reinstalling build-essential, pkg-config, libssl-dev, git-all..."
sudo apt install --reinstall build-essential pkg-config libssl-dev git-all -y
sudo apt-get install unzip
echo "Installing Rust using rustup..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env

echo "Downloading protoc..."
wget https://github.com/protocolbuffers/protobuf/releases/download/v21.4/protoc-21.4-linux-x86_64.zip

echo "Unzipping protoc..."
unzip -o protoc-21.4-linux-x86_64.zip -d $HOME/protoc
export PATH="$HOME/protoc/bin:$PATH"
echo 'export PATH="$HOME/protoc/bin:$PATH"' >> ~/.bashrc

echo "Installing cargo..."
sudo apt install -y cargo

echo "Installing screen..."
sudo apt install -y screen
