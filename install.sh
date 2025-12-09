#!/bin/bash
#
# Tab Mover Extension - Installation Script
# Installs the native messaging host for Chromium/Chrome on Linux
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
HOST_NAME="com.tabmover.host"
INSTALL_DIR="$HOME/.local/share/tab-mover"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}========================================"
echo "  Tab Mover - Native Host Installer"
echo -e "========================================${NC}"
echo

# Detect native messaging hosts directory
NATIVE_HOSTS_DIR=""
if [ -d "$HOME/.config/chromium" ]; then
    NATIVE_HOSTS_DIR="$HOME/.config/chromium/NativeMessagingHosts"
    echo -e "${GREEN}Detected:${NC} Chromium"
elif [ -d "$HOME/.config/google-chrome" ]; then
    NATIVE_HOSTS_DIR="$HOME/.config/google-chrome/NativeMessagingHosts"
    echo -e "${GREEN}Detected:${NC} Google Chrome"
else
    echo -e "${YELLOW}Warning: Neither Chromium nor Chrome config directory found${NC}"
    echo "Creating Chromium config directory..."
    NATIVE_HOSTS_DIR="$HOME/.config/chromium/NativeMessagingHosts"
fi

# Check for Chromium/Chrome executable
CHROMIUM_PATH=""
for path in /usr/bin/chromium /usr/bin/chromium-browser /usr/bin/google-chrome /usr/bin/google-chrome-stable; do
    if [ -x "$path" ]; then
        CHROMIUM_PATH="$path"
        break
    fi
done

if [ -z "$CHROMIUM_PATH" ]; then
    echo -e "${RED}Error: Chromium/Chrome executable not found${NC}"
    echo "Please install Chromium or Google Chrome first."
    exit 1
fi
echo -e "${GREEN}Browser executable:${NC} $CHROMIUM_PATH"

# Check for Python
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}Error: Python 3 is required but not installed${NC}"
    exit 1
fi
echo -e "${GREEN}Python:${NC} $(python3 --version)"

echo

# Get extension ID from user
echo -e "${YELLOW}To complete installation, you need the extension ID.${NC}"
echo
echo "Steps to get the extension ID:"
echo "  1. Open chrome://extensions in your browser"
echo "  2. Enable 'Developer mode' (toggle in top right)"
echo "  3. Click 'Load unpacked' and select: $SCRIPT_DIR/extension"
echo "  4. Copy the ID shown below the extension name"
echo "     (looks like: abcdefghijklmnopqrstuvwxyzabcdef)"
echo
read -p "Enter the extension ID: " EXTENSION_ID

# Validate extension ID format (32 lowercase letters)
if ! [[ "$EXTENSION_ID" =~ ^[a-p]{32}$ ]]; then
    echo -e "${RED}Error: Invalid extension ID format${NC}"
    echo "Extension ID should be 32 lowercase letters (a-p only)"
    exit 1
fi

echo
echo -e "${YELLOW}Installing native host...${NC}"

# Create installation directory
mkdir -p "$INSTALL_DIR"
echo -e "  ${GREEN}Created:${NC} $INSTALL_DIR"

# Copy native host script
cp "$SCRIPT_DIR/native-host/tab_mover_host.py" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/tab_mover_host.py"
echo -e "  ${GREEN}Installed:${NC} $INSTALL_DIR/tab_mover_host.py"

# Create native hosts directory if needed
mkdir -p "$NATIVE_HOSTS_DIR"

# Generate and install host manifest
HOST_MANIFEST="$NATIVE_HOSTS_DIR/$HOST_NAME.json"
cat > "$HOST_MANIFEST" << EOF
{
  "name": "$HOST_NAME",
  "description": "Native messaging host for Tab Mover extension",
  "path": "$INSTALL_DIR/tab_mover_host.py",
  "type": "stdio",
  "allowed_origins": [
    "chrome-extension://$EXTENSION_ID/"
  ]
}
EOF
echo -e "  ${GREEN}Created:${NC} $HOST_MANIFEST"

echo
echo -e "${GREEN}========================================"
echo "  Installation complete!"
echo -e "========================================${NC}"
echo
echo -e "${BLUE}Usage:${NC}"
echo "  Press Ctrl+Shift+G to move the active tab to a new window"
echo "  Or click the extension icon in the toolbar"
echo
echo -e "${YELLOW}Note:${NC} You may need to restart your browser for changes to take effect."
