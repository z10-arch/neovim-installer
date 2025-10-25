#!/bin/bash

echo "Rovodev Installer"

# Download acli binary
curl -LO "https://acli.atlassian.com/linux/latest/acli_linux_arm64/acli"

# Move to /usr/bin
sudo mv acli /usr/bin/

# Make it executable
sudo chmod +x /usr/bin/acli

# Verify installation
if ls /usr/bin | grep -q acli; then
    echo "Rovodev Installed"
else
    echo "Rovodev not installed"
fi
