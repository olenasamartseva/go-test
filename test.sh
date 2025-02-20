echo "Starting screen session 'nexus'..."
screen -S nexus -d -m  # Detached mode to continue script execution
sleep 1  # Brief pause to ensure screen session initializes

# Create a temporary script to handle the Nexus CLI installation
echo "Creating temporary installation script..."
cat > /tmp/nexus_install.sh << 'EOF'
#!/bin/bash
curl https://cli.nexus.xyz/ | sh << 'INPUT'
Y
INPUT
EOF

# Make the script executable
chmod +x /tmp/nexus_install.sh

# Run the temporary script in the screen session
echo "Installing Nexus CLI and accepting Terms of Use..."
screen -S nexus -X stuff "/tmp/nexus_install.sh\n"

# Clean up the temporary script
echo "Cleaning up temporary script..."
rm -f /tmp/nexus_install.sh
