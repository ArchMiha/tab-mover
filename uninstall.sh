#!/bin/bash
#
# Tab Mover Extension - Uninstallation Script
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

HOST_NAME="com.tabmover.host"
INSTALL_DIR="$HOME/.local/share/tab-mover"

echo -e "${BLUE}========================================"
echo "  Tab Mover - Uninstaller"
echo -e "========================================${NC}"
echo

# Remove native host manifest from all possible locations
for dir in "$HOME/.config/chromium/NativeMessagingHosts" \
           "$HOME/.config/google-chrome/NativeMessagingHosts"; do
    if [ -f "$dir/$HOST_NAME.json" ]; then
        rm "$dir/$HOST_NAME.json"
        echo -e "${GREEN}Removed:${NC} $dir/$HOST_NAME.json"
    fi
done

# Remove install directory
if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    echo -e "${GREEN}Removed:${NC} $INSTALL_DIR"
fi

echo
echo -e "${GREEN}Uninstallation complete.${NC}"
echo
echo -e "${YELLOW}Note:${NC} The following items were preserved:"
echo "  - Extension (remove via chrome://extensions)"
echo "  - Profile directory: ~/.config/chromium-isolated/tab-mover-profile"
echo "    (Delete manually if no longer needed)"
